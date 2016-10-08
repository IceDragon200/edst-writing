require 'colorize'

module EDST
  module Catalogue
    class Logger
      attr_accessor :device

      def initialize(prefix)
        @prefix = prefix
        @device = STDOUT
      end

      def write(message)
        @device.puts "#{@prefix} #{message}"
      end

      def info(message)
        write "INFO".light_blue << ": #{message}"
      end

      def warn(message)
        write "WARN".light_yellow << ": #{message}"
      end

      def error(message)
        write "ERROR".light_red << ": #{message}"
      end
    end
  end
end
