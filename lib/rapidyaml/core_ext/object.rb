# Object#to_yaml monkey patch for rapidyaml
#
# This file extends all Ruby objects with a to_yaml method that uses RapidYAML
# instead of the standard library's Psych implementation. When loaded via
# require "rapidyaml/core_ext", existing code calling obj.to_yaml will
# automatically benefit from rapidyaml's performance without modification.
#
# This modifies global behavior by overriding the standard to_yaml method.
# Use with caution in environments where Psych-specific serialization behavior
# is expected or where other libraries depend on the original implementation.

require 'rapidyaml'

class Object
  def to_yaml
    RapidYAML.dump(self)
  end
end

# Copyright (c) 2026 Durable Programming, LLC. All rights reserved.