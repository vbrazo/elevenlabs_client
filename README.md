# ElevenlabsClient

[![Gem Version](https://badge.fury.io/rb/elevenlabs_client.svg)](https://badge.fury.io/rb/elevenlabs_client)

A comprehensive Ruby client library for the ElevenLabs API, supporting voice synthesis, dubbing, dialogue generation, sound effects, and AI music composition.

## Features

🎙️ **Text-to-Speech** - Convert text to natural-sounding speech  
🎬 **Dubbing** - Create dubbed versions of audio/video content  
💬 **Dialogue Generation** - Multi-speaker conversations  
🔊 **Sound Generation** - AI-generated sound effects and ambient audio  
🎵 **Music Generation** - AI-powered music composition and streaming  
🎨 **Voice Design** - Create custom voices from text descriptions  
🎭 **Voice Management** - Create, edit, and manage individual voices  
🤖 **Models** - List available models and their capabilities  
📡 **Streaming** - Real-time audio streaming  
⚙️ **Configurable** - Flexible configuration options  
🧪 **Well-tested** - Comprehensive test coverage  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elevenlabs_client'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install elevenlabs_client
```

## Quick Start

### Configuration

#### Rails Applications (Recommended)

Create `config/initializers/elevenlabs_client.rb`:

```ruby
ElevenlabsClient::Settings.configure do |config|
  config.properties = {
    elevenlabs_base_uri: ENV["ELEVENLABS_BASE_URL"],
    elevenlabs_api_key: ENV["ELEVENLABS_API_KEY"]
  }
end
```

Set your environment variables:

```bash
export ELEVENLABS_API_KEY="your_api_key_here"
export ELEVENLABS_BASE_URL="https://api.elevenlabs.io"  # Optional, defaults to official API
```

#### Direct Configuration

```ruby
# Module-level configuration
ElevenlabsClient.configure do |config|
  config.properties = {
    elevenlabs_base_uri: "https://api.elevenlabs.io",
    elevenlabs_api_key: "your_api_key_here"
  }
end

# Or pass directly to client
client = ElevenlabsClient.new(
  api_key: "your_api_key_here",
  base_url: "https://api.elevenlabs.io"
)
```

### Basic Usage

```ruby
# Initialize client (uses configured settings)
client = ElevenlabsClient.new

# Text-to-Speech
audio_data = client.text_to_speech.convert("21m00Tcm4TlvDq8ikWAM", "Hello, world!")
File.open("hello.mp3", "wb") { |f| f.write(audio_data) }

# Dubbing
File.open("video.mp4", "rb") do |file|
  result = client.dubs.create(
    file_io: file,
    filename: "video.mp4",
    target_languages: ["es", "fr", "de"]
  )
end

# Dialogue Generation
dialogue = [
  { text: "Hello, how are you?", voice_id: "voice_1" },
  { text: "I'm doing great, thanks!", voice_id: "voice_2" }
]
audio_data = client.text_to_dialogue.convert(dialogue)

# Sound Generation
audio_data = client.sound_generation.generate("Ocean waves crashing on rocks")

# Voice Design
design_result = client.text_to_voice.design("Warm, professional female voice")
generated_voice_id = design_result["previews"].first["generated_voice_id"]

voice_result = client.text_to_voice.create(
  "Professional Voice",
  "Warm, professional female voice",
  generated_voice_id
)

# List Available Models
models = client.models.list
fastest_model = models["models"].min_by { |m| m["token_cost_factor"] }
puts "Fastest model: #{fastest_model['name']}"

# Voice Management
voices = client.voices.list
puts "Total voices: #{voices['voices'].length}"

# Create custom voice from audio samples
File.open("sample1.mp3", "rb") do |sample|
  voice = client.voices.create("My Voice", [sample], description: "Custom narrator voice")
  puts "Created voice: #{voice['voice_id']}"
end

# Music Generation
music_data = client.music.compose(
  prompt: "Upbeat electronic dance track with synthesizers",
  music_length_ms: 30000
)
File.open("generated_music.mp3", "wb") { |f| f.write(music_data) }

# Streaming Text-to-Speech
client.text_to_speech_stream.stream("voice_id", "Streaming text") do |chunk|
  # Process audio chunk in real-time
  puts "Received #{chunk.bytesize} bytes"
end
```

## API Documentation

### Core APIs

- **[Dubbing API](docs/DUBBING.md)** - Create dubbed versions of audio/video content
- **[Text-to-Speech API](docs/TEXT_TO_SPEECH.md)** - Convert text to natural speech
- **[Text-to-Speech Streaming API](docs/TEXT_TO_SPEECH_STREAMING.md)** - Real-time audio streaming
- **[Text-to-Dialogue API](docs/TEXT_TO_DIALOGUE.md)** - Multi-speaker conversations
- **[Sound Generation API](docs/SOUND_GENERATION.md)** - AI-generated sound effects
- **[Music Generation API](docs/MUSIC.md)** - AI-powered music composition and streaming
- **[Text-to-Voice API](docs/TEXT_TO_VOICE.md)** - Design and create custom voices
- **[Voice Management API](docs/VOICES.md)** - Manage individual voices (CRUD operations)
- **[Models API](docs/MODELS.md)** - List available models and capabilities

### Available Endpoints

| Endpoint | Description | Documentation |
|----------|-------------|---------------|
| `client.dubs.*` | Audio/video dubbing | [DUBBING.md](docs/DUBBING.md) |
| `client.text_to_speech.*` | Text-to-speech conversion | [TEXT_TO_SPEECH.md](docs/TEXT_TO_SPEECH.md) |
| `client.text_to_speech_stream.*` | Streaming TTS | [TEXT_TO_SPEECH_STREAMING.md](docs/TEXT_TO_SPEECH_STREAMING.md) |
| `client.text_to_dialogue.*` | Dialogue generation | [TEXT_TO_DIALOGUE.md](docs/TEXT_TO_DIALOGUE.md) |
| `client.sound_generation.*` | Sound effect generation | [SOUND_GENERATION.md](docs/SOUND_GENERATION.md) |
| `client.music.*` | AI music composition and streaming | [MUSIC.md](docs/MUSIC.md) |
| `client.text_to_voice.*` | Voice design and creation | [TEXT_TO_VOICE.md](docs/TEXT_TO_VOICE.md) |
| `client.voices.*` | Voice management (CRUD) | [VOICES.md](docs/VOICES.md) |
| `client.models.*` | Model information and capabilities | [MODELS.md](docs/MODELS.md) |

## Configuration Options

### Configuration Precedence

1. **Explicit parameters** (highest priority)
2. **Settings.properties** (configured via initializer)
3. **Environment variables** (lowest priority)

### Environment Variables

- `ELEVENLABS_API_KEY` - Your ElevenLabs API key (required)
- `ELEVENLABS_BASE_URL` - API base URL (optional, defaults to `https://api.elevenlabs.io`)

### Custom Environment Variable Names

```ruby
client = ElevenlabsClient.new(
  api_key_env: "CUSTOM_API_KEY_VAR",
  base_url_env: "CUSTOM_BASE_URL_VAR"
)
```

## Error Handling

The client provides specific exception types for different error conditions:

```ruby
begin
  result = client.text_to_speech.convert(voice_id, text)
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid parameters: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

### Exception Types

- `AuthenticationError` - Invalid API key or authentication failure
- `RateLimitError` - Rate limit exceeded
- `ValidationError` - Invalid request parameters
- `APIError` - General API errors

## Rails Integration

The gem is designed to work seamlessly with Rails applications. See the [examples](examples/) directory for complete controller implementations:

- [DubsController](examples/dubs_controller.rb) - Complete dubbing workflow
- [TextToSpeechController](examples/text_to_speech_controller.rb) - TTS with error handling
- [StreamingAudioController](examples/streaming_audio_controller.rb) - Real-time streaming
- [TextToDialogueController](examples/text_to_dialogue_controller.rb) - Dialogue generation
- [SoundGenerationController](examples/sound_generation_controller.rb) - Sound effects
- [MusicController](examples/music_controller.rb) - AI music composition and streaming
- [TextToVoiceController](examples/text_to_voice_controller.rb) - Voice design and creation
- [VoicesController](examples/voices_controller.rb) - Voice management (CRUD operations)

## Development

After checking out the repo, run:

```bash
bin/setup          # Install dependencies
bundle exec rspec  # Run tests
```

To install this gem onto your local machine:

```bash
bundle exec rake install
```

To release a new version:

1. Update the version number in `version.rb`
2. Update `CHANGELOG.md`
3. Run `bundle exec rake release`

## Testing

The gem includes comprehensive test coverage with RSpec:

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/elevenlabs_client/endpoints/
bundle exec rspec spec/elevenlabs_client/client
bundle exec rspec spec/integration/

# Run with documentation format
bundle exec rspec --format documentation
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/elevenlabs_client.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.

## Support

- 📖 **Documentation**: [API Documentation](docs/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/elevenlabs_client/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/elevenlabs_client/discussions)

---

Made with ❤️ for the Ruby community
