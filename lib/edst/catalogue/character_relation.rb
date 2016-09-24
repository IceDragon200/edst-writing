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
        grand_au: :grand_nn,
        grand_child: :grand_parent,
        grand_parent: :grand_child,
        nn: :au,
        parent: :child,
        sibling: :sibling,
        spouse: :spouse,
      }

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
        grand_au: :grand_aus,
        grand_nn: :grand_nns,
        grand_child: :grand_children,
        grand_parent: :grand_parents,
        nn: :nns,
        parent: :parents,
        sibling: :siblings,
        spouse: :spouses,
      }

      attr_reader :character
      attr_reader :relation
      attr_reader :target_name

      def initialize(**options)
        @character = options.fetch(:character)
        @relation = options.fetch(:relation)
        @target_name = options.fetch(:target_name)
      end

      def determine_branches
        case @relation.downcase
        when "ex-wife", "ex-husband"
          [:spouse]
        when "half-sister", "half-brother"
          [:half_sibling, :sibling]
        when "step-sister", "step-brother"
          [:adopted_sibling, :sibling]
        when "step-father", "step-mother"
          [:adopted_parent, :parent]
        when "step-daughter", "step-son"
          [:adopted_child, :child]
        when "grandfather", "grandmother"
          [:grand_parent]
        when "grandaunt", "granduncle"
          [:grand_au]
        when "grandson", "granddaughter"
          [:grand_child]
        when "wife", "husband"
          [:spouse]
        when "twin-sister", "twin-brother"
          [:twin_sibling, :biological_sibling, :sibling]
        when "sister", "brother"
          [:biological_sibling, :sibling]
        when "father", "mother"
          [:biological_parent, :parent]
        when "niece", "nephew"
          [:chibling]
        when "aunt", "uncle"
          [:pibling]
        when "cousin"
          [:cousin]
        when "son", "daughter"
          [:biological_child, :child]
        when "friend", "childhood friend"
          [:friend]
        else
          warn "unhandled relation `#{@relation}` (should be `#{@relation}` of `#{@target_name}`)."
          []
        end
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
