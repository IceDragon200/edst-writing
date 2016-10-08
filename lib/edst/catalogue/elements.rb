require 'edst/catalogue/logger'

module EDST
  module Catalogue
    class Elements
      ALIASES = {
        ["fire"] => %w[flare ignis fire],
        ["water"] => %w[aqua water],
        ["earth"] => %w[land terra earth],
        ["air"] => %w[atmos ventus air wind],
        ["dark"] => %w[shadow umbra dark],
        ["light"] => %w[lumi lux light holy],

        ["fire", "water"] => %w[fire+water steam],
        ["fire", "earth"] => %w[fire+earth magma lava],
        ["fire", "air"] => %w[fire+air scorch],
        ["water", "earth"] => %w[water+earth wood ligna],
        ["water", "air"] => %w[water+air acid acidum],
        ["earth", "air"] => %w[earth+air dust],

        ["light", "fire"] => %w[light+fire solar],
        ["light", "water"] => %w[light+water],
        ["light", "earth"] => %w[light+earth],
        ["light", "air"] => %w[light+air],
        ["dark", "fire"] => %w[dark+fire],
        ["dark", "water"] => %w[dark+water abyss],
        ["dark", "earth"] => %w[dark+earth],
        ["dark", "air"] => %w[dark+air miasma],
      }
      ALIASES.each_key(&:sort!)
      ALIASES.rehash

      ALIAS_TO_COMMON = ALIASES.reduce({}) do |acc, (element, aliases)|
        aliases.each do |ali|
          acc[ali.split("+").sort] = element
        end
        acc
      end

      def self.to_element_components(element)
        values = element.split("+").sort
        ALIAS_TO_COMMON[values] || values
      end

      class Validator
        attr_reader :character

        def initialize(character)
          @character = character
        end

        def find_element(name)
          expected = Elements.to_element_components(name)
          @character.elements.find do |(element, rank)|
            Elements.to_element_components(element) == expected
          end
        end

        def validate_element_name(errors, element)
          # check using Earthen's element system
          if @character.has_elegens?
            case element
            when "ignis", "aqua", "ventus", "terra", "lux", "umbra",
                 "ice", "pressure", "crystallo", "lightning",
                 "acidum", "steam", "scorch", "dust", "ligna", "magma",
                 "solar", "abyss", "miasma",
                 "void"
              # everything is okay
            else
              errors << "has unknown earthen element `#{element}`"
            end
          else
            case element
            when "fire", "water", "earth", "wind", "light", "dark"
              # everything is okay
            else
              errors << "has unknown standard element `#{element}`"
            end
          end
          errors
        end

        def validate_element_rank(errors, element, rank)
          unless rank.original_string =~ /\ARank\s+[IVXC]+/
            errors << "has malformed element rank `#{rank}` for `#{element}`"
          end
          errors
        end

        def find_primary_elements(*list)
          list.map do |element|
            [element, find_element(element)]
          end
        end

        def validate_element_mutations(errors, element, rank)
          primary_element_name = case element
          when "crystallo"
            "earth"
          when "lightning"
            "fire"
          when "pressure"
            "air"
          when "ice"
            "aqua"
          else
            return errors
          end
          if pair = find_element(primary_element_name)
            primary_element, primary_rank = pair
            if primary_rank.to_i < 5
              errors << "primary element `#{primary_element}` MUST be Rank 5 (is #{primary_rank.to_i}) or greater to have a mutation `#{element}`"
            end
            if rank.to_i > primary_rank.to_i
              errors << "mutation element `#{element}` cannot out-rank the primary element `#{primary_element}`"
            end
          else
            errors << "mutation `#{element}` primary element `#{primary_element_name}` is missing!"
          end
          errors
        end

        def validate_element_combinations(errors, element, rank)
          comps = Elements.to_element_components(element)
          elements = case comps
          # mutations
          when Elements.to_element_components("acidum")
            find_primary_elements("water", "air")
          when Elements.to_element_components("steam")
            find_primary_elements("water", "fire")
          when Elements.to_element_components("scorch")
            find_primary_elements("air", "fire")
          when Elements.to_element_components("dust")
            find_primary_elements("earth", "air")
          when Elements.to_element_components("ligna")
            find_primary_elements("water", "earth")
          when Elements.to_element_components("magma")
            find_primary_elements("fire", "earth")

          # alignments
          when Elements.to_element_components("light+earth")
            find_primary_elements("light","earth")
          when Elements.to_element_components("light+air")
            find_primary_elements("light","air")
          when Elements.to_element_components("light+water")
            find_primary_elements("light","water")
          when Elements.to_element_components("light+fire")
            find_primary_elements("light","fire")
          when Elements.to_element_components("dark+earth")
            find_primary_elements("dark","earth")
          when Elements.to_element_components("dark+air")
            find_primary_elements("dark","air")
          when Elements.to_element_components("dark+water")
            find_primary_elements("dark","water")
          when Elements.to_element_components("dark+fire")
            find_primary_elements("dark","fire")
          else
            return errors
          end
          elements.each do |(primary_element, found)|
            if found
              _, primary_rank = found
              if primary_rank.to_i < rank.to_i
                errors << "combination element `#{element}` cannot have a rank greater than primary element `#{primary_element} (#{primary_rank})`"
              end
            else
              errors << "missing primary element `#{primary_element}` for combination element `#{element}`"
            end
          end
          errors
        end

        def validate(errors = [])
          @character.elements.each do |(element, rank)|
            validate_element_name(errors, element)
            validate_element_rank(errors, element, rank)
            validate_element_mutations(errors, element, rank)
            validate_element_combinations(errors, element, rank)
          end
          errors
        end
      end

      module RomanNumeral
        TABLE = {
          "I" => 1,
          "II" => 2,
          "III" => 3,
          "IV" => 4,
          "V" => 5,
          "VI" => 6,
          "VII" => 7,
          "VIII" => 8,
          "IX" => 9,
          "X" => 10
        }

        def self.to_int(value)
          TABLE.fetch(value, 0)
        end
      end

      class Rank
        attr_reader :original_string
        attr_reader :numeral

        def initialize(string)
          @original_string = string
          @numeral = (@original_string =~ /\ARank\s+([IVX]+)/ ? $1 : @original_string).upcase
          @int = RomanNumeral.to_int(@numeral)
        end

        def to_s
          @original_string
        end

        def to_i
          @int
        end
      end

      def self.validate_character_elements(character)
        @logger = EDST::Catalogue::Logger.new "\t#{character.name.dump}"
        errors = Validator.new(character).validate
        errors.each do |line|
          @logger.warn line
        end
      end

      def self.parse(data)
        case data
        when Array
          case data[0]
          when :value
            value = data[1] == ".." ? nil : data[1].presence
            value ? [value, nil] : nil
          when :tuple
            element, rank = data[1]
            [element, Rank.new(rank)]
          when :list
            data[1].map { |obj| parse(obj) }.compact
          else
            raise "#{data}"
          end
        when String
          data.split(",").map do |str|
            element, rank = str.split(":").map(&:strip)
            [element, Rank.new(rank)]
          end
        end
      end
    end
  end
end
