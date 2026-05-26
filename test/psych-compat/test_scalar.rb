# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_yaml.rb (test_basic_strings)
# and inspirations/psych/test/psych/test_string.rb
class TestPsychCompatScalar < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_plain_string
    assert_equal 'simple string', Y.load('--- simple string')
  end

  def test_single_quoted_string
    assert_equal '1 Single Quoted String', Y.load("--- '1 Single Quoted String'")
  end

  def test_double_quoted_string_with_escapes
    assert_equal "Psych's Double \"Quoted\" String",
                 Y.load(%(--- "Psych's Double \\"Quoted\\" String"))
  end

  def test_literal_block_scalar
    assert_equal "A block\n  with several\n    lines.\n",
                 Y.load("--- |\n  A block\n    with several\n      lines.\n")
  end

  def test_literal_block_scalar_chomped
    assert_equal 'A "chomped" block',
                 Y.load("--- |-\n  A \"chomped\" block\n")
  end

  def test_folded_block_scalar
    assert_equal "A folded\n string\n",
                 Y.load("--- >\n  A\n  folded\n   string\n")
  end

  def test_colon_started_string
    assert_equal ': started string', Y.load('--- ": started string"')
  end

  def test_multiline_string_roundtrip
    str = "line one\nline two\n"

    assert_equal str, Y.load(Y.dump(str))
  end

  def test_string_with_special_characters_roundtrip
    str = 'hello & world <test>'

    assert_equal str, Y.load(Y.dump(str))
  end

  def test_utf8_string_roundtrip
    str = 'Český non-ASCII'

    assert_equal str, Y.load(Y.dump(str))
  end

  def test_empty_string_roundtrip
    assert_equal '', Y.load(Y.dump(''))
  end

  # Psych quotes YAML 1.1 boolean-like strings to prevent misinterpretation.
  # rapidyaml only recognizes true/false as booleans (YAML 1.2), so these
  # strings should round-trip correctly without quoting being required.
  def test_boolean_like_strings_roundtrip
    %w[yes Yes YES no No NO on On ON off Off OFF].each do |word|
      assert_equal word, Y.load(Y.dump(word)),
                   "expected '#{word}' to round-trip as a string"
    end
  end
end
