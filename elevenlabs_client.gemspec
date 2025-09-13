# frozen_string_literal: true

require_relative "lib/elevenlabs_client/version"

Gem::Specification.new do |spec|
  spec.name = "elevenlabs_client"
  spec.version = ElevenlabsClient::VERSION
  spec.authors = ["Vitor Oliveira"]
  spec.email = ["vbrazo@gmail.com"]

  spec.summary = "Ruby client for ElevenLabs API"
  spec.description = "A Ruby client library for interacting with ElevenLabs dubbing and voice synthesis APIs"
  spec.homepage = "https://github.com/vbrazo/elevenlabs_client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "websocket-client-simple", "~> 0.8"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-core", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
