# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Admin: Pronunciation Dictionaries
  - Create dictionary from file: `client.pronunciation_dictionaries.add_from_file(name:, file_io: nil, filename: nil, description: nil, workspace_access: nil)`
  - Create dictionary from rules: `client.pronunciation_dictionaries.add_from_rules(name:, rules:, description: nil, workspace_access: nil)`
  - Get dictionary metadata: `client.pronunciation_dictionaries.get(pronunciation_dictionary_id)`
  - Update dictionary: `client.pronunciation_dictionaries.update(pronunciation_dictionary_id, **attributes)`
  - Download dictionary version (PLS): `client.pronunciation_dictionaries.download_pronunciation_dictionary_version(dictionary_id:, version_id:)`
  - List dictionaries: `client.pronunciation_dictionaries.list_pronunciation_dictionaries(cursor:, page_size:, sort:, sort_direction:)`

### Docs
- Added `docs/admin/PRONUNCIATION_DICTIONARIES.md`
- Updated `docs/admin/README.md` and main `README.md` with links and examples

## [0.7.0] - 2024-09-15

### Added
- **🗑️ Admin Samples Management** - Voice sample deletion and content moderation
  - **Sample Deletion** (`client.samples.*`) - Delete voice samples by ID for content moderation and cleanup
  - Comprehensive error handling for voice and sample validation
  - Security-focused operations with proper authentication and authorization
  - Method aliases: `delete_voice_sample`, `remove_sample`

- **🏢 Admin Service Accounts** - Complete service account monitoring and management
  - **Account Monitoring** (`client.service_accounts.*`) - List all service accounts in workspace
  - **API Key Analytics** - Monitor API key status, permissions, and usage across all accounts
  - **Usage Tracking** - Character usage monitoring with limits and projections
  - **Security Auditing** - Comprehensive security analysis and compliance reporting
  - Method aliases: `list`, `all`, `service_accounts`

- **🔗 Admin Webhooks Management** - Workspace webhook monitoring and health analysis
  - **Webhook Monitoring** (`client.webhooks.*`) - List all workspace webhooks with detailed status
  - **Health Analysis** - Monitor webhook failures, auto-disabled status, and recent error codes
  - **Security Auditing** - Authentication method analysis and HTTPS compliance checking
  - **Usage Analytics** - Track webhook usage across different services and features
  - Method aliases: `get_webhooks`, `all`, `webhooks`

### Enhanced
- **📚 Documentation Expansion** - Comprehensive documentation for new admin endpoints
  - Added `docs/admin/SAMPLES.md` - Voice sample management and content moderation guide (883 lines)
  - Added `docs/admin/SERVICE_ACCOUNTS.md` - Service account monitoring and security analysis guide (1,264 lines)
  - Added `docs/admin/WEBHOOKS.md` - Webhook management and health monitoring guide (1,264 lines)
  - Updated `docs/admin/README.md` - Enhanced admin overview with all endpoints (548 lines)
  - Updated main README.md with new admin endpoint documentation
  - Total: 3,959 lines of additional admin documentation

- **🎯 Example Controllers** - Production-ready Rails integration examples for new endpoints
  - Added `examples/admin/samples_controller.rb` - Sample deletion with content moderation workflows (767 lines)
  - Added `examples/admin/service_accounts_controller.rb` - Account monitoring with analytics dashboard (500+ lines)
  - Added `examples/admin/webhooks_controller.rb` - Webhook health monitoring with export capabilities (761 lines)
  - All controllers include comprehensive error handling, filtering, and export functionality

### Improved
- **🧪 Test Coverage** - Comprehensive testing for all new admin endpoints
  - Added 35 new endpoint tests covering samples, service accounts, and webhooks
  - Added 31 new integration tests with proper WebMock stubbing and response validation
  - Enhanced error handling tests for all new admin scenarios
  - Total: 66 new tests, bringing total to 874 examples with 100% pass rate

