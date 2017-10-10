module EDST
  module Catalogue
    module DocumentChapters
      def chapter_frags
        @chapter_frags ||= begin
          result = []
          filenames = Dir.glob(book_pathname("{chapter,chapters}/{frag,frags}/**/*.edst"))
          filenames.each do |filename|
            doc = EDST::Document.load_file(filename)
            unless doc.search('div.head').empty?
              result << Chapter.new(
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
