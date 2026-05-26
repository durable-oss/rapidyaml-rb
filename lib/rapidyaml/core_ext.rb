# Core extension loader for rapidyaml
#
# This file provides optional monkey-patching for Ruby's standard YAML interface
# and Object#to_yaml method. When loaded, it replaces YAML module methods and
# adds to_yaml to all objects, directing them to use RapidYAML instead of Psych.
#
# This allows existing code using YAML.load/dump or obj.to_yaml to transparently
# benefit from rapidyaml's performance without code changes. Load explicitly with:
# require "rapidyaml/core_ext"
#
# Note: This modifies global behavior. Use with caution in libraries or when
# Psych-specific features (AST access, custom handlers) are needed elsewhere.

require_relative 'core_ext/object'
require_relative 'core_ext/yaml'

# Copyright (c) 2026 Durable Programming, LLC. All rights reserved.