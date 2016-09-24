module EDST
  module Catalogue
    class NodeNotFoundError < KeyError
    end

    module DocumentCommon
      attr_reader :id
      attr_reader :title

      protected def find_head_node(name)
        node = @document.search("tag.#{name}").first ||
          @document.search("div.head tag.#{name}").first
        unless node
          raise NodeNotFoundError, "#{filename}:#{@document.line} could not find a :#{name} tag in header"
        end
        node
      end

      def initialize_document_id
        @id = find_head_node('id').value
      end

      def initialize_document_title
        @title = find_head_node('title').value
      end

      def initialize_document
        initialize_document_id
        initialize_document_title
      end

      def display_title
        title
      end

      def href
        "/books/#{id}"
      end
    end
  end
end
