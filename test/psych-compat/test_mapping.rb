# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_hash.rb
# and inspirations/psych/test/psych/test_yaml.rb (test_basic_map)
class TestPsychCompatMapping < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_basic_map
    assert_parse_only(
      { 'one' => 'foo', 'two' => 'bar', 'three' => 'baz' },
      "one: foo\ntwo: bar\nthree: baz\n"
    )
  end

  def test_empty_hash
    assert_equal({}, Y.load("--- {}\n"))
  end

  def test_nested_hash
    assert_equal({ 'outer' => { 'inner' => 'value' } },
                 Y.load("outer:\n  inner: value\n"))
  end

  def test_hash_with_integer_keys
    assert_equal({ 1 => 'a', 2 => 'b' }, Y.load("1: a\n2: b\n"))
  end

  def test_hash_roundtrip
    obj = { 'a' => 1, 'b' => [1, 2], 'c' => { 'd' => true } }

    assert_cycle obj
  end

  def test_merge_keys
    # <<: merge key is a YAML 1.1 extension; rapidyaml supports it
    hash = Y.load(<<~YAML)
      foo: &foo
        hello: world
      bar:
        <<: *foo
    YAML
    assert_equal({ 'foo' => { 'hello' => 'world' }, 'bar' => { 'hello' => 'world' } }, hash)
  end

  def test_anchor_reuse_produces_equal_values
    hash = Y.load(<<~YAML)
      foo: &foo
        hello: world
      bar: *foo
    YAML
    assert_equal({ 'foo' => { 'hello' => 'world' }, 'bar' => { 'hello' => 'world' } }, hash)
    # NOTE: Psych assert_same on alias targets (same object identity).
    # rapidyaml produces equal but not necessarily identical objects.
    # DIFFERENCE: alias targets are not guaranteed to be the same Ruby object.
  end
end
