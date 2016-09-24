require 'edst/catalogue/utils'

module EDST
  module Catalogue
    class Character
      attr_accessor :book_id
      attr_accessor :relation_leaf
      attr_reader :document

      def initialize(book_id, document)
        @book_id = book_id
        @document = document
        @relation_leaf = nil
      end

      # The raw character data
      def character_data
        @document[:character]
      end

      private def raw_relations
        if r = @document.search('div.relation list').first
          return r.children.map(&:value)
        end
        []
      end

      def relations
        @relations ||= raw_relations.map do |str|
          rel, person = Utils.parse_character_relation(str)
          CharacterRelation.new(character: self, relation: rel, target_name: person)
        end
      end

      def filename
        @document.filename
      end

      def name
        character_data.name
      end

      def full_name
        character_data.name
      end

      def aliases
        character_data.aliases
      end

      def gender
        character_data.gender
      end

      def first_name
        character_data.first_name
      end

      def middle_name
        character_data.middle_name
      end

      def middle_names
        character_data.middle_names
      end

      def last_name
        character_data.last_name
      end

      # A basic identifier for the character, spaces are replaced with - and the name is lower cased
      def wiki_basename
        name.downcase.gsub(/\s+/, '-')
      end

      # A completely UNIQUE id to the character for the particular book
      def uuid
        character_data.uuid
      end

      # This is the UUID used to identify the same character across different worlds, ages etc
      def alternate_uuid
        character_data.alternate_uuid
      end

      # The character's base id, used for identifying them in urls
      def base_id
        wiki_basename
      end

      # Joins the character id with the book
      # @example
      #    full_id #=> "book/characters/character-base-id"
      def full_id
        [book_id, 'characters', base_id].join('/')
      end

      # The character's simple id, will probably not be unique
      def id
        base_id
      end

      # Helper method for showing the characters full url
      def href
        "/books/#{full_id}"
      end
    end
  end
end
