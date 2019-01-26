lib = File.join(File.dirname(__FILE__), 'lib')
$:.unshift lib unless $:.include?(lib)

require 'date'
require 'edst/catalogue/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'edst-writing'
  s.summary     = 'EDST writing toolkit'
  s.description = 'Extension for handling EDST story boards.'
  s.date        = Time.now.to_date.to_s
  s.version     = EDST::Catalogue::Version::STRING
  s.homepage    = 'https://github.com/IceDragon200/edst-writing/'
  s.license     = 'MIT'

  s.authors = ['Corey Powell']
  s.email  = 'mistdragon100@gmail.com'

  s.add_runtime_dependency 'activesupport',  '>= 4.2', '< 6.0'
  s.add_runtime_dependency 'colorize',       '~> 0.7'
  s.add_runtime_dependency 'rake',           '~> 10.3'
  s.add_runtime_dependency 'edst',           '~> 0.32'
  s.add_runtime_dependency 'edst-documents', '~> 0.3'
  # dev
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0'
  s.add_development_dependency 'simplecov', '~> 0'
  s.add_development_dependency 'rspec',     '~> 3.1'

  s.require_path = 'lib'
  s.executables = Dir.glob('bin/*').map { |s| File.basename(s) }
  s.files = ['Gemfile']
  s.files.concat(Dir.glob('{bin,lib,spec}/**/*'))
end
