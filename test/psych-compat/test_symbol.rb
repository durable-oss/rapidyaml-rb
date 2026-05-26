# frozen_string_literal: true

require_relative 'helper'

class TestPsychCompatSymbol < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_load_simple_symbol
    assert_equal :foo, Y.load('--- :foo', permitted_classes: [Symbol])
  end

  def test_load_symbol_with_digits
    assert_equal :'123', Y.load('--- :123', permitted_classes: [Symbol])
  end

  def test_load_symbol_with_spaces
    assert_equal :'hello world', Y.load('--- :hello world', permitted_classes: [Symbol])
  end

  def test_load_empty_symbol
    assert_equal :"", Y.load("--- ':'", permitted_classes: [Symbol])
  end

  def test_dump_simple_symbol
    assert_equal :foo, Y.load(Y.dump(:foo), permitted_classes: [Symbol])
  end

  def test_dump_symbol_with_digits
    assert_equal :'123', Y.load(Y.dump(:'123'), permitted_classes: [Symbol])
  end

  def test_cycle_symbol
    assert_equal :a, Y.load(Y.dump(:a), permitted_classes: [Symbol])
  end

  def test_symbol_in_hash_value
    result = Y.load(Y.dump({ 'key' => :value }), permitted_classes: [Symbol])

    assert_equal({ 'key' => :value }, result)
  end

  def test_symbol_in_array
    result = Y.load(Y.dump(%i[a b]), permitted_classes: [Symbol])

    assert_equal %i[a b], result
  end

  def test_without_permitted_classes_symbol_is_string
    result = Y.load('--- :foo')

    assert_equal ':foo', result
    assert_kind_of String, result
  end
end
