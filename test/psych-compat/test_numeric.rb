# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_numeric.rb
# Tests numeric scalar parsing against the YAML spec.
class TestPsychCompatNumeric < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_load_float_with_trailing_dot
    assert_in_delta(1.0, Y.load('--- 1.'))
  end

  def test_non_float_with_leading_zero
    # YAML 1.2: a leading zero makes the token a string, not an integer.
    # "090" is not valid octal, and base-10 leading zeros are not integers.
    assert_equal '090', Y.load('--- 090')
  end

  def test_does_not_attempt_numeric_with_space
    assert_equal '4 roses', Y.load('--- 4 roses')
  end

  def test_does_not_attempt_numeric_with_dots
    assert_equal '1.1.1', Y.load('--- 1.1.1')
  end

  def test_integer_roundtrip
    assert_cycle 0
    assert_cycle 42
    assert_cycle(-42)
  end

  def test_float_roundtrip
    assert_cycle 1.0
    assert_cycle 3.14
    assert_cycle(-2.5)
  end

  def test_infinity
    assert_equal(1 / 0.0, Y.load('--- .inf'))
    assert_equal(1 / 0.0, Y.load('--- .Inf'))
    assert_equal(1 / 0.0, Y.load('--- .INF'))
  end

  def test_negative_infinity
    assert_equal(-1 / 0.0, Y.load('--- -.inf'))
    assert_equal(-1 / 0.0, Y.load('--- -.Inf'))
    assert_equal(-1 / 0.0, Y.load('--- -.INF'))
  end

  def test_nan
    assert_predicate Y.load('--- .nan'), :nan?
    assert_predicate Y.load('--- .NaN'), :nan?
    assert_predicate Y.load('--- .NAN'), :nan?
  end

  # Psych (via syck compat) parses "12,34,56" as 123456.
  # rapidyaml follows YAML 1.2 and returns it as a string.
  # DIFFERENCE: comma-separated integer notation is not supported.
  def test_string_with_commas_is_string
    result = Y.load('--- 12,34,56')

    assert_kind_of String, result
  end
end
