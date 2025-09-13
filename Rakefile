# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run all tests"
task default: :spec

desc "Run tests with coverage"
task :spec_with_coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:spec].invoke
end

desc "Generate documentation"
task :doc do
  system("yard doc")
end

desc "Check code quality"
task :quality do
  system("rubocop")
end

desc "Run all checks (tests, quality)"
task check: [:spec, :quality]
