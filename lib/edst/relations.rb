require_relative 'relations/relation_node'

module EDST
  class RelationBuilder
    attr_reader :name
    attr_reader :linked

    def initialize(name, is:)
      @name = name
      @linked = RelationNode.new(@name, constraints: is)
    end
  end

  module Relations
    class << self
      attr_accessor :relations
      attr_accessor :relations_by_alias
    end

    self.relations = {}
    self.relations_by_alias = {}

    def self.determine(a, b)
      return [] if a == b
      aleaf, bleaf = a.relation_leaf, b.relation_leaf
      @relations.each_with_object([]) do |(key, relation), acc|
        #puts "Testing if `#{a.display_name}` is a `#{key}` of `#{b.display_name}`"
        acc << relation if relation.match?(aleaf, bleaf)
      end
    end

    def self.relation(name, **options)
      RelationBuilder.new(name, **options).tap do |relation|
        relations[relation.name] = relation.linked
        relations_by_alias[relation.name] = [relation.linked]
      end
    end

    def self.alias_relation(name, specialized)
      specialized.each do |sp|
        relations = @relations_by_alias.fetch(sp)
        relations.each do |relation|
          relation.aliases.push(name)
          (relations_by_alias[name] ||= []).push(relation)
        end
      end
    end
  end

  # gender: string = 'male' || 'female'
  #   This restricts the relation to a specific gender of the child
  #
  # descendant_of_parents: integer = 1
  #   This will trigger a  parents.all? { |parent| parent.children.include?(child) }
  #   The number represents the generation gap, 1 means direct descendant, while 2 means from the grand parents, 3 and up mean great-grand etc.
  #
  # sibling: boolean | symbol = true
  #   Determines if the child should be horizontally related to the parent, meaning, they are of the same or similar parents
  #   passing the :xor option will check if the nodes only have 1 common parent in common, while true will assume both parents are the same
  module Relations
    relation('son', is: { gender: 'male', descendant_of_parents: 1 })
    relation('grandson', is: { gender: 'male', descendant_of_parents: 2 })
    relation('adopted-son', is: { gender: 'male', descendant_of_adopted_parents: 1 })
    relation('adopted-grandson', is: { gender: 'male', descendant_of_adopted_parents: 2 })
    relation('daughter', is: { gender: 'female', descendant_of_parents: 1 })
    relation('granddaughter', is: { gender: 'female', descendant_of_parents: 2 })
    relation('adopted-daughter', is: { gender: 'female', descendant_of_adopted_parents: 1 })
    relation('adopted-granddaughter', is: { gender: 'female', descendant_of_adopted_parents: 2 })
    alias_relation('offspring', ['son', 'daughter'])
    alias_relation('grandchild', ['grandson', 'granddaughter'])
    alias_relation('adopted-offspring', ['adopted-son', 'adopted-daughter'])
    alias_relation('adopted-grandchild', ['adopted-grandson', 'adopted-granddaughter'])

    relation('biological-brother', is: { gender: 'male', sibling: true })
    relation('biological-sister', is: { gender: 'female', sibling: true })
    relation('half-brother', is: { gender: 'male', sibling: :half })
    relation('half-sister', is: { gender: 'female', sibling: :half })
    relation('adopted-brother', is: { gender: 'male', sibling: :adopted })
    relation('adopted-sister', is: { gender: 'female', sibling: :adopted })
    alias_relation('biological-sibling', ['biological-brother', 'biological-sister'])
    alias_relation('half-sibling', ['half-sister', 'half-brother'])
    alias_relation('adopted-sibling', ['adopted-sister', 'adopted-brother'])
    alias_relation('sibling', ['biological-sibling', 'half-sibling', 'adopted-sibling'])

    relation('biological-mother', is: { gender: 'female', parent_of_descendant: 1 })
    relation('biological-father', is: { gender: 'male', parent_of_descendant: 1 })
    relation('adopted-mother', is: { gender: 'female', adopted_parent_of_descendant: 1 })
    relation('adopted-father', is: { gender: 'male', adopted_parent_of_descendant: 1 })
    alias_relation('biological-parent', ['biological-mother', 'biological-father'])
    alias_relation('adopted-parent', ['adopted-mother', 'adopted-father'])
    alias_relation('parent', ['biological-parent', 'adopted-parent'])

    relation('biological-grandmother', is: { gender: 'female', parent_of_descendant: 2 })
    relation('biological-grandfather', is: { gender: 'male', parent_of_descendant: 2 })
    alias_relation('biological-grandparent', ['biological-grandmother', 'biological-grandfather'])

    pibling_test = lambda do |pibling, child|
      return true if child.piblings.include?(pibling)
      # iterate through the child's parents
      child.parents.each do |parent|
        # if the parent has a sibling who happens to be this uncle/aunt
        return true if parent.siblings.include?(pibling)
      end
      false
    end

    relation('aunt', is: { gender: 'female', constraint: pibling_test })
    relation('uncle', is: { gender: 'male', constraint: pibling_test })

    chibling_test = lambda do |child, adult|
      # does the adult specify that it has a chibling?
      return true if adult.chiblings.include?(child)
      pibling_test.call(adult, child)
    end

    relation('niece', is: { gender: 'female', constraint: chibling_test })
    relation('nephew', is: { gender: 'male', constraint: chibling_test })

    cousin_test = lambda do |cousin, child|
      # the cousin's parents must not be the same as the child
      # and they must not have any parent in common
      if cousin.parents != child.parents && (cousin.parents & child.parents).empty?
        child_parents = child.parents
        cousin.parents.each do |parent|
          child_parents.each do |child_parent|
            return true if child_parent.siblings.include?(parent)
          end
        end
      end
      false
    end

    relation('cousin', is: { constraint: cousin_test })

    relation('wife', is: { gender: 'female', spouse: true })
    relation('husband', is: { gender: 'male', spouse: true })
    alias_relation('spouse', ['wife', 'husband'])
  end
end
