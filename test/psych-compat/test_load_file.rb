# frozen_string_literal: true

require_relative 'helper'

# Adapted from inspirations/psych/test/psych/test_psych.rb
# Tests for RapidYAML.load_file / RapidYAML.dump_file
class TestPsychCompatLoadFile < PsychCompat::TestCase
  Y = PsychCompat::Y

  def test_load_file_scalar
    Tempfile.create(['psych_compat', '.yml']) do |f|
      f.binmode
      f.write('--- hello world')
      f.close

      assert_equal 'hello world', Y.load_file(f.path)
    end
  end

  def test_load_file_mapping
    Tempfile.create(['psych_compat', '.yml']) do |f|
      f.binmode
      f.write("foo: bar\n")
      f.close

      assert_equal({ 'foo' => 'bar' }, Y.load_file(f.path))
    end
  end

  def test_load_file_symbolize_names
    Tempfile.create(['psych_compat', '.yml']) do |f|
      f.binmode
      f.write("foo: bar\n")
      f.close

      assert_equal({ foo: 'bar' }, Y.load_file(f.path, symbolize_names: true))
    end
  end

  def test_load_file_missing_raises
    assert_raises(Errno::ENOENT) { Y.load_file('/nonexistent/path.yaml') }
  end

  def test_dump_file_roundtrip
    obj = { 'x' => 1, 'y' => [1, 2, 3] }
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'test.yml')
      Y.dump_file(obj, path)

      assert_equal obj, Y.load_file(path)
    end
  end

  def test_dump_file_creates_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'out.yml')

      refute_path_exists path
      Y.dump_file({ 'k' => 'v' }, path)

      assert_path_exists path
    end
  end
end
