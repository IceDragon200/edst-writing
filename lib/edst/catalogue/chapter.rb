module EDST
  module Catalogue
    class Chapter
      include DocumentCommon

      attr_reader :document
      attr_reader :filename
      attr_reader :book
      attr_reader :cluster
      attr_reader :number
      attr_accessor :data

      def initialize(book:, document:, cluster:, is_frag: false, extern:, filename: nil)
        @is_frag = is_frag
        @extern = extern
        @book = book
        @document = document
        @filename = filename || @document.filename || @book.filename
        @cluster = cluster
        initialize_document
        unless @is_frag
          @number = find_head_node('chapter').value.to_i
        end
      end

      def is_frag?
        @is_frag
      end

      def book_pathname(*args)
        book.book_pathname(*args)
      end

      def cluster_id
        cluster.id
      end

      def book_id
        book.id
      end

      def index
        number
      end
    end
  end
end
