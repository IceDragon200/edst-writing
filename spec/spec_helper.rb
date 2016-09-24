require 'codeclimate-test-reporter'
require 'simplecov'

def fixture_pathname(name)
  File.expand_path(File.join('fixtures', name), __dir__)
end

CodeClimate::TestReporter.start
SimpleCov.start
