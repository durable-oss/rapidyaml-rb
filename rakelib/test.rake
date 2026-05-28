# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

# Run tests inside the cross-compile container (catches ABI/linking issues early)
namespace :test do
  CROSS_PLATFORMS.each do |platform|
    desc "Build and test inside #{platform} container"
    task platform do
      RakeCompilerDock.sh(
        <<~SH,
          gem install bundler --no-document &&
          bundle install &&
          bundle exec rake compile test
        SH
        platform: platform,
        verbose: true,
        options: ['-e', "RUBY_CC_VERSION=#{RakeCompilerDock.ruby_cc_version(*CROSS_RUBIES)}"]
      )
    end
  end

  desc 'Test inside all platform containers'
  multitask cross: CROSS_PLATFORMS.map { |p| "test:#{p}" }
end
