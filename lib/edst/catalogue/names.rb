require 'edst/util'

module EDST
  module Catalogue
    module Names
      class Name < Struct.new(
        # first name
        :first_name,
        # because you can have multiple middle names
        :middle_names,
        # last name
        :last_name,
        # aliases act as alternatives to first_name
        :aliases,
        # character's name before marriage
        :pre_married_name)

        def has_different_last_name?
          pre_married_name != last_name
        end

        def first_and_family_name
          [first_name, last_name].compact.join(" ")
        end

        def pre_married_full_name
          [first_name, *(middle_names || []), pre_married_name].join(" ")
        end

        def middle_name
          middle_names&.first
        end

        def each_pair
          return to_enum :each_pair unless block_given?
          yield :aliases, aliases if EDST::Util.is_present?(aliases)
          yield :first_name, first_name if EDST::Util.is_present?(first_name)
          #yield :middle_name, middle_name if middle_name.is_present?
          yield :middle_names, middle_names if EDST::Util.is_present?(middle_names)
          yield :last_name, last_name if EDST::Util.is_present?(last_name)
          yield :pre_married_name, pre_married_name if EDST::Util.is_present?(pre_married_name)
        end

        def to_s
          [first_name, *(middle_names || []), last_name].compact.join(" ")
        end

        def pretty_format
          [
            first_name,
            aliases.map { |a| "(#{a})" },
            *(middle_names || []),
            last_name
          ].select do |str|
            EDST::Util.is_present?(str)
          end.compact.join(" ")
        end
      end

      def self.handle_placeholder(str)
        # remove the placeholders '_' and replace them with nothing
        return nil if str == "_"
        EDST::Util.presence(str)
      end

      def self.extract_aliases(words)
        aliases = []
        remaining = []
        words.each do |word|
          if word =~ /\((\w+)\)/
            aliases << $1
          else
            remaining << word
          end
        end
        return aliases, remaining
      end

      def self.parse(str)
        return nil if str.nil?
        return str if str.kind_of?(Name)
        name = Name.new
        aliases, remaining = extract_aliases str.split(/\s+/)
        remaining = remaining.map { |v| handle_placeholder v }
        aliases = aliases.map { |v| handle_placeholder v }.compact
        if remaining.size >= 3
          fn = remaining.first
          md = remaining.slice(1, remaining.size - 2)
          ln = remaining.last
          name.first_name, name.middle_names, name.last_name = fn, md, ln
        elsif remaining.size == 2
          name.first_name, name.last_name = *remaining
        elsif remaining.size == 1
          name.first_name = remaining.first
        end
        name.aliases = EDST::Util.presence(aliases)
        name
      end

      def self.equal_middle_name?(actual, expected, **_options)
        if EDST::Util.is_present?(actual.middle_names) && EDST::Util.is_present?(expected.middle_names)
          unless (actual.middle_names & expected.middle_names) == expected.middle_names
            return false
          end
        end
        true
      end

      def self.equal_last_name?(actual, expected, check_pre_married_name: true)
        if check_pre_married_name
          if actual.last_name && EDST::Util.is_present?(expected.pre_married_name)
            return true if expected.pre_married_name == actual.last_name
          end

          if expected.last_name && EDST::Util.is_present?(actual.pre_married_name)
            return true if actual.pre_married_name == expected.last_name
          end
        end

        if actual.last_name && expected.last_name
          return false unless actual.last_name == expected.last_name
        end

        true
      end

      def self.equal_first_name?(actual, expected, check_aliases: true)
        if check_aliases
          if actual.first_name && EDST::Util.is_present?(expected.aliases)
            return true if expected.aliases.include?(actual.first_name)
          end

          if expected.first_name && EDST::Util.is_present?(actual.aliases)
            return true if actual.aliases.include?(expected.first_name)
          end
        end

        if actual.first_name && expected.first_name
          return false unless actual.first_name == expected.first_name
        end
        true
      end

      def self.equal?(aname, bname, check_aliases: true, check_pre_married_name: true)
        actual, expected = parse(aname), parse(bname)

        if actual and expected then
          return false unless equal_middle_name?(actual, expected)
          return false unless equal_last_name?(actual, expected, check_pre_married_name: check_pre_married_name)
          return false unless equal_first_name?(actual, expected, check_aliases: check_aliases)

          return true
        end

        false
      end
    end
  end
end