- **🔧 Client Integration** - Seamless integration of new admin endpoints
  - Updated `Client` class to expose new admin endpoints (`samples`, `service_accounts`, `webhooks`)
  - Enhanced error handling for admin-specific scenarios across all endpoints
  - Consistent API patterns and response structures
  - Proper namespacing under `ElevenlabsClient::Admin` module

### Technical Improvements
- **🔒 Security Management** - Advanced security monitoring and compliance
  - Voice sample content moderation with audit trails
  - Service account permission analysis and excessive privilege detection
  - Webhook security auditing with HTTPS and authentication validation
  - Comprehensive security reporting and recommendation systems

- **📊 Health Monitoring** - Sophisticated health analysis across admin resources
  - Webhook failure tracking with error code analysis and auto-disable detection
  - Service account usage monitoring with character limit projections
  - Sample deletion tracking for content moderation compliance
  - Real-time health status reporting with actionable insights

- **🛡️ Content Moderation** - Professional content management capabilities
  - Secure sample deletion with proper authentication and logging
  - Batch sample operations for efficient content cleanup
  - Audit trail support for compliance and tracking
  - Integration with content moderation workflows and policies

- **📈 Analytics & Reporting** - Advanced analytics across all admin functions
  - Service account usage analytics with trend analysis
  - Webhook performance monitoring with failure rate calculations
  - Sample deletion analytics for content moderation reporting
  - Exportable reports in CSV, JSON, and Excel formats

## [0.6.0] - 2024-09-15

### Added
- **🏢 Admin API Suite** - Complete administrative functionality for account management
  - **User Management** (`client.user.*`) - Access comprehensive user account information, subscription details, and feature availability
  - **Usage Analytics** (`client.usage.*`) - Monitor character usage with detailed analytics, breakdowns by voice/model/source, and trend analysis
  - **Voice Library** (`client.voice_library.*`) - Browse and manage community shared voices with advanced filtering and search capabilities
  - All admin endpoints include comprehensive error handling and response validation

### Enhanced
- **📚 Documentation Expansion** - Comprehensive documentation for all admin functionality
  - Added `docs/admin/USER.md` - User account and subscription management guide (589 lines)
  - Added `docs/admin/USAGE.md` - Usage analytics and monitoring guide (604 lines)
  - Added `docs/admin/VOICE_LIBRARY.md` - Voice library browsing and management guide (883 lines)
  - Added `docs/admin/README.md` - Admin API overview and quick start guide (472 lines)
  - Updated main README.md with admin endpoint documentation and examples
  - Total: 3,512 lines of new admin documentation

- **🎯 Example Controllers** - Production-ready Rails integration examples
  - Added `examples/admin/user_controller.rb` - User dashboard with health monitoring (767 lines)
  - Added `examples/admin/usage_controller.rb` - Usage analytics dashboard with real-time monitoring (584 lines)
  - Added `examples/admin/voice_library_controller.rb` - Voice library browser with curation tools (844 lines)
  - Added `examples/admin/models_controller.rb` - Model comparison and selection guide (983 lines)
  - All controllers include comprehensive error handling, JSON API support, and export functionality

### Improved
- **🧪 Test Coverage** - Comprehensive testing for all admin functionality
  - Added 88 endpoint tests covering all admin API methods and error scenarios
  - Added 77 integration tests covering real-world usage patterns and workflows
  - All tests include proper error handling validation and response structure verification
  - Total: 165 new tests with 100% pass rate

- **🔧 Client Integration** - Seamless integration of admin endpoints
  - Updated `Client` class to expose all admin endpoints (`usage`, `user`, `voice_library`)
  - Enhanced error handling for admin-specific scenarios
  - Consistent API patterns across all admin endpoints
  - Proper namespacing under `ElevenlabsClient::Admin` module

### Technical Improvements
- **📊 Advanced Analytics** - Sophisticated usage monitoring and insights
  - Character usage breakdowns by voice, model, user, and source
  - Time-based aggregation (hour, day, week, month, cumulative)
  - Trend analysis and forecasting capabilities
  - Cost estimation and optimization recommendations

