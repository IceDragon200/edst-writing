module EDST
  module Catalogue
    class CharacterRelation
      INVERTED_BRANCHES = {
        adopted_parent: :adopted_child,
        adopted_child: :adopted_parent,
        adopted_sibling: :adopted_sibling,
        pibling: :chibling,
        chibling: :pibling,
        biological_parent: :biological_child,
        biological_child: :biological_parent,
        biological_sibling: :biological_sibling,
        half_sibling: :half_sibling,
        twin_sibling: :twin_sibling,
        child: :parent,
        cousin: :cousin,
        friend: :friend,
        grand_pibling: :grand_chibling,
        grand_chibling: :grand_pibling,
        grand_child: :grand_parent,
        grand_parent: :grand_child,
        parent: :child,
        sibling: :sibling,
        spouse: :spouse,
      }.freeze

      BRANCH_TO_COLLECTION = {
        adopted_parent: :adopted_parents,
        adopted_child: :adopted_children,
        adopted_sibling: :adopted_siblings,
        pibling: :piblings,
        chibling: :chiblings,
        biological_parent: :biological_parents,
        biological_child: :biological_children,
        biological_sibling: :biological_siblings,
        half_sibling: :half_siblings,
        twin_sibling: :twin_siblings,
        child: :children,
        cousin: :cousins,
        friend: :friends,
        grand_pibling: :grand_piblings,
        grand_chibling: :grand_chiblings,
        grand_child: :grand_children,
        grand_parent: :grand_parents,
        parent: :parents,
        sibling: :siblings,
        spouse: :spouses,
      }.freeze

      BRANCHES_BY_RELATION = {
        "ex-wife" => [:spouse],
        "ex-husband" => [:spouse],
        "half-sister" => [:half_sibling, :sibling],
        "half-brother" => [:half_sibling, :sibling],
        "step-sister" => [:adopted_sibling, :sibling],
        "step-brother" => [:adopted_sibling, :sibling],
        "step-father" => [:adopted_parent, :parent],
        "step-mother" => [:adopted_parent, :parent],
        "step-daughter" => [:adopted_child, :child],
        "step-son" => [:adopted_child, :child],
        "foster-father" => [:adopted_parent, :parent],
        "foster-mother" => [:adopted_parent, :parent],
        "foster-daughter" => [:adopted_child, :child],
        "foster-son" => [:adopted_child, :child],
        "grandfather" => [:grand_parent],
        "grandmother" => [:grand_parent],
        "grandaunt" => [:grand_pibling],
        "granduncle" => [:grand_pibling],
        "grandson" => [:grand_child],
        "granddaughter" => [:grand_child],
        "wife" => [:spouse],
        "husband" => [:spouse],
        "twin-sister" => [:twin_sibling, :biological_sibling, :sibling],
        "twin-brother" => [:twin_sibling, :biological_sibling, :sibling],
        "sister" => [:biological_sibling, :sibling],
        "brother" => [:biological_sibling, :sibling],
        "father" => [:biological_parent, :parent],
        "mother" => [:biological_parent, :parent],
        "niece" => [:chibling],
        "nephew" => [:chibling],
        "aunt" => [:pibling],
        "uncle" => [:pibling],
        "cousin" => [:cousin],
        "son" => [:biological_child, :child],
        "daughter" => [:biological_child, :child],
        "friend" => [:friend],
        "childhood friend" => [:friend]
      }.freeze

      # Returns a rough guestimation of the target's gender with the given word.
      # Returns either, 'female', 'male', 'genderless', or 'unknown'
      # 'unknown' is considered an error.
      #
      # @param [String] relation
      # @return [String] male, female, genderless, unknown
      def self.gender_of_relation(relation)
        case relation
        # feminine
        when /grandmother/i, /daughter/i, /mother/i, /sister/i, /aunt/i, /niece/i, /wife/i, /woman/i, /maid/i
          'female'
        # masculine
        when /grandfather/i, /son/i, /father/i, /brother/i, /uncle/i, /nephew/i, /husband/i, /man/i, /butler/i
          'male'
        when /friend/i, /cousin/i
          'genderless'
        else
          'unknown'
        end
      end

      # Ensures that
      def self.test_gender(char, relation)
        case expected = gender_of_relation(relation)
        when 'female', 'male'
          unless char.gender == expected
            char.log.err "`relation` mismatch gender, expected to be `#{expected}`, but character is a `#{char.gender}`."
            return false
          end
        when 'unknown'
          char.log.err "`relation` unhandled relation type `#{word}`."
          false
        end
        true
      end

      def self.branches_by_relation(relation)
        key = relation.downcase
        if BRANCHES_BY_RELATION.has_key?(key)
          BRANCHES_BY_RELATION[key]
        else
          warn "unhandled relation `#{relation}`."
          []
        end
      end

      def self.invert_relation(relation, other_is_male)
        case relation
        when 'ex-wife', 'ex-husband'
          [other_is_male ? 'ex-husband' : 'ex-wife', nil]

        when /(half|step|twin)-(sister|brother)/
          prefix = $1
          [other_is_male ? "#{prefix}-brother" : "#{prefix}-sister", nil]

        when /foster-(father|mother)/
          [other_is_male ? 'foster-son' : 'foster-daughter', nil]

        when /foster-(daughter|son)/
          [other_is_male ? 'foster-father' : 'foster-mother', nil]

        when /step-(father|mother)/
          [other_is_male ? 'step-son' : 'step-daughter', nil]

        when /step-(daughter|son)/
          [other_is_male ? 'step-father' : 'step-mother', nil]

        when /grand(father|mother)/
          [other_is_male ? 'grandson' : 'granddaughter', nil]

        when /grand(aunt|uncle)/
          [other_is_male ? 'grandnewphew' : 'grandniece', nil]

        when /grand(daughter|son)/
          [other_is_male ? 'grandfather' : 'grandmother', nil]

        when 'wife', 'husband'
          [other_is_male ? 'husband' : 'wife', nil]

        when 'sister', 'brother'
          [other_is_male ? 'brother' : 'sister', nil]

        when 'father', 'mother'
          [other_is_male ? 'son' : 'daughter', nil]

        when 'niece', 'nephew'
          [other_is_male ? 'uncle' : 'aunt', nil]

        when 'aunt', 'uncle'
          [other_is_male ? 'nephew' : 'niece', nil]

        when 'son', 'daughter'
          [other_is_male ? 'father' : 'mother', nil]

        when 'childhood friend', 'best friend', 'friend', 'cousin'
          [relation, nil]

        else
          [nil, "unhandled relation `#{relation}` (should be `#{relation}` of `%<other_name>s`)."]
        end
      end

      attr_reader :character
      attr_reader :relation
      attr_reader :target_name

      def initialize(**options)
        @character = options.fetch(:character)
        @relation = options.fetch(:relation)
        @target_name = options.fetch(:target_name)
      end

      def determine_branches
        CharacterRelation.branches_by_relation @relation
      end

      private def convert_branches_to_collections(branches)
        branches.map { |value| BRANCH_TO_COLLECTION.fetch(value) }
      end

      def inverted_branches
        determine_branches.each_with_object([]) do |value, acc|
          v = INVERTED_BRANCHES.fetch(value)
          acc << v
        end
      end

      def branches_to_collections
        convert_branches_to_collections(determine_branches)
      end

      def inverted_branches_to_collections
        convert_branches_to_collections(inverted_branches)
      end
    end
  end
end
