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

      # A shortcut for searching the ast and returning the result as an Array
      def self.lookup(node, thing)
        node.search(thing).to_a
      end

      def self.grammar_deflate(str)
        str.deflate.gsub(/\s+([,])/, '\1')
      end

      def self.parse_character_name(name)
        names = OpenStruct.new
        wrds = name.split(/\s+/)
        if wrds.size >= 3
          fn = wrds.first
          md = wrds.slice(1, wrds.size - 2)
          ln = wrds.last
          names.first_name, names.middle_names, names.last_name = fn, md, ln
          names.middle_name = md.first
        elsif wrds.size == 2
          names.first_name, names.last_name = *wrds
        elsif wrds.size == 1
          names.first_name = wrds.first
        end
        names
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
        else
          nil
        end
      end

      def self.write_edst_node_to_text(tracking, file, node)
        track = tracking.fork node
        case node.kind
        when :tag
          case node.key
          when '.branch', '.pov', '.time'
            puts "Skipping %s tag %s" % [node.key, node.value]
          else
            if node.value
              file.puts "#{node.key.capitalize} = #{node.value.grammar_deflate}"
            else
              file.puts "#{node.key.capitalize}"
            end
          end
        when :dialogue
          file.puts "#{node.key}: #{node.value.grammar_deflate}"
          file.puts
        when :label
          file.puts
          file.puts "___ #{node.value.grammar_deflate} ___"
          file.puts
        when :p
          file.puts "#{node.value.grammar_deflate}"
          file.puts
        else
          node.each_child do |child|
            write_edst_node_to_text(track, file, child)
          end
        end
      end

      def self.edst_to_text(node, filename)
        FileUtils::Verbose.mkdir_p File.dirname(filename)
        File.open(filename, 'w') do |file|
          tracking = NodeTracking.new
          node.search('div') do |body|
            write_edst_node_to_text(tracking, file, body)
            file.puts
          end
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
