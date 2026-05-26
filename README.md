# rapidyaml

Fast YAML parsing for Ruby via [rapidyaml](https://github.com/biojppm/rapidyaml) — a C++ YAML library. Drop-in replacement for Psych.

## Installation

```ruby
gem "rapidyaml"
```

Building from source requires a C++17 compiler. No extra system libraries needed — rapidyaml is vendored.

## Usage

The API is compatible with Psych:

```ruby
require "rapidyaml"

# Parse YAML
data = RapidYAML.load("key: value\nlist:\n  - 1\n  - 2\n")
# => {"key" => "value", "list" => [1, 2]}

# Symbolized keys
data = RapidYAML.load("key: value\n", symbolize_names: true)
# => {key: "value"}

# safe_load is equivalent (rapidyaml never executes arbitrary code)
data = RapidYAML.safe_load(yaml_string)

# Serialize
yaml = RapidYAML.dump({ name: "Alice", age: 30 })

# File I/O
data = RapidYAML.load_file("config.yaml")
RapidYAML.dump_file(data, "output.yaml")
```

## Psych compatibility

| Psych method | RapidYAML equivalent |
|---|---|
| `Psych.load` | `RapidYAML.load` |
| `Psych.safe_load` | `RapidYAML.safe_load` |
| `Psych.unsafe_load` | `RapidYAML.unsafe_load` |
| `Psych.dump` | `RapidYAML.dump` |
| `Psych.safe_dump` | `RapidYAML.safe_dump` |
| `Psych.dump_stream` | `RapidYAML.dump_stream` |
| `Psych.load_file` | `RapidYAML.load_file` |
| `Psych.unsafe_load_file` | `RapidYAML.unsafe_load_file` |
| `Psych.dump_file` | `RapidYAML.dump_file` |
| `Psych.load_stream` | `RapidYAML.load_stream` |
| `Psych.safe_load_stream` | `RapidYAML.safe_load_stream` |
| `Psych.libyaml_version` | `RapidYAML.libyaml_version` (returns rapidyaml version) |

Scalar coercion matches Psych defaults: `true`/`false` → Boolean, integers, floats, `~`/`null` → nil.

`unsafe_load` and `unsafe_load_file` are provided for drop-in compatibility. Because rapidyaml never executes arbitrary Ruby object tags, they behave identically to `load` and `load_file` — there is no unsafe code path.

### Side-by-side with Psych

rapidyaml and Psych can be loaded simultaneously. They occupy different namespaces (`RapidYAML` vs `Psych`) and do not interfere with each other. You can use rapidyaml for hot paths where parse speed matters and fall back to Psych where you need AST access or custom tag handling:

```ruby
require "rapidyaml"
require "psych"

# Fast path
config = RapidYAML.load(File.read("large_config.yaml"))

# AST manipulation still goes through Psych
tree = Psych.parse(some_yaml)
```

### Not supported: Psych AST methods

Psych exposes a visitor-based AST through `Psych.parse`, `Psych.parse_file`, `Psych.parse_stream`, and `Psych.parser`. These return `Psych::Nodes::Document` trees and support streaming visitors via `Psych::Handler`.

rapidyaml has no equivalent. The library resolves the ryml parse tree directly to Ruby objects and does not expose an intermediate AST. If your code depends on `Psych::Nodes`, `Psych::TreeBuilder`, `Psych::Visitors`, or custom `Psych::Handler` subclasses, it is not compatible with this gem.

## Development

```bash
bundle install
bundle exec rake compile
bundle exec rake test
```

## License

MIT — see LICENSE.
