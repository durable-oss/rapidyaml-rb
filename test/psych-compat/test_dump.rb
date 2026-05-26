# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_psych.rb
# Tests for RapidYAML.dump
class TestPsychCompatDump < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_dump_produces_string
    assert_kind_of String, Y.dump('hello')
  end

  def test_dump_scalar_roundtrip
    assert_equal 'hello', Y.load(Y.dump('hello'))
  end

  def test_dump_integer_roundtrip
    assert_equal 42, Y.load(Y.dump(42))
  end

  def test_dump_float_roundtrip
    assert_in_delta 3.14, Y.load(Y.dump(3.14)), 0.001
  end

  def test_dump_boolean_true_roundtrip
    assert Y.load(Y.dump(true))
  end

  def test_dump_boolean_false_roundtrip
    refute Y.load(Y.dump(false))
  end

  def test_dump_nil_roundtrip
    assert_nil Y.load(Y.dump(nil))
  end

  def test_dump_array_roundtrip
    obj = %w[a b c]

    assert_equal obj, Y.load(Y.dump(obj))
  end

  def test_dump_hash_roundtrip
    obj = { 'name' => 'Alice', 'age' => 30 }

    assert_equal obj, Y.load(Y.dump(obj))
  end

  def test_dump_nested_roundtrip
    obj = { 'outer' => { 'inner' => [1, 2, 3] } }

    assert_equal obj, Y.load(Y.dump(obj))
  end

  def test_dump_array_of_hashes_roundtrip
    obj = [{ 'a' => 1 }, { 'b' => 2 }]

    assert_equal obj, Y.load(Y.dump(obj))
  end

  # Psych.dump with an IO argument returns the IO and writes to it.
  # RapidYAML.dump always returns a String; it does not accept an IO.
  # This difference is documented — use dump_file for file output.
  def test_dump_returns_string_not_io
    result = Y.dump({ 'hello' => 'world' })

    assert_kind_of String, result
  end
end
