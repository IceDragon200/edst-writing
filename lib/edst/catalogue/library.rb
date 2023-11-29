require 'ostruct'
require 'edst/core_ext/string'
require 'edst/core_ext/ostruct'
require 'edst/catalogue/utils'
require 'edst/catalogue/book'

module EDST
  module Catalogue
    class Registry
      attr_reader :data

      def initialize(d = {})
        @data = d
      end

      def []=(key, value)
        raise ArgumentError, "cannot register with falsy key!" unless key
        if @data.has_key?(key)
          raise KeyError, "key `#{key}` is already taken!"
        end
        @data[key] = value
      end

      def [](key)
        @data[key]
      end
    end

    class Library
      # A hash containing all books, mapped by id
      attr_reader :books
      # An Array containing ALL the characters currently available in the library
      attr_reader :characters
      # A hash mapping the character's full_id to the character
      attr_reader :character_by_full_id
      # A hash mapping the character's uuid to the character
      attr_reader :character_by_uuid
      # A hash mapping a character's alternate uuid to all instances of their character
      attr_reader :characters_by_sinuuid

      def initialize
        @books = {}
        @characters = []
        @character_by_full_id = {}
        @character_by_uuid = {}
        @characters_by_sinuuid = {}
      end

      def clear
        @books.clear
        @characters.clear
        @character_by_full_id.clear
        @character_by_uuid.clear
        @characters_by_sinuuid.clear
      end

      def find_book(book_id)
        @books.fetch(book_id)
      end

      def load_book(book_filename, **options)
        puts "Loading Book '#{book_filename}'"
        book_registry = Registry.new @books
        begin
          book = Catalogue::Book.load_file(book_filename, **options)
          puts "Loaded Book '#{book_filename}'"
          book_registry[book.id] = book
        rescue Catalogue::BookError => ex
          puts ex.inspect
        end
      end

      def load_characters
        puts "Fetching All Characters across Books"
        @books.each_value.each_with_object(@characters) do |book, result|
          result.concat book.characters
        end
        char_by_full_id = Registry.new @character_by_full_id
        char_by_uuid = Registry.new @character_by_uuid
        chars_by_sinuuid = Registry.new @characters_by_sinuuid
        puts "Mapping characters to id maps"
        @characters.each do |character|
          char_by_full_id[character.full_id] = character
          if character.uuid
            begin
              char_by_uuid[character.uuid] = character
            rescue KeyError => ex
              old_character = char_by_uuid[character.uuid]
              warn "#{character.full_id} UUID is already taken by #{old_character.full_id}"
              raise ex
            end
          else
            warn "#{character.full_id} has no UUID".light_yellow
          end
          if character.sinuuid
            (chars_by_sinuuid[character.sinuuid] ||= []).push(character)
          else
            #warn "#{character.full_id} has no Singular UUID".light_yellow
          end
        end
      end
    end
  end
end
