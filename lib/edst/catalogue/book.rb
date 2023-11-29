require 'edst/catalogue/document_common'
require 'edst/catalogue/document_chapters'
require 'edst/catalogue/document_characters'

module EDST
  module Catalogue
    class BookError < LoadError
    end

    class Book
      include DocumentCommon
      include DocumentChapters
      include DocumentCharacters

      attr_reader :document
      attr_writer :relation_tree
      attr_reader :arcs
      attr_reader :filename

      def initialize(document:, filename: nil)
        @document = document
        @filename = filename || @document.filename
        initialize_document
        @arcs = []
        load_characters
        load_arcs
      end

      def book_pathname(*args)
        File.join(File.dirname(@filename), *args)
      end

      private def load_arcs_from_files
        arcs_glob = book_pathname('{chapter,chapters}/arc*.edst')
        files = Dir.glob(arcs_glob)
        files.each do |filename|
          doc = EDST::Document.load_file(filename)
          @arcs << Arc.new(book: self, filename: filename, document: doc.search('div.arc').first, extern: true)
        end
      end

      private def load_arcs
        arcs_elm = @document.search('div.arcs').first
        if arcs_elm && arcs_elm.search('div.arc').first
          arcs_elm.search('div.arc').each do |arc|
            @arcs << Arc.new(book: self, document: arc, extern: false)
          end
        else
          load_arcs_from_files
        end
        @arcs.sort_by!(&:id)
      end

      private def load_characters
        files = Dir.glob(book_pathname('{character,characters}/*.edst'))
        load_and_validate_characters(files)
      end

      def characters
        @character_list
      end

      def find_character_by_name(name)
        characters.find_by_name(name)
      end

      def find_relation_leaf(character)
        unless character.is_a?(Character)
          character = find_character_by_name(character)
        end
        if character
          id = character.full_id
          tree = @relation_map[id]
          if tree
            unless tree.character == character
              raise "character mismatch"
            end
          else
            tree = @relation_map[id] = RelationLeaf.new(character)
          end
          return tree
        end
        nil
      end

      def relation_tree
        @relation_tree ||= begin
          @relation_map = {}
          root = RelationLeaf.new nil
          characters.each do |parent|
            leaf = find_relation_leaf(parent)
            root.children.push(leaf)
            parent.relations.each do |prel|
              next unless prel.target_name
              child = find_relation_leaf(prel.target_name)
              next unless child
              # prel here is from the parent character, if the relation says "child of X" then the relation will report that it is_child
              # the leaf is also the current character, if the relation says "is parent of", then it will add the related character to this node's children
              prel.inverted_branches_to_collections.each do |sym|
                leaf.add_to_group(sym, child)
              end
            end
          end
          root
        end
      end

      def relation_map
        relation_tree
        @relation_map
      end

      def each_cluster(&block)
        return to_enum :each_cluster unless block_given?
        arcs.each do |arc|
          arc.clusters.each(&block)
        end
      end

      def clusters
        each_cluster.to_a
      end

      def load_everything
        # precache the characters
        characters
        # the character relation map
        relation_map
        # chapter arcs
        arcs
        # chapter clusters
        clusters
        # chapters
        chapters
        chapter_map
        # return self
        self
      end

      def self.load_file(filename, lazy_load: true)
        document = EDST::Document.load_file File.expand_path(filename), debug: true
        book_node = document.search('div.book').first
        if book_node
          book = Catalogue::Book.new(
            #filename: filename,
            document: book_node
          ).tap(&:relation_tree)
          book.load_everything unless lazy_load
          book
        else
          raise BookError, "'#{filename}' did not contain a valid div.book"
        end
      end
    end
  end
end
