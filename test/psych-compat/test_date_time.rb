# frozen_string_literal: true

require_relative 'helper'
require 'date'
require 'time'

class TestPsychCompatDateTime < PsychCompat::TestCase
  Y = PsychCompat::Y

  # --- Date ---

  def test_load_date
    d = Y.load('--- 2024-01-15', permitted_classes: [Date])

    assert_equal Date.new(2024, 1, 15), d
    assert_kind_of Date, d
  end

  def test_dump_date
    d = Date.new(2024, 1, 15)

    assert_match(/2024-01-15/, Y.dump(d))
  end

  def test_cycle_date
    d = Date.new(2024, 6, 30)

    assert_equal d, Y.load(Y.dump(d), permitted_classes: [Date])
  end

  def test_date_without_permitted_classes_is_string
    result = Y.load('--- 2024-01-15')

    assert_kind_of String, result
  end

  # --- Time ---

  def test_load_time_utc
    t = Y.load('--- 2024-01-15 12:00:00.000000000 Z', permitted_classes: [Time])

    assert_kind_of Time, t
    assert_equal 2024, t.year
    assert_equal 1, t.month
    assert_equal 15, t.day
    assert_equal 12, t.hour
    assert_predicate t, :utc?
  end

  def test_load_time_with_offset
    t = Y.load('--- 2024-01-15 12:00:00.000000000 +09:00', permitted_classes: [Time])

    assert_kind_of Time, t
    assert_equal 12, t.hour
    assert_equal 9 * 3600, t.utc_offset
  end

  def test_dump_time_utc
    t = Time.utc(2024, 1, 15, 12, 0, 0)
    yaml = Y.dump(t)

    assert_match(/2024-01-15 12:00:00/, yaml)
    assert_match(/Z/, yaml)
  end

  def test_dump_time_with_offset
    t = Time.new(2024, 1, 15, 12, 0, 0, '+09:00')
    yaml = Y.dump(t)

    assert_match(/2024-01-15 12:00:00/, yaml)
    assert_match(/\+09:00/, yaml)
  end

  def test_cycle_time_utc
    t = Time.utc(2024, 6, 30, 8, 30, 0)
    result = Y.load(Y.dump(t), permitted_classes: [Time])

    assert_kind_of Time, result
    assert_equal t.to_i, result.to_i
  end

  def test_cycle_time_with_offset
    t = Time.new(2024, 6, 30, 8, 30, 0, '+05:30')
    result = Y.load(Y.dump(t), permitted_classes: [Time])

    assert_kind_of Time, result
    assert_equal t.to_i, result.to_i
  end

  def test_time_without_permitted_classes_is_string
    result = Y.load('--- 2024-01-15 12:00:00.000000000 Z')

    assert_kind_of String, result
  end
end
