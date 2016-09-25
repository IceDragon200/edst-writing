require 'edst/catalogue/utils'
require 'edst/catalogue/relation_leaf'
require 'edst/catalogue/character_relation'
require 'edst/catalogue/character'
require 'edst/catalogue/character_list'
require 'edst/catalogue/document_common'
require 'edst/catalogue/document_chapters'
require 'edst/catalogue/chapter'
require 'edst/catalogue/cluster'
require 'edst/catalogue/arc'
require 'edst/catalogue/book'
require 'edst/catalogue/library'

module EDST
  module Catalogue
    def self.preload(rootpath: __dir__, lazy_load: true)
      library = EDST::Catalogue::Library.new
      book_glob = File.expand_path("**/book.edst", rootpath)
      Dir.glob(book_glob) do |book_filename|
        library.load_book(book_filename, lazy_load: lazy_load)
      end
      library.load_characters
      library
    end
  end
end
