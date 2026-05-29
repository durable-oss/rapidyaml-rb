# frozen_string_literal: true

require_relative 'lib/rapidyaml/version'

Gem::Specification.new do |spec|
  spec.name        = 'rapidyaml'
  spec.version     = RapidYAML::VERSION
  spec.authors     = ['Durable Programming LLC']
  spec.email       = ['commercial@durableprogramming.com']
  spec.summary     = 'Fast YAML parsing and emission via rapidyaml — drop-in Psych replacement'
  spec.description = 'Ruby bindings to rapidyaml (ryml), a C++ YAML library. ' \
                     'Exposes a Psych-compatible API so it can be used as a drop-in replacement.'
  spec.homepage    = 'https://github.com/durable-oss/rapidyaml'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir[
    'lib/**/*',
    'ext/**/*',
    'LICENSE',
    'rapidyaml.gemspec'
  ].reject { |f| File.directory?(f) }

  spec.extensions = ['ext/rapidyaml/extconf.rb']

  spec.add_development_dependency 'minitest',            '~> 5.0'
  spec.add_development_dependency 'rake',                '~> 13.0'
  spec.add_development_dependency 'rake-compiler',       '~> 1.2'
  spec.add_development_dependency 'rake-compiler-dock',  '~> 1.4'
  spec.add_development_dependency 'rice',                '~> 4.0'
  spec.add_development_dependency 'rubocop',             '> 1.86.0'
  spec.add_development_dependency 'rubocop-minitest',    '> 0.39.0'
end
