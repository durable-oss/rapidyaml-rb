# frozen_string_literal: true

VENDOR_SUITE = 'vendor/yaml-test-suite'

namespace :validation do
  desc "Clone yaml-test-suite into #{VENDOR_SUITE} (no-op if already present)"
  task :setup do
    sh "git clone --depth 1 https://github.com/yaml/yaml-test-suite #{VENDOR_SUITE}" unless Dir.exist?(VENDOR_SUITE)
  end

  desc "Run yaml-test-suite validation tests (requires #{VENDOR_SUITE})"
  task run: :setup do
    ruby '-Ilib validation/test_yaml_test_suite.rb'
  end
end

desc 'Run yaml-test-suite validation tests'
task validation: 'validation:run'
