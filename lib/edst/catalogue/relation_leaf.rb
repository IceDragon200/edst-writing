require 'set'

module EDST
  module Catalogue
    class RelationLeaf
      # the current character
      attr_reader :character

      GROUPS = [
        :biological_parents,
        :adopted_parents,
        :parents,
        # parent siblings (aunts, uncles)
        :piblings,
        :biological_siblings,
        :half_siblings,
        :twin_siblings,
        :adopted_siblings,
        :siblings,
        :biological_children,
        :adopted_children,
        :children,
        # nephews, nieces
        :chiblings,
        :cousins,
        :friends,
        :spouses
      ]

      GROUPS.each do |sym|
        define_method sym do
          @group_by_name[sym]
        end
      end

      def initialize(character)
        @character = character
        @character.relation_leaf = self if @character
        @groups = []
        @group_by_name = {}
        GROUPS.each do |group|
          add_group group
        end
      end

      def name
        @character.name
      end

      def display_name
        @character.display_name
      end

      private def add_group(name)
        #result = Set.new
        result = []
        @group_by_name[name] = result
        @groups << [name, result]
      end

      def ancestors
        parents.inject([]) { |acc, parent| acc.concat(parent.ancestors) }
      end

      def descendants
        children.inject([]) { |acc, child| acc.concat(child.descendants) }
      end

      def each(&block)
        return to_enum :each unless block_given?
        @groups.each do |_, values|
          values.each(&block)
        end
      end

      def each_relation
        return to_enum :each_relation unless block_given?
        @groups.each do |key, values|
          yield key, values
        end
      end

      def display_relations
        puts "`#{name}` Relations"
        each_relation do |key, values|
          unless values.empty?
            puts ":#{key}"
            values.each do |v|
              puts "\t#{v.name}"
            end
          end
        end
      end
    end
  end
end
