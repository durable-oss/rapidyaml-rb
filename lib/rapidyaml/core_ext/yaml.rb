# YAML module monkey patch for rapidyaml
#
# This file overrides the standard YAML module methods to delegate to RapidYAML
# instead of Psych. When loaded via require "rapidyaml/core_ext", existing
# code using YAML.load, YAML.dump, and related methods will automatically use
# rapidyaml for improved performance without requiring code changes.
#
# The monkey patch preserves the original YAML API signatures while redirecting
# calls to the corresponding RapidYAML methods. Extra keyword arguments are
# ignored to maintain compatibility with Psych's extended parameter lists.
#
# This modifies global behavior by replacing Ruby's standard YAML implementation.
# Use with caution in environments where Psych-specific features or behaviors
# are required by other parts of the application or loaded libraries.

require 'yaml'
require 'rapidyaml'

module YAML
  class << self
    def load(yaml, symbolize_names: false, permitted_classes: [], **_)
      RapidYAML.load(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
    end

    def safe_load(yaml, symbolize_names: false, permitted_classes: [], **_)
      RapidYAML.safe_load(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
    end

    def unsafe_load(yaml, symbolize_names: false, permitted_classes: [], **_)
      RapidYAML.unsafe_load(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
    end

    def dump(obj, **)
      RapidYAML.dump(obj)
    end

    def safe_dump(obj, **)
      RapidYAML.safe_dump(obj)
    end

    def dump_stream(*objects)
      RapidYAML.dump_stream(*objects)
    end

    def load_stream(yaml, symbolize_names: false, permitted_classes: [], **_, &block)
      RapidYAML.load_stream(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes, &block)
    end

    def safe_load_stream(yaml, symbolize_names: false, permitted_classes: [], **_, &block)
      RapidYAML.safe_load_stream(yaml, symbolize_names: symbolize_names, permitted_classes: permitted_classes, &block)
    end

    def load_file(path, symbolize_names: false, permitted_classes: [], **_)
      RapidYAML.load_file(path, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
    end

    def unsafe_load_file(path, symbolize_names: false, permitted_classes: [], **_)
      RapidYAML.unsafe_load_file(path, symbolize_names: symbolize_names, permitted_classes: permitted_classes)
    end
  end
end

# Copyright (c) 2026 Durable Programming, LLC. All rights reserved.