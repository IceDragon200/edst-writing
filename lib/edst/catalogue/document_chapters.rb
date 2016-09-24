module EDST
  module Catalogue
    module DocumentChapters
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
