# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark/ips'
require 'psych'
require 'rapidyaml'

yaml_files = Dir[File.join(__dir__, 'yaml', '*.yaml')]
raise "No YAML fixtures found in #{__dir__}/yaml/" if yaml_files.empty?

YAML_STRINGS = yaml_files.map { |p| File.read(p) }.freeze

Benchmark.ips do |x|
  x.config(time: 10, warmup: 3)

  x.report('psych') do
    YAML_STRINGS.each { |s| Psych.safe_load(s) }
  end

  x.report('rapidyaml') do
    YAML_STRINGS.each { |s| RapidYAML.load(s) }
  end

  x.compare!
end
