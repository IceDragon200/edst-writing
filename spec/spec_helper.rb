def fixture_pathname(name)
  File.expand_path(File.join('fixtures', name), __dir__)
end
