module EDST
  module Catalogue
    # Le Version module, what more do you need to know.
    module Version
      MAJOR, MINOR, TEENY, PATCH = 1, 0, 1, nil
      STRING = [MAJOR, MINOR, TEENY, PATCH].compact.join('.').freeze
    end
    VERSION = Version::STRING
  end
end
