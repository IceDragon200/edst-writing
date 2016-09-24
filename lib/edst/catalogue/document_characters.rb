require 'edst/catalogue/utils'
require 'edst/catalogue/node_logger'

module EDST
  module Catalogue
    module DocumentCharacters
      # Patches various tag fields, since EDST makes no distinction between integers
      # and regular words and so forth.
      def patch_character(character)
        OpenStruct.conj! character, Utils.parse_character_name(character.name)

        # patch the age
        character.age = character.age.to_i

        character.gender = (character.gender && character.gender.downcase) || '<unknown>'
      end

      # Returns a rough guestimation of the target's gender with the given word.
      # Returns either, 'female', 'male', 'genderless', or 'unknown'
      # 'unknown' is considered an error.
      def check_gender_of_word(word)
        case word
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
      def assert_gender(char, word)
        case expected = check_gender_of_word(word)
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

      def fetch_character(name)
        node = @name_map[name]
        unless node
          puts "\tNo such character `#{name}`".light_red
          return nil
        end
        node
      end

      def check_relations(char)
        rel = Utils.lookup(char, 'div.relation').first
        return char[:log].warn 'missing `relation` div.' unless rel
        return char[:log].err 'empty `relation` div.' unless rel.has_children?

        ls = Utils.lookup(rel, 'list').first
        return char[:log].err '`relation` is missing a `list`.' unless ls

        character = char[:character]
        char[:log].warn "character doesn't have a gender tag." unless character.gender.present?

        ls.each_child do |ln|
          str = ln.value
          d = Utils.parse_character_relation(str)
          next char[:log].err "`relation` (#{str}) does not match (a of b) pattern." unless d

          r = d[0]
          n = d[1]
          if rel_catalogue_char = @character_list.find_by_name(n)
            if assert_gender(character, r)
              rmap = @relations_map[character.catalogue_character.base_id] ||= {}
              if node = @name_map[rel_catalogue_char.base_id]
                (rmap[r.downcase] ||= []).push node
              else
                char[:log].err "no such character #{frn}"
              end
            end
          else
            char[:log].err "`relation` (#{str}) person does not exist."
          end
        end
      end

      def does_relation_exist?(name, relof, expected_base_id)
        node = fetch_character name
        return false, nil unless node
        return false, nil unless fetch_character expected_base_id

        rels = @relations_map[name]
        unless rels
          node[:log].warn "`#{name}` has no relations"
          return false, nil
        end

        chars = rels[relof].presence
        unless chars
          node[:log].warn "`#{name}` does not have a `#{relof}` relation list. (expected to be a `#{relof}` of `#{expected_base_id}`)"
          return false, nil
        end

        chars.each do |char|
          return true, char if char[:character].catalogue_character.base_id == expected_base_id
        end

        #node[:log].err "#{name} has no relation #{relof} to #{expected_base_id}"
        node[:log].err "`#{name}` is not a `#{relof}` of `#{expected_base_id}`"
        return false, nil
      end

      def crosscheck_relations
        @relations_map.each_pair do |id, rels|
          me = @name_map[id]
          unless me
            puts "WARNING: Character (#{id}) has no name_map node"
            next
          end
          my_char = me[:character]
          i_am_male = my_char.gender.downcase == 'male'
          rels.each_pair do |rel, list|
            list.each do |node|
              their_char = node[:character]
              their_first_name = their_char.first_name
              they_are_male = their_char.gender.downcase == 'male'
              relof = case rel
              when /ex-wife/, /ex-husband/
                they_are_male ? 'ex-husband' : 'ex-wife'

              when /(half|step|twin)-(sister|brother)/
                prefix = $1
                they_are_male ? "#{prefix}-brother" : "#{prefix}-sister"

              when /step-(father|mother)/
                they_are_male ? 'step-son' : 'step-daughter'
              when /step-(daughter|son)/
                they_are_male ? 'step-father' : 'step-mother'

              when /grand(father|mother)/
                they_are_male ? 'grandson' : 'granddaughter'
              when /grand(aunt|uncle)/
                they_are_male ? 'grandnewphew' : 'grandniece'
              when /grand(daughter|son)/
                they_are_male ? 'grandfather' : 'grandmother'

              when /wife/, /husband/
                they_are_male ? 'husband' : 'wife'
              when /sister/, /brother/
                they_are_male ? 'brother' : 'sister'
              when /father/, /mother/
                they_are_male ? 'son' : 'daughter'
              when /niece/, /nephew/
                they_are_male ? 'uncle' : 'aunt'
              when /aunt/, /uncle/
                they_are_male ? 'nephew' : 'niece'
              when /son/, /daughter/
                they_are_male ? 'father' : 'mother'
              when /friend/, /childhood friend/, /cousin/
                rel
              else
                me[:log].warn "unhandled relation `#{rel}` (should be `#{rel}` of `#{their_first_name}`)."
                nil
              end

              next unless relof
              b, _ = *does_relation_exist?(their_char.catalogue_character.base_id, relof, my_char.catalogue_character.base_id)
              next unless b
              a1 = my_char.age.to_i
              a2 = their_char.age.to_i

              child, parent = nil, nil
              case rel
              # only direct descendants are calculated
              when 'daughter', 'son'
                child = my_char
                parent = their_char
              when 'father', 'mother'
                child = their_char
                parent = my_char
              end

              if child && parent
                if parent.age == 0 and child.age == 0
                  puts "\tAges cannot be determined for `#{parent.first_name.light_magenta}` and `#{child.first_name.light_magenta}`."
                elsif child.age == 0
                  puts "\tChild #{child.first_name.light_magenta} has no age!"
                elsif parent.age <= child.age
                  puts "\tParent #{parent.first_name.light_magenta}[#{parent.age}] is expected to be older than #{child.first_name.light_magenta}[#{child.age}]."
                  puts "\t\tBased on the lower age limit [18] parent should be at least #{child.age + 18}"
                else
                  if parent == my_char
                    age_at_which_child_was_born = parent.age - child.age
                    puts "\tParent #{parent.first_name.light_magenta} had child #{child.first_name.light_magenta} at age: #{age_at_which_child_was_born}"
                  end
                end
              end
            end
          end
        end
      end

      def load_characters_main(filenames)
        @name_map = {}
        @relations_map = {}
        @character_list = Catalogue::CharacterList.new

        pool = []
        files_checked = 0
        sources = filenames.presence || Dir.glob('character/*.edst')
        sources.sort.each do |filename|
          next if File.basename(filename).start_with?('#')
          root = EDST::Document.load_file(filename)
          root[:filename] = filename
          root[:log] = NodeLogger.new(root)

          chars = []
          if (char = Utils.lookup(root, 'div.character')).present?
            chars = char
          elsif (dchars = Utils.lookup(root, 'div.characters')).present?
            unless (chars = Utils.lookup(dchars[0], 'div.character')).present?
              root[:log].err 'div.characters is empty.'
            end
          else
            root[:log].err 'No character found'
          end

          chars.each do |char|
            char[:filename] = filename
            char[:log] = NodeLogger.new(char)
            pool << char
          end
          files_checked += 1
        end

        puts ".. \tFound #{pool.size} characters in #{files_checked} files"

        # we first map the characters to a name table
        pool.each do |char|
          name = Utils.lookup(char, 'tag.name').first
          next char[:log].err 'missing `name` tag.' unless name

          cat_char = @character_list.add Catalogue::Character.new(id, char)
          ost = OpenStruct.new
          ost[:aliases] = []
          char.each_child.select { |node| node.kind == :tag }.each do |node|
            node_key = node.key.downcase
            case node_key
            when /\Aalias(?:\.(\S+))?/
              ost[:aliases] << node.value
            else
              ost[node.key.downcase] = node.value
            end
          end
          ost.log = char[:log] # borrowing

          patch_character ost

          # ensure that each name is unique
          char[:character] ||= ost
          if m = @name_map[cat_char.base_id]
            char[:log].warn "Name (#{cat_char.base_id}) was already mapped for #{m[:filename]}"
          else
            char[:name] = ost.name
            if ost.age == 0
              char[:log].warn "Age is 0, are you sure thats what you wanted?"
            end
            char[:character].catalogue_character = cat_char
            @name_map[cat_char.base_id] = char
          end
        end

        pool
      end

      def load_and_validate_characters(filenames)
        pool = load_characters_main filenames
        # then we check their relations
        puts ".. \tSetting up relations map and checking basic relations"
        pool.each do |char|
          check_relations(char)
        end

        puts ".. \tCross checking relations"
        crosscheck_relations
        pool
      end
    end
  end
end
