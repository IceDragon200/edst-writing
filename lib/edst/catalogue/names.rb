require 'active_support/core_ext/object'

module EDST
  module Catalogue
    module Names
      class Name < Struct.new(:first_name, :middle_names, :last_name, :aliases)
        def first_and_family_name
          [first_name, last_name].compact.join(" ")
        end

        def middle_name
          middle_names&.first
        end

        def each_pair
          return to_enum :each_pair unless block_given?
          yield :first_name, first_name if first_name.present?
          #yield :middle_name, middle_name if middle_name.present?
          yield :middle_names, middle_names if middle_names.present?
          yield :last_name, last_name if last_name.present?
        end

        def to_s
          [first_name, *(middle_names || []), last_name].compact.join(" ")
        end
      end

      def self.handle_placeholder(str)
        # remove the placeholders '_' and replace them with nothing
        return nil if str == "_"
        str.presence
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
        name.aliases = aliases.presence
        name
      end

      def self.equal?(aname, bname, check_aliases: true)
        actual, expected = parse(aname), parse(bname)
        if actual.middle_names.present? && expected.middle_names.present?
          unless (actual.middle_names & expected.middle_names) == expected.middle_names
            return false
          end
        end

        if actual.last_name && expected.last_name
          return false unless actual.last_name == expected.last_name
        end

        if check_aliases
          if actual.first_name && expected.aliases.present?
            return true if expected.aliases.include?(actual.first_name)
          end

          if expected.first_name && actual.aliases.present?
            return true if actual.aliases.include?(expected.first_name)
          end
        end

        if actual.first_name && expected.first_name
          return false unless actual.first_name == expected.first_name
        end
        true
      end
    end
  end
end
