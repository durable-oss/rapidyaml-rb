# frozen_string_literal: true

require 'mkmf-rice'

# rapidyaml is vendored as a single-header amalgamation at ext/rapidyaml/ryml_all.hpp
# No system library required.

$CXXFLAGS += ' -std=c++17 -O2'

$LDFLAGS += ' -static-libstdc++ -static-libgcc'

create_makefile('rapidyaml/rapidyaml')

# Copyright (c) 2026 Durable Programming, LLC. All rights reserved.