- **🎤 Voice Discovery** - Powerful voice library management
  - Advanced filtering by category, gender, age, accent, language, and use case
  - Voice recommendation engine based on requirements
  - Bulk voice addition and collection curation tools
  - Voice analytics and popularity tracking

- **👤 Account Management** - Comprehensive user account oversight
  - Real-time subscription monitoring and health checks
  - Usage limit tracking with projections and alerts
  - Feature availability matrix and upgrade recommendations
  - Security and moderation status monitoring

### Changed
- **🔄 Code Organization** - Moved TextToDialogue class to its own file
  - Extracted `TextToDialogue` class from `text_to_speech.rb` to `text_to_dialogue.rb`
  - Improved code organization and modularity
  - All tests and functionality remain unchanged
  - Added Speech-to-Text delete transcript endpoint (`delete_transcript`)

## [0.5.1] - 2024-09-15

### Removed
- **🧹 Dependency Optimization** - Removed unnecessary development dependencies
  - Removed `rubocop` and `rubocop-rspec` dependencies
  - Removed `brakeman` dependency (not suitable for gem libraries)
  - Removed `.rubocop.yml` and `.brakeman.yml` configuration files
  - Reduced bundle size from 49 to 31 gems (37% reduction)

### Changed
- **⚡ CI/CD Optimization** - Simplified and streamlined continuous integration
  - Removed linting job from GitHub Actions workflow
  - Focused CI pipeline on essential checks: tests, security, and build
  - Updated CI to use only `bundler-audit` for dependency vulnerability scanning
  - Faster CI builds with fewer dependencies and simpler workflow

### Updated
- **📚 Documentation Cleanup** - Updated documentation to reflect simplified toolchain
  - Removed RuboCop references from README.md
  - Updated CI/CD documentation section
  - Simplified development workflow documentation
  - Updated Rake task descriptions and help text
- **🔧 Development Tools** - Streamlined development workflow
  - Removed lint-related Rake tasks (`dev:lint`, `dev:lint_fix`, `dev:brakeman`)
  - Simplified `release:prepare` task to focus on tests and security
  - Updated help documentation for available Rake tasks

### Technical Improvements
- **📦 Leaner Dependencies** - More focused dependency management
  - Kept only essential development tools: RSpec, WebMock, bundler-audit
  - Maintained security scanning through bundler-audit
  - Improved bundle install speed and reduced maintenance overhead
- **🚀 Performance** - Faster development and CI workflows
  - Reduced Docker image sizes for CI/CD
  - Faster bundle installations
  - Simplified toolchain reduces cognitive overhead

### Notes
- This release focuses on optimizing the development experience and CI/CD pipeline
- Security scanning is maintained through bundler-audit, which is more appropriate for gem libraries
- The simplified toolchain reduces maintenance overhead while maintaining code quality through comprehensive testing

## [0.5.0] - 2025-09-14

### Added

- Text-to-Speech With Timestamps
  - `client.text_to_speech_with_timestamps.generate(voice_id, text, **options)`
  - Character-level `alignment` and `normalized_alignment`
- Streaming Text-to-Speech With Timestamps
  - `client.text_to_speech_stream_with_timestamps.stream(voice_id, text, **options, &block)`
  - JSON streaming with audio chunks and timing per chunk
- WebSocket Streaming Enhancements
  - Single-context and multi-context improvements; correct query param ordering and filtering
  - Docs: `docs/WEBSOCKET_STREAMING.md`
- Text-to-Dialogue Streaming
  - `client.text_to_dialogue_stream.stream(inputs, **options, &block)`
  - Docs: `docs/TEXT_TO_DIALOGUE_STREAMING.md`

### Improved

- Client streaming JSON handling for timestamp streams (`post_streaming_with_timestamps`)
- Robust parsing and block yielding across streaming tests
- URL query parameter ordering to match expectations in tests

### Tests

- Added comprehensive unit and integration tests for all new endpoints
- Full suite now: 687 examples, 0 failures

### Notes

- These features require valid ElevenLabs API keys and correct model/voice permissions

## [0.4.0] - 2025-09-12

### Added

