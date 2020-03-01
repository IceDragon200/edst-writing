require 'edst/catalogue/names'
require 'edst/catalogue/node_tracking'
require 'edst/util'

module EDST
  module Catalogue
    module Utils
      class Configuration
        attr_reader :filename

        def initialize(filename, defaults = {})
          @filename = filename
          @defaults = defaults
        end

        def load_file
          unless File.exist?(@filename)
            File.write(@filename, @defaults.to_yaml)
          end
          YAML.load_file(@filename)
        end

        def get
          @config ||= OpenStruct.new(load_file)
        end
      end

      def self.node_to_text(node)
        result = []
        node.each_child do |child|
          case child.kind
          when :p
            result << child.value
          else
            warn "Cannot convert child node #{child.kind} to text"
          end
        end
        result.join("\n")
      end

      def self.node_to_data(node)
        case node.kind
        when :div, :list
          result = []
          node.each_child do |child|
            obj = node_to_data(child)
            result << obj if obj
          end
          [:list, result]
        when :tag
          [:tuple, [node.key, node.value]]
        when :p, :ln
          [:value, node.value]
        when :comment
          nil
        else
          raise "unhandled node kind `#{node.kind.inspect}`"
        end
      end

      def self.unroll_data(node, &block)
        return unless EDST::Util.present?(node)
        return to_enum :unroll_data, node unless block_given?
        kind, value = node
        case kind
        when :list
          value.each do |child|
            unroll_data(child, &block)
          end
        when :value, :tag
          block.call(value)
        else
          p node
          raise "unhandled node kind `#{kind.inspect}`"
        end
      end

      # @return [String]
      def self.node_to_label_id(node)
        "label-#{node.value.downcase.gsub(/\s+/, '-')}"
      end

      # A shortcut for searching the ast and returning the result as an Array
      def self.lookup(node, thing)
        node.search(thing).to_a
      end

      def self.grammar_deflate(str)
        str.deflate.gsub(/\s+([,])/, '\1')
      end

      def self.parse_character_name(name)
        Catalogue::Names.parse(name)
      end

      # Parses relation items, usually in the form of `A of B`, where A is the
      # relation type, and B is the name of the character the relation relates to.
      #
      # @example
      #   Son of ThatGuy
      #   # means that the current character, is the Son of ThatGuy
      def self.parse_character_relation(str)
        if str =~ /(.+)\s+of\s+(.+)/
          rel = $1
          person = $2
          return rel, person
        end
        return nil, nil
      end

      def self.capitalize_tag_key(key)
        case key
        when "id"
          "ID"
        else
          key.capitalize
        end
      end

      def self.write_edst_node_to_text(tracking, file, node)
        track = tracking.fork node
        case node.kind
        when :tag
          case node.key
          when /^&(\S+)/
            puts "Skipping %s tag %s" % [node.key, node.value]
          else
            if node.value.to_s.strip != ""
              file.puts "#{capitalize_tag_key(node.key)} = #{grammar_deflate(node.value)}."
            else
              file.puts "#{capitalize_tag_key(node.key)}."
            end
            file.puts
          end
        when :dialogue
          file.puts "\t#{node.key}: #{grammar_deflate(node.value)}"
          file.puts ""
        when :label
          file.puts ""
          file.puts ":: #{grammar_deflate(node.value)}"
          file.puts ""
        when :p
          file.puts "#{grammar_deflate(node.value)}"
          file.puts ""
        when :div
          file.puts
          file.puts "#{node.key.upcase}."
          node.each_child do |child|
            write_edst_node_to_text(track, file, child)
          end
          file.puts
        else
          node.each_child do |child|
            write_edst_node_to_text(track, file, child)
          end
        end
      end

      def self.write_edst_as_text_to_io(node, io)
        tracking = NodeTracking.new
        node.search('div') do |body|
          write_edst_node_to_text(tracking, io, body)
          io.puts ""
        end
      end

      def self.edst_to_text(node, filename)
        FileUtils::Verbose.mkdir_p File.dirname(filename)
        File.open(filename, 'w') do |file|
          write_edst_as_text_to_io(node, file)
          #file.puts
          #file.puts
          #node.search('div.bloopers') do |body|
          #  write_edst_node_to_text(file, body)
          #end
        end
      end
    end
  end
end
