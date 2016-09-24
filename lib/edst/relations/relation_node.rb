module EDST
  class RelationNode
    attr_accessor :key
    attr_accessor :aliases
    attr_accessor :constraints

    def initialize(key, **options)
      @key = key
      @constraints = options.fetch(:constraints)
      @aliases = []
    end

    def to_s
      @key
    end

    def is_descendant_of_parents?(scope, child, parent, depth = 1)
      top = [child]
      depth.times { top = top.map(&:biological_parents).flatten }
      top.include?(parent)
    end

    def is_descendant_of_adopted_parents?(scope, child, parent, depth = 1)
      top = [child]
      depth.times { top = top.map(&:adopted_parents).flatten }
      top.include?(parent)
    end

    def is_parent_of_descendant?(scope, parent, child, depth = 1)
      is_descendant_of_parents?(scope, child, parent, depth)
    end

    def is_adopted_parent_of_descendant?(scope, parent, child, depth = 1)
      is_descendant_of_adopted_parents?(scope, child, parent, depth)
    end

    def is_spouse?(scope, a, b)
      a.spouses.include?(b)
    end

    # does a and b have XOR parents?
    def has_xor_parents?(scope, a, b)
      a.parents != b.parents && !(a.parents & b.parents).empty?
    end

    def is_biological_siblings?(scope, child, other)
      child.biological_siblings.include?(other)
    end

    def is_adopted_siblings?(scope, child, other)
      child.adopted_siblings.include?(other)
    end

    def is_half_siblings?(scope, child, other)
      child.half_siblings.include?(other)
    end

    def is_sibling?(scope, child, other)
      child.siblings.include?(other)
    end

    def match?(scope, a, b)
      # if they are the same, just abort immediately
      return false if a == b
      @constraints.each do |key, value|
        case key
        when :gender
          return false unless a.character.gender == value
        when :descendant_of_parents
          return false unless is_descendant_of_parents?(scope, a, b, value)
        when :descendant_of_adopted_parents
          return false unless is_descendant_of_adopted_parents?(scope, a, b, value)
        when :sibling
          case value
          when :half
            return false unless is_half_siblings?(scope, a, b)
          when :adopted
            return false unless is_adopted_siblings?(scope, a, b)
          when true
            return false unless is_biological_siblings?(scope, a, b)
          else
            return false if is_biological_siblings?(scope, a, b)
          end
        when :parent_of_descendant
          return false unless is_parent_of_descendant?(scope, a, b, value)
        when :adopted_parent_of_descendant
          return false unless is_adopted_parent_of_descendant?(scope, a, b, value)
        when :constraint
          return false unless value.call(scope, a, b)
        when :spouse
          if value
            return false unless is_spouse?(scope, a, b)
          else
            return false if is_spouse?(scope, a, b)
          end
        else
          raise ArgumentError, "invalid constraint key `#{key.inspect}`"
        end
      end
    end
  end
end
