# RapidYAML - Fast YAML parsing and serialization for Ruby
#
# This file provides the main Ruby interface for the rapidyaml gem, which wraps
# the C++ rapidyaml library for high-performance YAML processing. It implements a
# drop-in replacement API compatible with Psych, including load/dump methods with
# support for symbolized keys, permitted classes for scalar coercion, and file I/O.
#
# The module delegates core parsing and serialization to C extension methods while
# providing Ruby-side features like scalar coercion (Symbol, Date, Time), key
# symbolization, and stream processing. All "unsafe" methods are aliased to their
# safe equivalents since rapidyaml never executes arbitrary Ruby code.
#
# Key features:
# - Psych-compatible API (load, dump, safe_load, etc.)
# - Scalar type coercion with permitted_classes
# - Multi-document YAML stream support
# - File I/O convenience methods
# - No AST/visitor pattern support (direct object conversion only)

require 'psych'
require 'set'
require_relative 'rapidyaml/version'

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "rapidyaml/#{Regexp.last_match(1)}/rapidyaml"
rescue LoadError
  require 'rapidyaml/rapidyaml'
end

module RapidYAML
  # Error and SyntaxError are defined in the C extension (Init_rapidyaml).
  # ParseError is kept as an alias for backward compatibility.
  ParseError = SyntaxError

  # Regex patterns for scalar coercion during load.
  # Only applied when the corresponding class is in permitted_classes.
  DATE_RE     = /\A(\d{4})-(\d{2})-(\d{2})\z/
  DATETIME_RE = /\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?: ?(?:Z|[+-]\d{2}:?\d{2}))?\z/

  module_function

  # Parses a YAML string and returns the corresponding Ruby object.
  #
  # @param yaml [String] YAML-formatted string
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  #   (supports Symbol, Date, Time)
  # @return [Object] parsed Ruby object
  # @raise [RapidYAML::SyntaxError] if the YAML is invalid
  def load(yaml, symbolize_names: false, permitted_classes: [])
    result = Ext.parse(yaml)
    result = coerce_scalars(result, permitted_classes) unless permitted_classes.empty?
    symbolize_names ? deep_symbolize_keys(result) : result
  end

  # Alias matching Psych.safe_load; rapidyaml does not execute arbitrary code,
  # so this is equivalent to load for all practical purposes.
  #
  # @param yaml [String] YAML-formatted string
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  # @return [Object] parsed Ruby object
  # @raise [RapidYAML::SyntaxError] if the YAML is invalid
  def safe_load(yaml, symbolize_names: false, permitted_classes: [])
    load(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
  end

  # Serializes a Ruby object to a YAML string.
  #
  # @param obj [Object] Ruby object to serialize
  # @return [String] YAML representation
  # @raise [RapidYAML::Error] if the object cannot be serialized
  def dump(obj)
    Ext.emit(obj)
  end

  # Serializes multiple Ruby objects into a multi-document YAML stream.
  #
  # @param objects [Array<Object>] Ruby objects to serialize
  # @return [String] YAML stream with one document per object
  # @raise [RapidYAML::Error] if any object cannot be serialized
  def dump_stream(*objects)
    objects.map do |obj|
      s = dump(obj)
      obj.is_a?(Hash) || obj.is_a?(Array) ? "---\n#{s}" : "--- #{s}"
    end.join
  end

  # Equivalent to dump; rapidyaml does not serialize arbitrary Ruby objects,
  # so there is no unsafe surface to restrict.
  #
  # @param obj [Object] Ruby object to serialize
  # @return [String] YAML representation
  def safe_dump(obj)
    dump(obj)
  end

  # Returns the version string of the bundled rapidyaml C++ library.
  # Psych exposes libyaml_version; this is the equivalent for rapidyaml.
  #
  # @return [String] rapidyaml version, e.g. "0.13.0"
  def libyaml_version
    Ext.ryml_version
  end

  # Parses all YAML documents in a string and yields each as a Ruby object.
  # If no block given, returns an array of all documents.
  #
  # @param yaml [String] YAML-formatted string (may contain multiple documents)
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  # @yield [Object] each parsed document
  # @return [Array, nil] array of documents if no block given
  def load_stream(yaml, symbolize_names: false, permitted_classes: [], &block)
    docs = Ext.parse_stream(yaml)
    docs = docs.map { |d| coerce_scalars(d, permitted_classes) } unless permitted_classes.empty?
    docs = docs.map { |d| deep_symbolize_keys(d) } if symbolize_names
    if block
      docs.each(&block)
      nil
    else
      docs
    end
  end

  # @see load_stream
  def safe_load_stream(yaml, symbolize_names: false, permitted_classes: [], &block)
    load_stream(yaml, symbolize_names: symbolize_names,
                      permitted_classes: permitted_classes, &block)
  end

  # Alias matching Psych.unsafe_load; rapidyaml never executes arbitrary Ruby
  # object tags, so this is equivalent to load.
  #
  # @param yaml [String] YAML-formatted string
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  # @return [Object] parsed Ruby object
  def unsafe_load(yaml, symbolize_names: false, permitted_classes: [])
    load(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
  end

  # Alias matching Psych.unsafe_load_file; rapidyaml never executes arbitrary
  # Ruby object tags, so this is equivalent to load_file.
  #
  # @param path [String] path to the YAML file
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  # @return [Object] parsed Ruby object
  def unsafe_load_file(path, symbolize_names: false, permitted_classes: [])
    load_file(path, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
  end

  # Parses YAML from a file and returns the corresponding Ruby object.
  #
  # @param path [String] path to the YAML file
  # @param symbolize_names [Boolean] if true, hash keys are returned as symbols
  # @param permitted_classes [Array<Class>] classes allowed for type coercion
  # @return [Object] parsed Ruby object
  # @raise [RapidYAML::SyntaxError] if the YAML is invalid
  # @raise [Errno::ENOENT] if the file does not exist
  def load_file(path, symbolize_names: false, permitted_classes: [])
    load(File.read(path), symbolize_names: symbolize_names,
                          permitted_classes: permitted_classes)
  end

  # Serializes a Ruby object to a YAML file.
  #
  # @param obj [Object] Ruby object to serialize
  # @param path [String] destination file path
  # @return [void]
  # @raise [RapidYAML::Error] if the object cannot be serialized
  def dump_file(obj, path)
    File.write(path, dump(obj))
  end

  # @api private
  def coerce_scalars(obj, permitted_classes)
    set = permitted_classes.to_set
    permit_symbol = set.include?(Symbol)
    permit_date   = set.include?(Date)
    permit_time   = set.include?(Time)
    coerce_scalars_inner(obj, permit_symbol, permit_date, permit_time)
  end
  private_class_method :coerce_scalars

  # @api private
  def coerce_scalars_inner(obj, permit_symbol, permit_date, permit_time)
    case obj
    when Hash
      obj.transform_keys { |k| coerce_scalars_inner(k, permit_symbol, permit_date, permit_time) }
         .transform_values { |v| coerce_scalars_inner(v, permit_symbol, permit_date, permit_time) }
    when Array
      obj.map { |v| coerce_scalars_inner(v, permit_symbol, permit_date, permit_time) }
    when String
      coerce_string(obj, permit_symbol, permit_date, permit_time)
    else
      obj
    end
  end
  private_class_method :coerce_scalars_inner

  # @api private
  def coerce_string(str, permit_symbol, permit_date, permit_time)
    if permit_symbol && str.start_with?(':')
      name = str[1..]
      return name.empty? ? :"" : name.to_sym
    end
    if permit_time && str =~ DATETIME_RE && str.include?(':')
      begin
        require 'time'
        t = Time.parse(str)
        return t
      rescue ArgumentError
        # fall through
      end
    end
    if permit_date && str =~ DATE_RE
      begin
        require 'date'
        return Date.new(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i)
      rescue ArgumentError
        # fall through
      end
    end
    str
  end
  private_class_method :coerce_string

  # @api private
  def deep_symbolize_keys(obj)
    case obj
    when Hash
      obj.transform_keys(&:to_sym).transform_values { |v| deep_symbolize_keys(v) }
    when Array
      obj.map { |v| deep_symbolize_keys(v) }
    else
      obj
    end
  end
  private_class_method :deep_symbolize_keys
end

# Copyright (c) 2026 Durable Programming, LLC. All rights reserved.
