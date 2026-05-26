# frozen_string_literal: true

require_relative 'helper'

class TestPsychCompatStream < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_load_stream_two_documents
    docs = Y.load_stream("--- foo\n...\n--- bar\n")

    assert_equal %w[foo bar], docs
  end

  def test_load_stream_single_document
    docs = Y.load_stream("--- foo\n")

    assert_equal ['foo'], docs
  end

  def test_load_stream_yields_documents
    collected = []
    Y.load_stream("--- foo\n...\n--- bar\n") { |doc| collected << doc }

    assert_equal %w[foo bar], collected
  end

  def test_load_stream_returns_nil_with_block
    result = Y.load_stream("--- foo\n") { |_| }

    assert_nil result
  end

  def test_safe_load_stream_two_documents
    docs = Y.safe_load_stream("--- foo\n...\n--- bar\n")

    assert_equal %w[foo bar], docs
  end

  def test_load_stream_mixed_types
    docs = Y.load_stream("--- 1\n...\n--- two\n...\n--- true\n")

    assert_equal [1, 'two', true], docs
  end

  def test_load_stream_mapping_documents
    docs = Y.load_stream("---\na: 1\n...\n---\nb: 2\n")

    assert_equal [{ 'a' => 1 }, { 'b' => 2 }], docs
  end

  def test_load_stream_symbolize_names
    docs = Y.load_stream("---\na: 1\n", symbolize_names: true)

    assert_equal [{ a: 1 }], docs
  end
end
