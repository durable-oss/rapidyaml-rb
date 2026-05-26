# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_psych.rb
# Tests for RapidYAML.load / RapidYAML.safe_load
class TestPsychCompatLoad < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_simple_scalar
    assert_equal 'foo', Y.load("--- foo\n")
  end

  def test_load_mapping
    assert_equal({ 'one' => 'foo', 'two' => 'bar', 'three' => 'baz' },
                 Y.load("one: foo\ntwo: bar\nthree: baz\n"))
  end

  def test_load_sequence
    assert_equal %w[a b c], Y.load("- a\n- b\n- c\n")
  end

  def test_load_nested
    assert_equal({ 'outer' => { 'inner' => 42 } },
                 Y.load("outer:\n  inner: 42\n"))
  end

  def test_load_integer
    assert_equal 42, Y.load('--- 42')
    assert_kind_of Integer, Y.load('--- 42')
  end

  def test_load_negative_integer
    assert_equal(-1, Y.load('--- -1'))
  end

  def test_load_float
    assert_in_delta 3.14, Y.load('--- 3.14'), 0.001
    assert_kind_of Float, Y.load('--- 3.14')
  end

  def test_load_boolean_true
    assert Y.load('--- true')
    assert Y.load('--- True')
    assert Y.load('--- TRUE')
  end

  def test_load_boolean_false
    refute Y.load('--- false')
    refute Y.load('--- False')
    refute Y.load('--- FALSE')
  end

  def test_load_null_tilde
    assert_nil Y.load('--- ~')
  end

  def test_load_null_keyword
    assert_nil Y.load('--- null')
  end

  def test_load_symbolize_names
    result = Y.load("key: value\n", symbolize_names: true)

    assert_equal({ key: 'value' }, result)
  end

  def test_load_nested_symbolize_names
    result = Y.load("outer:\n  inner: 1\n", symbolize_names: true)

    assert_equal({ outer: { inner: 1 } }, result)
  end

  def test_symbolize_names_mixed
    yaml = "foo:\n  bar: baz\nhoge:\n  - fuga: piyo\n"

    assert_equal({ foo: { bar: 'baz' }, hoge: [{ fuga: 'piyo' }] },
                 Y.load(yaml, symbolize_names: true))
  end

  def test_safe_load_basic
    assert_equal %w[a b], Y.safe_load("- a\n- b")
  end

  def test_safe_load_equivalent_to_load
    yaml = "hello: world\n"

    assert_equal Y.load(yaml), Y.safe_load(yaml)
  end

  def test_safe_load_symbolize_names
    yaml = "foo:\n  bar: baz\nhoge:\n  - fuga: piyo\n"

    assert_equal({ foo: { bar: 'baz' }, hoge: [{ fuga: 'piyo' }] },
                 Y.safe_load(yaml, symbolize_names: true))
  end

  def test_load_raises_on_invalid_yaml
    assert_raises(RapidYAML::SyntaxError) { Y.load('{unclosed: [') }
  end

  def test_safe_load_raises_on_invalid_yaml
    assert_raises(RapidYAML::SyntaxError) { Y.safe_load('{unclosed: [') }
  end

  # YAML 1.1 extended booleans (yes/no/on/off) are NOT supported.
  # rapidyaml follows YAML 1.2 where only true/false are booleans.
  # These scalars are returned as strings.
  def test_yaml_11_booleans_are_strings
    %w[yes Yes YES no No NO on On ON off Off OFF].each do |word|
      result = Y.load("--- #{word}")

      assert_kind_of String, result,
                     "expected '#{word}' to be a String (YAML 1.2), got #{result.inspect}"
    end
  end

  # y/Y/n/N are strings in both YAML 1.1 (syck compat) and YAML 1.2.
  def test_y_and_n_are_strings
    assert_kind_of String, Y.load('--- y')
    assert_kind_of String, Y.load('--- Y')
    assert_kind_of String, Y.load('--- n')
    assert_kind_of String, Y.load('--- N')
  end
end
