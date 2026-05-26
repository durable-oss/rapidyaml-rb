# frozen_string_literal: true

require 'rapidyaml'

# Basic round-trip
yaml = "---\nfoo: bar\nbaz: 42\n"
result = RapidYAML.load(yaml)
raise 'load failed' unless result == { 'foo' => 'bar', 'baz' => 42 }

roundtrip = RapidYAML.dump(result)
raise 'dump failed' unless RapidYAML.load(roundtrip) == result

puts "OK ruby=#{RUBY_VERSION} rapidyaml=#{RapidYAML::VERSION}"
