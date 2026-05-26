# frozen_string_literal: true

require 'minitest/autorun'
require 'rapidyaml'

class TestRapidYAML < Minitest::Test
  # ---- load ----------------------------------------------------------------

  def test_load_mapping
    result = RapidYAML.load("key: value\n")

    assert_equal({ 'key' => 'value' }, result)
  end

  def test_load_sequence
    result = RapidYAML.load("- a\n- b\n- c\n")

    assert_equal(%w[a b c], result)
  end

  def test_load_nested
    yaml = "outer:\n  inner: 42\n"
    result = RapidYAML.load(yaml)

    assert_equal({ 'outer' => { 'inner' => 42 } }, result)
  end

  def test_load_integer_coercion
    result = RapidYAML.load("number: 99\n")

    assert_equal(99, result['number'])
    assert_kind_of Integer, result['number']
  end

  def test_load_float_coercion
    result = RapidYAML.load("pi: 3.14\n")

    assert_in_delta 3.14, result['pi'], 0.001
    assert_kind_of Float, result['pi']
  end

  def test_load_boolean_true
    result = RapidYAML.load("flag: true\n")

    assert result['flag']
  end

  def test_load_boolean_false
    result = RapidYAML.load("flag: false\n")

    refute result['flag']
  end

  def test_load_null
    result = RapidYAML.load("val: ~\n")

    assert_nil result['val']
  end

  def test_load_symbolize_names
    result = RapidYAML.load("key: value\n", symbolize_names: true)

    assert_equal({ key: 'value' }, result)
  end

  def test_load_nested_symbolize_names
    yaml = "outer:\n  inner: 1\n"
    result = RapidYAML.load(yaml, symbolize_names: true)

    assert_equal({ outer: { inner: 1 } }, result)
  end

  # ---- safe_load -----------------------------------------------------------

  def test_safe_load_is_equivalent_to_load
    yaml = "hello: world\n"

    assert_equal RapidYAML.load(yaml), RapidYAML.safe_load(yaml)
  end

  # ---- dump ----------------------------------------------------------------

  def test_dump_produces_parseable_output
    obj = { 'name' => 'Alice', 'age' => 30 }
    yaml = RapidYAML.dump(obj)

    assert_kind_of String, yaml
    roundtrip = RapidYAML.load(yaml)

    assert_equal obj, roundtrip
  end

  # ---- load_file / dump_file -----------------------------------------------

  def test_load_file_and_dump_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'test.yaml')
      obj = { 'x' => 1, 'y' => 2 }
      RapidYAML.dump_file(obj, path)
      result = RapidYAML.load_file(path)

      assert_equal obj, result
    end
  end

  def test_load_file_missing_raises
    assert_raises(Errno::ENOENT) { RapidYAML.load_file('/nonexistent/path.yaml') }
  end

  # ---- sexagesimal (YAML 1.1 regression guard) -----------------------------

  def test_sexagesimal_not_coerced_to_integer
    result = RapidYAML.load("time: 20:03:20\n")

    assert_equal '20:03:20', result['time']
    assert_kind_of String, result['time']
  end

  # ---- hash keys that are not strings/symbols ------------------------------

  def test_dump_hash_with_integer_keys
    yaml = RapidYAML.dump({ 1 => 'a', 2 => 'b' })

    assert_kind_of String, yaml
    result = RapidYAML.load(yaml)
    assert_equal 'a', result['1']
  end

  # ---- empty stream --------------------------------------------------------

  def test_load_stream_empty_returns_empty_array
    assert_equal [], RapidYAML.load_stream('')
  end

  def test_load_stream_comment_only_returns_empty_array
    assert_equal [], RapidYAML.load_stream("# just a comment\n")
  end

  # ---- load_stream multiple docs -------------------------------------------

  def test_load_stream_multiple_documents
    yaml = "---\nfoo: 1\n---\nbar: 2\n"
    docs = RapidYAML.load_stream(yaml)

    assert_equal 2, docs.length
    assert_equal({ 'foo' => 1 }, docs[0])
    assert_equal({ 'bar' => 2 }, docs[1])
  end

  # ---- dump_stream ---------------------------------------------------------

  def test_dump_stream_roundtrips
    objects = [{ 'a' => 1 }, [1, 2, 3], 'scalar']
    yaml = RapidYAML.dump_stream(*objects)
    docs = RapidYAML.load_stream(yaml)

    assert_equal objects, docs
  end
end
