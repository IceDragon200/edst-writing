require 'edst/catalogue/utils'
require 'edst/catalogue/node_logger'
require 'edst/catalogue/character_relation'

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
          relation, character_name = Utils.parse_character_relation(str)
          unless relation && character_name
            char[:log].err "`relation` (#{str}) does not match (a of b) pattern."
            next
          end
          if rel_catalogue_char = @character_list.find_by_name(character_name)
            if CharacterRelation.test_gender(character, relation)
              rmap = @relations_map[character.catalogue_character.base_id] ||= {}
              if node = @name_map[rel_catalogue_char.base_id]
                (rmap[relation.downcase] ||= []).push node
              else
                char[:log].err "no such character #{frn}"
              end
            end
          else
            char[:log].err "`relation` (#{character_name}) person does not exist."
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
              other_char = node[:character]
              other_is_male = other_char.gender.downcase == 'male'
              relof, err = CharacterRelation.invert_relation(rel, other_is_male)
              me[:log].warn(err % { other_name: other_char.name }) if err

              next unless relof
              b, _ = *does_relation_exist?(other_char.catalogue_character.base_id, relof, my_char.catalogue_character.base_id)
              next unless b
              a1 = my_char.age.to_i
              a2 = other_char.age.to_i

              child, parent = nil, nil
              case rel
              # only direct descendants are calculated
              when 'daughter', 'son'
                child = my_char
                parent = other_char
              when 'father', 'mother'
                child = other_char
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
          char.each_child do |node|
            case node.kind
            when :div
              node_key = node.key.downcase
              ost[node.key.downcase] = Catalogue::Utils.node_to_data(node)
            when :tag
              node_key = node.key.downcase
              case node_key
              when /\Aalias(?:\.(\S+))?/
                ost[:aliases] << node.value
              else
                ost[node.key.downcase] = node.value
              end
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
