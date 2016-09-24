require 'colorize'

module EDST
  module Catalogue
    # A special logging interface for logging from a EDST::AST.
    class NodeLogger
      # This can be another NodeLogger or something that responds to puts
      attr_accessor :io

      def initialize(node)
        @node = node
        @io = STDOUT
      end

      def new(node)
        NodeLogger.new(node).tap { |l| l.io = self }
      end

      def puts(str)
        name = @node[:name] && "##{@node[:name]}".light_magenta or ''
        @io.puts "(#{@node[:filename]}#{name}) #{str}"
      end

      def warn(str)
        puts str.light_yellow
      end

      def err(str)
        puts str.light_red
      end
    end
  end
end
