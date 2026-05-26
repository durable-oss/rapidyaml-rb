# frozen_string_literal: true

require 'minitest/autorun'
require 'rapidyaml/core_ext'

class TestCoreExtObject < Minitest::Test
  def test_to_yaml_string
    assert_equal "hello\n", 'hello'.to_yaml
  end

  def test_to_yaml_integer
    assert_equal "42\n", 42.to_yaml
  end

  def test_to_yaml_array
    result = RapidYAML.load([1, 2, 3].to_yaml)

    assert_equal [1, 2, 3], result
  end

  def test_to_yaml_hash
    result = RapidYAML.load({ 'a' => 1 }.to_yaml)

    assert_equal({ 'a' => 1 }, result)
  end

  def test_to_yaml_nil
    result = RapidYAML.load(nil.to_yaml)

    assert_nil result
  end

  def test_to_yaml_roundtrip
    obj = { 'name' => 'Alice', 'scores' => [10, 20, 30] }

    assert_equal obj, RapidYAML.load(obj.to_yaml)
  end
end

class TestCoreExtYAML < Minitest::Test
  # ---- load ----------------------------------------------------------------

  def test_load_scalar
    assert_equal 'hello', YAML.load("hello\n")
  end

  def test_load_mapping
    assert_equal({ 'a' => 1 }, YAML.load("a: 1\n"))
  end

  def test_load_symbolize_names
    assert_equal({ a: 1 }, YAML.load("a: 1\n", symbolize_names: true))
  end

  def test_safe_load_mapping
    assert_equal({ 'a' => 1 }, YAML.safe_load("a: 1\n"))
  end

  def test_unsafe_load_mapping
    assert_equal({ 'a' => 1 }, YAML.unsafe_load("a: 1\n"))
  end

  # ---- dump ----------------------------------------------------------------

  def test_dump_roundtrip
    obj = { 'x' => 42 }

    assert_equal obj, YAML.load(YAML.dump(obj))
  end

  def test_safe_dump_roundtrip
    obj = { 'x' => 42 }

    assert_equal obj, YAML.load(YAML.safe_dump(obj))
  end

  def test_dump_stream
    yaml = YAML.dump_stream('foo', 'bar')
    docs = RapidYAML.load_stream(yaml)

    assert_equal %w[foo bar], docs
  end

  # ---- load_stream ---------------------------------------------------------

  def test_load_stream_array
    docs = YAML.load_stream("--- foo\n...\n--- bar\n")

    assert_equal %w[foo bar], docs
  end

  def test_load_stream_block
    collected = []
    result = YAML.load_stream("--- foo\n...\n--- bar\n") { |d| collected << d }

    assert_equal %w[foo bar], collected
    assert_nil result
  end

  def test_safe_load_stream_array
    docs = YAML.safe_load_stream("--- 1\n...\n--- two\n")

    assert_equal [1, 'two'], docs
  end

  # ---- load_file -----------------------------------------------------------

  def test_load_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'test.yaml')
      File.write(path, "key: value\n")

      assert_equal({ 'key' => 'value' }, YAML.load_file(path))
    end
  end

  def test_unsafe_load_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'test.yaml')
      File.write(path, "key: value\n")

      assert_equal({ 'key' => 'value' }, YAML.unsafe_load_file(path))
    end
  end

  # ---- unknown kwargs are absorbed -----------------------------------------

  def test_load_ignores_unknown_kwargs
    assert_equal 'hello', YAML.load("hello\n", freeze: true)
  end
end
