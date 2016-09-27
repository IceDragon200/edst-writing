require 'spec_helper'
require 'edst/catalogue/names'

describe EDST::Catalogue::Names do
  context '.parse' do
    it 'will parse a name, given the first and last' do
      name = described_class.parse("John Doe")
      expect(name.first_name).to eq("John")
      expect(name.last_name).to eq("Doe")
    end

    it 'will parse a name, given the first, middle and last' do
      name = described_class.parse("John Foo Doe")
      expect(name.first_name).to eq("John")
      expect(name.middle_name).to eq("Foo")
      expect(name.last_name).to eq("Doe")
    end

    it 'will parse a name, given the first, multiple middle and last' do
      name = described_class.parse("John Foo Bar Doe")
      expect(name.first_name).to eq("John")
      expect(name.middle_name).to eq("Foo")
      expect(name.middle_names).to eq(["Foo", "Bar"])
      expect(name.last_name).to eq("Doe")
    end

    it 'will drop place holders' do
      name = described_class.parse("John _ Doe")
      expect(name.first_name).to eq("John")
      expect(name.middle_name).to eq(nil)
      expect(name.last_name).to eq("Doe")
    end

    it 'can parse aliases out of the name' do
      name = described_class.parse("John (Silver) Doe")
      expect(name.first_name).to eq("John")
      expect(name.aliases).to include("Silver")
      expect(name.last_name).to eq("Doe")
    end
  end

  context '.equal?' do
    it 'will compare 2 name strings' do
      expect(described_class).to be_equal("John James Doe", "John Doe")
      expect(described_class).to be_equal("John James Doe", "John")
      expect(described_class).to be_equal("John Johnathan James Doe", "John James Doe")
      expect(described_class).to be_equal("John (Silver) Doe", "Silver Doe")
      expect(described_class).not_to be_equal("John (Silver) Doe", "Silver Doe", check_aliases: false)
      expect(described_class).not_to be_equal("John Doe", "Henry Doe")
    end
  end
end
