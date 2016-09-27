require 'edst/catalogue/utils'

module EDST
  module Catalogue
    class NodeNotFoundError < KeyError
    end

    module DocumentCommon
      attr_reader :id
      attr_reader :title
      attr_reader :descriptions

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

      def initialize_document_description
        @descriptions = []
        @document.each_child do |child|
          case child.kind
          when :div
            case child.key
            when "description.spoiler"
              @descriptions << [:spoiler, EDST::Catalogue::Utils.node_to_text(child)]
            when "description"
              @descriptions << [:normal, EDST::Catalogue::Utils.node_to_text(child)]
            end
          end
        end
      end

      def initialize_document
        initialize_document_id
        initialize_document_title
        initialize_document_description
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
