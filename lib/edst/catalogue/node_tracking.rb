module EDST
  module Catalogue
    class NodeTracking
      attr_reader :stack

      def initialize
        @stack = []
      end

      def initialize_copy(org)
        @stack = org.stack.dup
      end

      def fork(node)
        dup.tap do |obj|
          obj.stack << node
        end
      end
    end
  end
end
