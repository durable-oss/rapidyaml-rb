# frozen_string_literal: true

require 'rubygems/package_task'

Gem::PackageTask.new(GEMSPEC).define

namespace :gem do
  CROSS_PLATFORMS.each do |platform|
    desc "Build precompiled gem for #{platform}"
    task platform do
      RakeCompilerDock.sh(
        <<~SH,
          SRCDIR="$PWD" &&
          STAGEDIR=$(mktemp -d) &&
          cp -a "$SRCDIR/." "$STAGEDIR/" &&
          find "$STAGEDIR" -type f -name '*.so' -delete &&
          find "$STAGEDIR" -type f -name '*.bundle' -delete &&
          rm -rf "$STAGEDIR/tmp" "$STAGEDIR/.devenv" "$STAGEDIR/pkg" &&
          cd "$STAGEDIR" &&
          gem install bundler --no-document &&
          bundle install &&
          bundle exec rake gem:#{platform}:builder MAKE="nice make -j4" &&
          mkdir -p "$SRCDIR/pkg" &&
          cp -a "$STAGEDIR/pkg/." "$SRCDIR/pkg/"
        SH
        platform: platform,
        verbose: true
      )
    end

    namespace platform do
      task :builder do
        Rake::Task["native:#{platform}"].invoke
        Rake::Task["pkg/#{GEMSPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end

  desc 'Build precompiled gems for all platforms'
  multitask cross: CROSS_PLATFORMS.map { |p| "gem:#{p}" }

  desc 'Build precompiled gems for linux platforms'
  multitask linux: CROSS_PLATFORMS.grep(/linux/).map { |p| "gem:#{p}" }

  desc 'Build precompiled gems for darwin platforms'
  multitask darwin: CROSS_PLATFORMS.grep(/darwin/).map { |p| "gem:#{p}" }

  desc 'Build precompiled gems for windows platforms'
  multitask windows: CROSS_PLATFORMS.grep(/mingw|mswin/).map { |p| "gem:#{p}" }

  desc 'Build native gem for current platform'
  task native: %i[compile gem]
end
