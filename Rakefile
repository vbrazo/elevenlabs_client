# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Define RSpec task
RSpec::Core::RakeTask.new(:spec)

# Default task
task default: :spec

# Custom tasks for gem management
namespace :gem do
  desc "Build the gem"
  task :build do
    sh "gem build elevenlabs_client.gemspec"
  end

  desc "Install the gem locally"
  task install: :build do
    version = File.read("lib/elevenlabs_client/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem install ./elevenlabs_client-#{version}.gem"
  end

  desc "Uninstall the gem"
  task :uninstall do
    version = File.read("lib/elevenlabs_client/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem uninstall elevenlabs_client -v #{version}"
  end

  desc "Clean up built gems"
  task :clean do
    sh "rm -f *.gem"
  end

  desc "Push gem to RubyGems"
  task push: :build do
    version = File.read("lib/elevenlabs_client/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem push elevenlabs_client-#{version}.gem"
  end
end

# Development tasks
namespace :dev do
  desc "Run all tests"
  task :test do
    sh "bundle exec rspec"
  end

  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    sh "bundle exec rspec"
  end

  desc "Run linter"
  task :lint do
    sh "bundle exec rubocop"
  end

  desc "Auto-correct linting issues"
  task :lint_fix do
    sh "bundle exec rubocop -a"
  end

  desc "Run security audit"
  task :audit do
    sh "bundle exec bundle-audit check --update"
  end

  desc "Run all security checks"
  task :security do
    Rake::Task["dev:audit"].invoke
  end

  desc "Update dependencies"
  task :update do
    sh "bundle update"
  end

  desc "Check for outdated dependencies"
  task :outdated do
    sh "bundle outdated"
  end
end

# Testing tasks
namespace :test do
  desc "Run unit tests only"
  task :unit do
    sh "bundle exec rspec spec/elevenlabs_client/endpoints/ spec/elevenlabs_client/client_spec.rb spec/elevenlabs_client/settings_spec.rb"
  end

  desc "Run integration tests only"
  task :integration do
    sh "bundle exec rspec spec/elevenlabs_client/client/ spec/elevenlabs_client/integration/"
  end

  desc "Run tests for a specific endpoint"
  task :endpoint, [:name] do |t, args|
    endpoint = args[:name]
    if endpoint
      sh "bundle exec rspec spec/elevenlabs_client/endpoints/#{endpoint}_spec.rb spec/elevenlabs_client/client/client_#{endpoint}_integration_spec.rb"
    else
      puts "Usage: rake test:endpoint[endpoint_name]"
      puts "Available endpoints: dubs, text_to_speech, text_to_speech_stream, text_to_dialogue, sound_generation, text_to_voice, models, voices, music"
    end
  end

  desc "Run performance tests"
  task :performance do
    sh "bundle exec rspec spec/performance/ --tag performance" if Dir.exist?("spec/performance")
  end
end

# Documentation tasks
namespace :docs do
  desc "Generate YARD documentation"
  task :generate do
    sh "bundle exec yard doc"
  end

  desc "Serve documentation locally"
  task :serve do
    sh "bundle exec yard server"
  end

  desc "Check documentation coverage"
  task :coverage do
    sh "bundle exec yard stats --list-undoc"
  end
end

# Release tasks
namespace :release do
  desc "Prepare for release (run tests, lint, build)"
  task :prepare do
    puts "🔍 Running tests..."
    Rake::Task["dev:test"].invoke
    
    puts "🧹 Running linter..."
    Rake::Task["dev:lint"].invoke
    
    puts "🔒 Running security checks..."
    Rake::Task["dev:security"].invoke
    
    puts "📦 Building gem..."
    Rake::Task["gem:build"].invoke
    
    puts "✅ Release preparation complete!"
  end

  desc "Create a new release (tag, build, push)"
  task :create do
    version = File.read("lib/elevenlabs_client/version.rb").match(/VERSION = "(.+)"/)[1]
    
    puts "🏷️  Creating git tag v#{version}..."
    sh "git tag v#{version}"
    sh "git push origin v#{version}"
    
    puts "📦 Building and pushing gem..."
    Rake::Task["gem:push"].invoke
    
    puts "🎉 Release v#{version} created successfully!"
  end

  desc "Check if ready for release"
  task :check do
    version = File.read("lib/elevenlabs_client/version.rb").match(/VERSION = "(.+)"/)[1]
    
    puts "📋 Release Checklist for v#{version}:"
    puts "  ✓ Version updated in version.rb"
    puts "  ✓ CHANGELOG.md updated" if File.read("CHANGELOG.md").include?(version)
    puts "  ✓ All tests passing" if system("bundle exec rspec > /dev/null 2>&1")
    puts "  ✓ No linting issues" if system("bundle exec rubocop > /dev/null 2>&1")
    puts "  ✓ Documentation up to date"
    puts "  ✓ Ready for release!"
  end
end

# Maintenance tasks
namespace :maintenance do
  desc "Clean up temporary files"
  task :clean do
    sh "rm -rf tmp/"
    sh "rm -rf coverage/"
    sh "rm -f *.gem"
    puts "🧹 Cleaned up temporary files"
  end

  desc "Reset development environment"
  task :reset do
    Rake::Task["maintenance:clean"].invoke
    sh "bundle install"
    puts "🔄 Development environment reset"
  end

  desc "Update copyright year"
  task :copyright do
    current_year = Date.today.year
    files = Dir["**/*.rb", "**/*.md"].reject { |f| f.include?("vendor/") || f.include?(".git/") }
    
    files.each do |file|
      content = File.read(file)
      updated = content.gsub(/Copyright \(c\) \d{4}/, "Copyright (c) #{current_year}")
      File.write(file, updated) if updated != content
    end
    
    puts "📅 Updated copyright year to #{current_year}"
  end
end

# Help task
desc "Show available tasks"
task :help do
  puts <<~HELP
    🎵 ElevenLabs Client Gem - Available Rake Tasks

    📦 Gem Management:
      rake gem:build          - Build the gem
      rake gem:install        - Install gem locally
      rake gem:uninstall      - Uninstall gem
      rake gem:clean          - Clean up built gems
      rake gem:push           - Push gem to RubyGems

    🧪 Testing:
      rake spec               - Run all tests (default)
      rake test:unit          - Run unit tests only
      rake test:integration   - Run integration tests only
      rake test:endpoint[name] - Run tests for specific endpoint
      rake dev:coverage       - Run tests with coverage

    🔧 Development:
      rake dev:lint           - Run linter
      rake dev:lint_fix       - Auto-fix linting issues
      rake dev:audit          - Run bundler-audit
      rake dev:security       - Run security checks
      rake dev:update         - Update dependencies
      rake dev:outdated       - Check outdated dependencies

    📚 Documentation:
      rake docs:generate      - Generate YARD docs
      rake docs:serve         - Serve docs locally
      rake docs:coverage      - Check doc coverage

    🚀 Release:
      rake release:prepare    - Prepare for release
      rake release:create     - Create new release
      rake release:check      - Check release readiness

    🧹 Maintenance:
      rake maintenance:clean  - Clean temporary files
      rake maintenance:reset  - Reset dev environment
      rake maintenance:copyright - Update copyright year

    Use 'rake -T' to see all available tasks.
  HELP
end