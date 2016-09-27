require 'edst/catalogue/utils'
require 'edst/catalogue/names'

module EDST
  module Catalogue
    class CharacterList
      attr_reader :data

      def initialize(i = [])
        @data = i
      end

      def concat(list)
        @data.concat(list.data)
      end

      def add(character)
        @data << character
        return character
      end

      def find_by_name(name, check_aliases: true)
        @data.find do |character|
          Catalogue::Names.equal?(character.names, name, check_aliases: check_aliases)
        end
      end

      def find_by_name!(name, **options)
        find_by_name(name, options) || raise(KeyError, "character `#{name}` not found")
      end

      def each(&block)
        return to_enum :each unless block_given?
        @data.each(&block)
      end

      def update_attributes(**options)
        each do |character|
          options.each_pair do |key, value|
            character.send("#{key}=", value)
          end
        end
        self
      end

      def to_ary
        @data
      end
    end
  end
end
