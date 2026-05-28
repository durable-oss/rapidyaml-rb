# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake_compiler_dock'
require 'yaml'

native_config = YAML.load_file('misc/native.yml')
CROSS_RUBIES = native_config['rubies'].freeze
CROSS_PLATFORMS = native_config['platforms'].freeze

# Only set RUBY_CC_VERSION on the host launching dock tasks.
# Inside the container it's already set; setting it on the host without
# cross-toolchain headers causes a bad compile.
RakeCompilerDock.set_ruby_cc_version(*CROSS_RUBIES) unless ENV['RUBY_CC_VERSION']

Rake::ExtensionTask.new('rapidyaml', GEMSPEC) do |ext|
  ext.source_pattern = '*.{c,cc,cpp,h}'
  ext.lib_dir = 'lib/rapidyaml'

  if ENV['RUBY_CC_VERSION']
    ext.cross_compile = true
    ext.cross_platform = CROSS_PLATFORMS
    ext.cross_config_options << '--enable-cross-compilation'
  end
end