- **🎵 Dubbing Generation API** 
  - `delete(dubbing_id)` - Delete dubbing projects
  - `get_resource(dubbing_id)` - Get detailed resource information
  - `create_segment(options)` - Create new segments
  - `delete_segment(options)` - Delete segments
  - `update_segment(options)` - Update segment text/timing
  - `transcribe_segment(options)` - Regenerate transcriptions
  - `translate_segment(options)` - Regenerate translations
  - `dub_segment(options)` - Regenerate dubs
  - `render_project(options)` - Render output media
  - `update_speaker(options)` - Update speaker voices
  - `get_similar_voices(options)` - Get voice recommendations
- **🔧 HTTP Client Improvements** - Added HTTP method
  - Added `patch` method for PATCH requests

## [0.3.0] - 2025-09-12

### Added
- **🎵 Music Generation API** - AI-powered music composition and streaming
  - `client.music.compose(options)` - Generate music from text prompts
  - `client.music.compose_stream(options, &block)` - Real-time music streaming
  - `client.music.compose_detailed(options)` - Generate music with metadata
  - `client.music.create_plan(options)` - Create structured composition plans
- **🎭 Voice Management API** - Complete CRUD operations for individual voices
  - `client.voices.get(voice_id)` - Get detailed voice information
  - `client.voices.list()` - List all voices in account
  - `client.voices.create(name, samples, **options)` - Create custom voices from audio samples
  - `client.voices.edit(voice_id, samples, **options)` - Edit existing voices
  - `client.voices.delete(voice_id)` - Delete voices from account
  - `client.voices.banned?(voice_id)` - Check voice safety status
  - `client.voices.active?(voice_id)` - Check voice availability
- **📋 Enhanced Rakefile** - Comprehensive gem management and development tasks
  - Build, install, push, and clean gem operations
  - Development tools (linting, testing, security audit)
  - Documentation generation and serving
  - Release preparation and management
  - Maintenance and cleanup tasks

### Enhanced
- **🚨 Consolidated Error Handling** - Unified error handling across all endpoints
  - Merged `handle_response`, `handle_binary_response`, and `handle_streaming_response` into single method
  - Enhanced error message extraction from JSON, nested objects, arrays, and plain text
  - More specific error types: `BadRequestError`, `NotFoundError`, `UnprocessableEntityError`
  - Better error messages extracted from actual API responses instead of generic fallbacks
- **🔧 HTTP Client Improvements** - Added missing HTTP methods and consolidated functionality
  - Added `delete` method for DELETE requests
  - Enhanced `post_with_custom_headers` for flexible header management
  - Consistent error handling across all HTTP methods (GET, POST, DELETE, multipart, binary, streaming)
- **📚 Documentation Organization** - Comprehensive documentation for all new features
  - [MUSIC.md](docs/MUSIC.md) - Complete music generation guide (570 lines)
  - [VOICES.md](docs/VOICES.md) - Voice management documentation (519 lines)
  - Enhanced README with music capabilities and updated feature list
  - Professional Rails integration examples

### New Error Classes
- `ElevenlabsClient::BadRequestError` (400) - Invalid parameters or malformed requests
- `ElevenlabsClient::NotFoundError` (404) - Resource not found
- `ElevenlabsClient::UnprocessableEntityError` (422) - Valid request but invalid data

### Music Generation Features
- **🎼 Composition Styles** - Support for all major music genres
  - Electronic: EDM, House, Techno, Ambient, Synthwave
  - Orchestral: Classical, Film Score, Epic Orchestral
  - Popular: Pop, Rock, Hip-Hop, Country, Folk
  - Jazz & Blues: Traditional Jazz, Smooth Jazz, Blues
  - World Music: Celtic, Medieval, New Age, Ethnic
- **🎛️ Advanced Controls** - Detailed composition parameters
  - Custom composition plans with sections, tempo, key, instruments
  - Multiple output formats (MP3, WAV) with quality settings
  - Music length control (5 seconds to 5 minutes)
  - Model selection for different generation approaches
- **📡 Streaming Support** - Real-time music generation and playback
  - Chunk-based streaming for immediate playback
  - Memory-efficient processing for long compositions
  - WebSocket integration for live applications

