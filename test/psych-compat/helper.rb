# frozen_string_literal: true

# Psych compatibility test helper.
#
# These tests are adapted from the Psych test suite
# (inspirations/psych/test/psych/) and run against RapidYAML to verify
# API-level compatibility with the standard Ruby YAML library.
#
# KNOWN DIFFERENCES FROM PSYCH (documented, not bugs):
#
#   - No ruby object tags (!ruby/object, !ruby/struct, !ruby/data, etc.)
#     rapidyaml only serializes plain Ruby data structures plus
#     Symbol, Date, and Time via permitted_classes:.
#
#   - No alias same-object identity (assert_same on alias targets)
#     rapidyaml resolves aliases to equal values, not the same object.
#
#   - No YAML 1.1 extended booleans (yes/no/on/off)
#     rapidyaml follows YAML 1.2: only true/false are booleans.
#
#   - No dump options (line_width, canonical, header, version, indentation)
#     rapidyaml's dump output format is fixed.
#
#   - No ScalarScanner, parse/parse_file/parse_stream, or visitor APIs
#     rapidyaml does not expose a parse tree.
#
#   - No domain types or add_builtin_type callbacks
#
#   - No freeze: option on load
#
#   - DateTime is not supported (Psych uses !ruby/object:DateTime tag)
#     Use Time instead.

require 'minitest/autorun'
require 'stringio'
require 'tempfile'
require 'rapidyaml'

module PsychCompat
  Y = RapidYAML

  class TestCase < Minitest::Test
    # Round-trips obj through dump then load and asserts equality.
    def assert_cycle(obj)
      result = Y.load(Y.dump(obj))
      if obj.nil?
        assert_nil result
      else
        assert_equal obj, result
      end
    end

    # Parses yaml and asserts equality with obj.
    def assert_parse_only(obj, yaml)
      assert_equal obj, Y.load(yaml)
    end

    # Dumps obj, re-parses, and asserts equality both ways.
    def assert_to_yaml(obj, yaml)
      assert_equal obj, Y.load(yaml)
      assert_equal obj, Y.load(Y.dump(obj))
    end
  end
end
