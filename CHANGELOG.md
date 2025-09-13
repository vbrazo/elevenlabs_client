# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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