### Voice Management Features
- **🎤 Voice Creation** - Create custom voices from audio samples
  - Multiple sample upload support for better quality
  - Voice metadata and labeling system
  - Quality validation and optimization
- **🔧 Voice Editing** - Modify existing voices
  - Add new samples to improve voice quality
  - Update voice metadata and descriptions
  - Batch voice operations
- **🔍 Voice Discovery** - Advanced voice management
  - Search and filter voices by category, labels, quality
  - Voice status checking (active, banned, available)
  - Voice analytics and usage tracking

### Rails Integration Examples
- **[MusicController](examples/music_controller.rb)** - Complete music generation implementation
  - Basic and advanced music generation endpoints
  - Streaming music with real-time playback
  - Composition planning and structured music creation
  - Batch generation and music library management
  - Interactive music generation with user preferences
- **[VoicesController](examples/voices_controller.rb)** - Voice management implementation
  - Full CRUD operations for voice management
  - File upload handling for voice samples
  - Voice search and filtering capabilities
  - Batch voice operations and management workflows

### Technical Improvements
- **🧪 Comprehensive Testing** - Expanded test coverage
  - **57 new music tests** (24 unit + 33 integration)
  - **Enhanced error handling tests** across all endpoints
  - **Total test coverage**: 300+ tests with consistent passing
- **🏗️ Architecture Consolidation** - Cleaner codebase
  - Removed duplicate error handling methods
  - Consolidated HTTP response processing
  - Enhanced error message extraction with fallback handling
  - Improved code organization and maintainability
- **📦 Release Management** - Professional release workflow
  - Automated release preparation tasks
  - Version management and changelog automation
  - Security auditing and dependency management
  - Documentation generation and validation

### Breaking Changes
- **Error Handling** - More specific error types may require catch block updates
  ```ruby
  # Before (v0.2.0)
  rescue ElevenlabsClient::ValidationError => e
    # Handle all 4xx errors
  end
  
  # After (v0.3.0) - More specific handling
  rescue ElevenlabsClient::BadRequestError => e
    # Handle 400 Bad Request
  rescue ElevenlabsClient::NotFoundError => e
    # Handle 404 Not Found
  rescue ElevenlabsClient::UnprocessableEntityError => e
    # Handle 422 Unprocessable Entity
  rescue ElevenlabsClient::ValidationError => e
    # Handle other 4xx errors
  end
  ```

### Migration Guide
```ruby
# New Music API Usage
client = ElevenlabsClient.new

# Generate music
music_data = client.music.compose(
  prompt: "Upbeat electronic dance track",
  music_length_ms: 30000
)

# Stream music generation
client.music.compose_stream(prompt: "Relaxing ambient") do |chunk|
  # Process audio chunk in real-time
end

# Voice management
voices = client.voices.list
voice = client.voices.get("voice_id")

# Create custom voice
File.open("sample.mp3", "rb") do |sample|
  voice = client.voices.create("My Voice", [sample])
end
```

## [0.2.0] - 2025-09-12

### Added
- **Text-to-Speech API** - Convert text to natural-sounding speech with voice customization
- **Text-to-Speech Streaming API** - Real-time audio streaming for live applications
- **Text-to-Dialogue API** - Multi-speaker conversation generation
- **Sound Generation API** - AI-generated sound effects and ambient audio
- **Comprehensive Documentation** - Separate documentation files for each API endpoint
- **Rails Integration Examples** - Complete controller examples for all endpoints
- **Enhanced Configuration** - Flexible configuration with Settings module
- **Streaming Support** - Real-time audio chunk processing with block callbacks
- **Binary Response Handling** - Proper handling of audio data responses
- **Query Parameter Support** - URL query parameters for API requests

### Enhanced
- **Endpoint Organization** - Moved all endpoints to dedicated `lib/elevenlabs_client/endpoints/` directory
- **Client Architecture** - Separated HTTP client logic from endpoint-specific functionality
- **Error Handling** - Enhanced error handling with streaming-specific exceptions
- **Test Coverage** - Expanded test suite to 187+ tests covering all new functionality
- **Configuration System** - Priority-based configuration (explicit > Settings > ENV)

