module EDST
  module Catalogue
    module DocumentChapters
      def chapter_frags
        @chapter_frags ||= begin
          result = []
          frag_glob_pathname = book_pathname("{chapter,chapters}/{frag,frags}/**/*.edst")
          filenames = Dir.glob(frag_glob_pathname)
          filenames.each do |filename|
            # skip any filename that starts with __, those are usually template files
            next if File.basename(filename).start_with?("__")
            doc = begin
              EDST::Document.load_file(filename, debug: true)
            rescue => ex
              puts "`#{File.expand_path(filename)}` failed to load"
              raise ex
            end

            unless doc.search('div.head').to_a.empty?
              result << Chapter.new(
                is_frag: true,
                book: self,
                cluster: nil,
                filename: filename,
                document: doc,
                extern: true)
            end
          end
          result
        end
      end

      def each_chapter_frag(&block)
        return to_enum :each_chapter_frag unless block_given?
        chapter_frags.each(&block)
      end

      def each_chapter(&block)
        return to_enum :each_chapter unless block_given?
        clusters.each do |cluster|
          cluster.chapters.each(&block)
        end
      end

      def chapters
        each_chapter.to_a
      end

      def chapter_map
        @chapter_map ||= begin
          result = {}
          each_chapter do |chapter|
            result[chapter.number] = chapter
          end
          result
        end
      end
    end
  end
end
