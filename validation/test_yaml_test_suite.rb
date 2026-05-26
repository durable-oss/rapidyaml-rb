# frozen_string_literal: true

require 'minitest/autorun'
require 'psych'
require 'json'
require 'open3'
require 'rbconfig'
require_relative '../lib/rapidyaml'

SUITE_DIR = File.expand_path('../vendor/yaml-test-suite/src', __dir__)

unless Dir.exist?(SUITE_DIR)
  abort "yaml-test-suite not found at #{SUITE_DIR}.\n" \
        'Run: git clone --depth 1 https://github.com/yaml/yaml-test-suite vendor/yaml-test-suite'
end

# Expand the visual placeholders the suite uses for non-printable characters.
def expand_yaml_placeholders(str)
  str
    .gsub('␣', ' ')
    .gsub('———»', "\t")
    .gsub('——»',  "\t")
    .gsub('—»',   "\t")
    .gsub('»',    "\t")
    .gsub('↵',    "\n")
    .gsub('∎',    '')
    .gsub('←',    "\r")
    .gsub('⇔',    '﻿')
end

# Parse the concatenated multi-document JSON produced by the suite.
# Each top-level JSON value is separated by a bare newline between values.
def parse_json_stream(raw)
  results = []
  pos = 0
  str = raw.strip
  while pos < str.length
    # skip leading whitespace
    pos += 1 while pos < str.length && str[pos] =~ /\s/
    break if pos >= str.length

    # Ruby's JSON.parse doesn't support streaming, so we walk forward until
    # we have a complete value by attempting parses of increasing length.
    # This is O(n^2) but test data is tiny.
    not_found = Object.new
    parsed = not_found
    ((pos + 1)..str.length).each do |len|
      candidate = str[pos, len - pos]
      begin
        parsed = JSON.parse(candidate)
        pos = len
        break
      rescue JSON::ParserError
        next
      end
    end
    break if parsed.equal?(not_found)

    results << parsed
  end
  results
end

# Load all test cases from src/*.yaml using Psych (the suite is itself YAML).
def load_test_cases
  cases = []
  Dir.glob(File.join(SUITE_DIR, '*.yaml')).each do |path|
    id = File.basename(path, '.yaml')
    docs = Psych.safe_load_stream(File.read(path))
    docs.each do |doc|
      next unless doc.is_a?(Array)

      doc.each_with_index do |tc, idx|
        next unless tc.is_a?(Hash)
        next if tc['skip']

        label = tc['name'] || "#{id}/#{idx}"
        cases << {
          id: "#{id}##{idx}",
          label: label,
          yaml: expand_yaml_placeholders(tc['yaml'] || ''),
          json: tc['json'],
          dump: tc['dump'],
          fail: tc['fail'] == true
        }
      end
    end
  end
  cases
end

TEST_CASES = load_test_cases.freeze

class YamlTestSuiteLoad < Minitest::Test
  TEST_CASES.each do |tc|
    if tc[:fail]
      define_method("test_load_error_#{tc[:id]}") do
        assert_raises(RapidYAML::SyntaxError, RapidYAML::Error) do
          RapidYAML.load_stream(tc[:yaml])
        end
      end
    elsif tc[:json]
      define_method("test_load_vs_json_#{tc[:id]}") do
        expected = parse_json_stream(tc[:json])
        actual   = RapidYAML.load_stream(tc[:yaml])
        assert_equal expected, actual,
                     "#{tc[:id]} #{tc[:label].inspect}: rapidyaml vs JSON mismatch"
      end

      define_method("test_load_psych_vs_json_#{tc[:id]}") do
        expected = parse_json_stream(tc[:json])
        actual = begin
          Psych.safe_load_stream(tc[:yaml], aliases: true)
        rescue Psych::SyntaxError, Psych::Exception => e
          skip "Psych cannot parse this input: #{e.message}"
        end
        assert_equal expected, actual,
                     "#{tc[:id]} #{tc[:label].inspect}: Psych vs JSON mismatch"
      end

      define_method("test_load_compat_#{tc[:id]}") do
        ryaml = RapidYAML.load_stream(tc[:yaml])
        psych = begin
          Psych.safe_load_stream(tc[:yaml], aliases: true)
        rescue Psych::SyntaxError, Psych::Exception => e
          skip "Psych cannot parse this input: #{e.message}"
        end
        assert_equal psych, ryaml,
                     "#{tc[:id]} #{tc[:label].inspect}: rapidyaml vs Psych mismatch"
      end
    end
  end
end

# Dump tests are run in a subprocess per test to isolate segfaults in Ext.emit.
# A crash becomes a test failure rather than killing the whole suite.
class YamlTestSuiteDump < Minitest::Test
  TEST_CASES.each do |tc|
    next unless tc[:dump] && !tc[:fail]

    define_method("test_dump_#{tc[:id]}") do
      script = <<~RUBY
        require_relative #{File.expand_path('../lib/rapidyaml', __dir__).inspect}
        require "json"
        docs = RapidYAML.load_stream(#{tc[:yaml].inspect})
        puts docs.map { |d| RapidYAML.dump(d) }.join
      RUBY
      out, status = Open3.capture2e(RbConfig.ruby, '-e', script)
      flunk "#{tc[:id]} #{tc[:label].inspect}: dump crashed (exit #{status.exitstatus})\n#{out}" unless status.success?
      assert_equal tc[:dump], out,
                   "#{tc[:id]} #{tc[:label].inspect}: dump output mismatch"
    end
  end
end
