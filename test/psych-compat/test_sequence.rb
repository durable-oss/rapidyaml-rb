# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_array.rb
# and inspirations/psych/test/psych/test_yaml.rb (spec sequence examples)
class TestPsychCompatSequence < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_empty_sequence
    assert_equal [], Y.load("--- []\n")
  end

  def test_basic_sequence
    assert_equal %w[a b c], Y.load("- a\n- b\n- c\n")
  end

  def test_sequence_of_integers
    assert_equal [1, 2, 3], Y.load("- 1\n- 2\n- 3\n")
  end

  def test_nested_sequence
    assert_equal [[1, 2], [3, 4]], Y.load("- - 1\n  - 2\n- - 3\n  - 4\n")
  end

  def test_sequence_of_mappings
    assert_equal [{ 'a' => 1 }, { 'b' => 2 }],
                 Y.load("- a: 1\n- b: 2\n")
  end

  def test_spec_simple_implicit_sequence
    assert_to_yaml(
      ['Mark McGwire', 'Sammy Sosa', 'Ken Griffey'],
      "- Mark McGwire\n- Sammy Sosa\n- Ken Griffey\n"
    )
  end

  def test_cycle_array
    # Symbol keys are stringified on dump (rapidyaml has no tag for :symbols).
    # Round-trip equality holds when the original uses string keys.
    assert_cycle [{ 'a' => 'b' }, 'foo']
  end

  def test_cycle_nested
    assert_cycle [1, [2, [3, [4]]]]
  end
end