### Documentation
- **Modular Documentation** - Split endpoint documentation into separate files:
  - [DUBBING.md](docs/DUBBING.md) - Audio/video dubbing functionality
  - [TEXT_TO_SPEECH.md](docs/TEXT_TO_SPEECH.md) - Text-to-speech conversion
  - [TEXT_TO_SPEECH_STREAMING.md](docs/TEXT_TO_SPEECH_STREAMING.md) - Real-time streaming
  - [TEXT_TO_DIALOGUE.md](docs/TEXT_TO_DIALOGUE.md) - Multi-speaker dialogues
  - [SOUND_GENERATION.md](docs/SOUND_GENERATION.md) - Sound effect generation
- **Improved README** - Streamlined main README with quick start guide
- **Rails Examples** - Complete controller implementations for all endpoints
- **Usage Examples** - Comprehensive examples for each API feature

### New Endpoints
- `client.text_to_speech.*` - Text-to-speech conversion with voice settings
- `client.text_to_speech_stream.*` - Real-time streaming text-to-speech
- `client.text_to_dialogue.*` - Multi-speaker dialogue generation
- `client.sound_generation.*` - AI sound effect and ambient audio generation

### New Features
- **Voice Customization** - Stability, similarity boost, style controls
- **Audio Formats** - Multiple output formats (MP3, PCM) with quality options
- **Looping Audio** - Generate seamless looping sound effects
- **Deterministic Generation** - Seed support for consistent results
- **Batch Processing** - Multiple sound generation in single requests
- **WebSocket Integration** - Real-time streaming to WebSocket connections
- **File Format Support** - Enhanced support for various audio/video formats

### Technical Improvements
- **Modular Architecture** - Clean separation of concerns with endpoint classes
- **HTTP Client Enhancement** - Added streaming, binary, and custom header support
- **Settings Management** - Centralized configuration with Rails initializer support
- **Memory Management** - Efficient handling of large audio files and streams
- **Concurrent Testing** - Parallel test execution for faster development

### Examples Added
- `examples/dubs_controller.rb` - Complete dubbing workflow with batch processing
- `examples/text_to_speech_controller.rb` - TTS with voice customization
- `examples/streaming_audio_controller.rb` - Real-time streaming with WebSocket support
- `examples/text_to_dialogue_controller.rb` - Specialized dialogue endpoints
- `examples/sound_generation_controller.rb` - Sound effects with presets and batch processing
- `examples/rails_initializer.rb` - Rails configuration example

### Breaking Changes
- **Endpoint Access** - Dubbing methods moved from `client.create_dub` to `client.dubs.create`
- **File Structure** - Endpoint classes moved to `lib/elevenlabs_client/endpoints/`
- **Configuration** - Enhanced configuration system with new precedence rules

### Migration Guide
```ruby
# Before (v0.1.0)
client.create_dub(file_io: file, filename: "video.mp4", target_languages: ["es"])

# After (v0.2.0)
client.dubs.create(file_io: file, filename: "video.mp4", target_languages: ["es"])
```

## [0.1.0] - 2025-09-12

### Added
- Initial release of ElevenLabs Client gem
- Support for ElevenLabs Dubbing API
- Create dubbing jobs with video/audio files
- Monitor dubbing job status
- List dubbing jobs with filters
- Retrieve dubbing resources for editing
- Comprehensive error handling with specific exception types
- Support for multiple target languages
- Configurable API endpoint and authentication
- Full test coverage with RSpec
- WebMock integration for testing

### Features
- **Dubbing API**: Complete support for ElevenLabs dubbing workflow
- **Error Handling**: Specific exceptions for different error conditions
- **File Support**: Multiple video and audio formats (MP4, MOV, MP3, WAV, etc.)
- **Language Support**: Multiple target languages for dubbing
- **Configuration**: Flexible API key and endpoint configuration
- **Testing**: Comprehensive test suite with integration tests
