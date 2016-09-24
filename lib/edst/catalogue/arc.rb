require 'edst/document'
require 'edst/catalogue/document_common'
require 'edst/catalogue/document_chapters'

module EDST
  module Catalogue
    class Arc
      include DocumentCommon
      include DocumentChapters

      attr_reader :document
      attr_reader :filename
      attr_reader :book
      attr_reader :index

      def initialize(book:, document:, extern:, filename: nil)
        @extern = extern
        @document = document
        @book = book
        @filename = filename || @document.filename || @book.filename
        initialize_document
        @index = find_head_node('index').value.to_i
      end

      def book_id
        book.id
      end

      def book_pathname(*args)
        book.book_pathname(*args)
      end

      private def cluster_ids
        @cluster_ids ||= begin
          c = @document.search('tag.clusters').first
          raise "(#{filename}), No clusters entry found for arc" unless c
          c.value.gsub(/\s+/, '').split(',')
        end
      end

      private def load_clusters_from_files
        result = []
        cluster_ids.each do |cluster_id|
          ['%04d', '%03d', '%02d', '%d'].each do |pattern|
            id_str = pattern % cluster_id.to_i
            files = Dir.glob(book_pathname("chapter/cls#{id_str}.edst"))
            files.each do |filename|
              doc = EDST::Document.load_file(filename)
              result << Cluster.new(
                book: self,
                arc: self,
                filename: filename,
                document: doc.search('div.cluster').first,
                extern: true)
            end
          end
        end
        result
      end

      private def load_clusters
        result = []
        clusters_elm = @document.search('div.clusters').first
        if clusters_elm && clusters_elm.search('div.cluster').first
          clusters_elm.search('div.cluster').each do |c|
            result << Cluster.new(book: book, arc: self, document: c, extern: false)
          end
        else
          result.concat load_clusters_from_files
        end
        result.sort_by!(&:index)
        result
      end

      def clusters
        @clusters ||= load_clusters
      end
    end
  end
end
