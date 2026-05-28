# frozen_string_literal: true

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

CPP_SOURCES = FileList['ext/**/*.cpp'].exclude('ext/**/ryml_all.hpp')

namespace :lint do
  desc 'Check C++ formatting with clang-format'
  task :cpp do
    unformatted = CPP_SOURCES.to_a.select do |f|
      system("clang-format --dry-run --Werror #{f}", out: File::NULL, err: File::NULL) == false
    end
    unless unformatted.empty?
      unformatted.each { |f| warn "clang-format violation: #{f}" }
      abort 'Run `rake format:cpp` to fix.'
    end
  end
end

namespace :format do
  desc 'Auto-format C++ sources with clang-format'
  task :cpp do
    sh "clang-format -i #{CPP_SOURCES.join(' ')}"
  end
end

desc 'Run all linters (Ruby + C++)'
task lint: %i[rubocop lint:cpp]
