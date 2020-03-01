require 'edst/catalogue/utils'
require 'edst/catalogue/character_relation'
require 'edst/catalogue/names'
require 'edst/catalogue/elements'
require 'edst/util'

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

      # @return [Array<CharacterRelation>]
      def relations
        @relations ||= raw_relations.map do |str|
          rel, person = Utils.parse_character_relation(str)
          CharacterRelation.new(character: self, relation: rel, target_name: person)
        end
      end

      def find_relation_by_name(name)
        @relations.find do |relation|
          Catalogue::Names.equal?(relation.target_name, name)
        end
      end

      def filename
        @document.filename
      end

      def has_attribute?(name)
        respond_to?(name) || character_data[name] != nil
      end

      def get(name)
        respond_to?(name) ? send(name) : character_data[name]
      end
      alias :[] :get

      def gender
        character_data.gender
      end

      # Returns the raw character name, this may contain nicknames, placeholders and other illegal characters
      # Use display_name instead if you wish to show the name
      def name
        character_data.name
      end

      # @return [Catalogue::Name] the character's names
      def names
        @names ||= Catalogue::Names.parse(character_data.name).tap do |n|
          n.aliases = character_data.aliases
          n.pre_married_name = [
            # gender-neutral format
            character_data.pre_married_name,
            # for the ladies
            character_data.maiden_name,
            # for the gentlemen
            character_data.bachelor_name,
            # you don't have a pre_married_name now do you.
            character_data.last_name
          ].find do |str|
            EDST::Util.present?(str)
          end
        end
      end

      def first_and_family_name
        names.first_and_family_name
      end

      def display_name
        names.to_s
      end

      def aliases
        names.aliases
      end

      def first_name
        names.first_name
      end

      def middle_name
        names.middle_name
      end

      def middle_names
        names.middle_names
      end

      def last_name
        names.last_name
      end

      def pre_married_name
        names.pre_married_name
      end

      def has_elegens?
        !!@has_elegens
      end

      def elements
        @elements ||= begin
          @has_elegens = false
          source =
            (if elegens = character_data["elegens"]
              @has_elegens = true
              elegens
            else
              character_data["elements"]
            end || []).map do |str|
              EDST::Util.presence(str)
            end.compact

          Elements.parse(source)
        end
      end

      def has_elements?
        EDST::Util.present?(elements)
      end

      def spirit_overlays
        @spirit_overlays ||= begin
          source = character_data["spirit_overlays"] || []
          Catalogue::Utils.unroll_data(source).to_a
        end
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
      def sinuuid
        character_data.sinuuid
      end

      # The character's base id, used for identifying them in urls
      def base_id
        wiki_basename
      end

      def book_base_id
        [book_id, base_id].join('/')
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
