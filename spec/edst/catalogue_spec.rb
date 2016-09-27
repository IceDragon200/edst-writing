require 'spec_helper'
require 'edst/catalogue'

describe EDST::Catalogue do
  context ".preload" do
    it 'will preload a list of books from a given directory path' do
      #described_class.preload(rootpath: fixture_pathname('books'))
      described_class.preload(rootpath: "/home/icy/docs/texts/Writing")
    end
  end
end
