# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'efir'
  s.version = '1.0.0-rc1'
  s.summary = 'ethereum client'
  s.author = 'soylent'
  s.files = Dir['bin/*', 'lib/**/*']
  s.executables = 'efir'
  s.rdoc_options = ['--exclude', 'lib']
  s.required_ruby_version = '>= 2.5.0'
  s.add_development_dependency 'cutest', '~> 1.2'
end
