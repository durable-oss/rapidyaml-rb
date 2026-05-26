# frozen_string_literal: true

require_relative 'helper'
require 'date'
require 'time'

# Tests for permitted_classes: option on load / safe_load.
# rapidyaml never deserializes arbitrary objects, so permitted_classes
# only controls whether Symbol, Date, and Time coercions are applied.
class TestPsychCompatPermittedClasses < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_symbol_not_coerced_by_default
    assert_equal ':foo', Y.load('--- :foo')
    assert_equal ':foo', Y.safe_load('--- :foo')
  end

  def test_symbol_coerced_with_permitted_classes
    assert_equal :foo, Y.load('--- :foo', permitted_classes: [Symbol])
    assert_equal :foo, Y.safe_load('--- :foo', permitted_classes: [Symbol])
  end

  def test_date_not_coerced_by_default
    assert_kind_of String, Y.load('--- 2024-01-15')
  end

  def test_date_coerced_with_permitted_classes
    assert_kind_of Date, Y.load('--- 2024-01-15', permitted_classes: [Date])
  end

  def test_time_not_coerced_by_default
    assert_kind_of String, Y.load('--- 2024-01-15 12:00:00.0 Z')
  end

  def test_time_coerced_with_permitted_classes
    assert_kind_of Time, Y.load('--- 2024-01-15 12:00:00.0 Z', permitted_classes: [Time])
  end

  def test_multiple_permitted_classes
    yaml = Y.dump({ 'sym' => :foo, 'date' => Date.new(2024, 1, 15) })
    result = Y.load(yaml, permitted_classes: [Symbol, Date])

    assert_equal :foo, result['sym']
    assert_equal Date.new(2024, 1, 15), result['date']
  end

  def test_permitted_classes_as_strings
    assert_equal :foo, Y.load('--- :foo', permitted_classes: ['Symbol'])
  end

  def test_permitted_classes_nested
    yaml = "items:\n  - :a\n  - :b\n"
    result = Y.load(yaml, permitted_classes: [Symbol])

    assert_equal %i[a b], result['items']
  end
end
