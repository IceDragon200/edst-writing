module EDST
  module Catalogue
    class Cluster
      include DocumentCommon

      attr_reader :document
      attr_reader :filename
      attr_reader :book
      attr_reader :arc
      attr_reader :index

      def initialize(book:, document:, arc:, extern:, filename: nil)
        @extern = extern
        @book = book
        @document = document
        @filename = filename || @document.filename || @book.filename
        @index = find_head_node('index').value.to_i
        @arc = arc
        initialize_document
      end

      def book_pathname(*args)
        book.book_pathname(*args)
      end

      def arc_id
        arc.id
      end

      def book_id
        book.id
      end

      private def chapter_ids
        @chapter_ids ||= begin
          c = @document.search('tag.chapters').first
          raise "(#{filename}), No chapters tag found for cluster" unless c
          c.value.gsub(/\s+/, '').split(',')
        end
      end

      private def load_chapters_from_files
        result = []
        chapter_ids.each do |chapter_id|
          ['%04d', '%03d', '%02d', '%d'].each do |pattern|
            id_str = pattern % chapter_id.to_i
            files = Dir.glob(book_pathname("{chapter,chapters}/ch#{id_str}.edst"))
            files.each do |filename|
              doc = EDST::Document.load_file(filename)
              result << Chapter.new(
                book: self,
                cluster: self,
                filename: filename,
                document: doc,
                extern: true)
            end
          end
        end
        result.sort_by!(&:index)
        result
      end

      private def load_chapters
        load_chapters_from_files
      end

      def chapters
        @chapters ||= load_chapters
      end
    end
  end
end
