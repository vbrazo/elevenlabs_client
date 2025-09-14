# Text-to-Speech with Timestamps

This document provides examples and documentation for ElevenLabs' text-to-speech with timestamps functionality using the `elevenlabs_client` gem.

## Features

- Generate speech from text with precise character-level timing information
- Stream speech generation with real-time timestamp data
- Support for various voice settings and models
- Audio-text synchronization capabilities

## Table of Contents

- [Generate Speech with Timestamps](#generate-speech-with-timestamps)
- [Stream Speech with Timestamps](#stream-speech-with-timestamps)
- [Configuration Options](#configuration-options)
- [Response Format](#response-format)
- [Examples](#examples)

## Generate Speech with Timestamps

The text-to-speech with timestamps endpoint converts text to speech and returns both the audio data (base64 encoded) and precise character-level timing information.

### Basic Usage

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient::Client.new(api_key: "your-api-key")

# Generate speech with timestamps
voice_id = "21m00Tcm4TlvDq8ikWAM"
text = "Hello world! This is a test for the API of ElevenLabs."

response = client.text_to_speech.convert_with_timestamps(voice_id, text)

# Access the results
audio_data = Base64.decode64(response["audio_base64"])
alignment = response["alignment"]
normalized_alignment = response["normalized_alignment"]

puts "Generated audio with #{alignment['characters'].length} characters"
puts "First character: #{alignment['characters'][0]} at #{alignment['character_start_times_seconds'][0]}s"
```

### Advanced Usage with Options

```ruby
# Generate with custom settings
response = client.text_to_speech.convert_with_timestamps(
  voice_id,
  text,
  model_id: "eleven_multilingual_v2",
  output_format: "mp3_44100_128",
  voice_settings: {
    stability: 0.5,
    similarity_boost: 0.8,
    style: 0.5,
    use_speaker_boost: true
  },
  language_code: "en",
  apply_text_normalization: "auto",
  seed: 12345
)
```

## Stream Speech with Timestamps

The streaming version provides real-time audio chunks with timestamp information as they are generated.

### Basic Streaming

```ruby
# Stream speech with timestamps
client.text_to_speech.stream_with_timestamps(voice_id, text) do |chunk|
  # Each chunk contains audio and alignment data
  if chunk["audio_base64"]
    audio_data = Base64.decode64(chunk["audio_base64"])
    # Process audio chunk
    
    if chunk["alignment"]
      # Process timing information
      characters = chunk["alignment"]["characters"]
      start_times = chunk["alignment"]["character_start_times_seconds"]
      end_times = chunk["alignment"]["character_end_times_seconds"]
      
      puts "Received #{characters.length} characters in this chunk"
    end
  end
end
```

### Advanced Streaming Options

```ruby
# Stream with custom options
client.text_to_speech.stream_with_timestamps(
  voice_id,
  text,
  model_id: "eleven_multilingual_v2",
  output_format: "mp3_44100_128",
  voice_settings: {
    stability: 0.5,
    similarity_boost: 0.8
  },
  optimize_streaming_latency: 1,
  enable_logging: false
) do |chunk|
  # Handle each streaming chunk
  process_audio_chunk(chunk)
end
```

## Configuration Options

### Common Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `voice_id` | String | Voice ID to be used | Required |
| `text` | String | Text to convert to speech | Required |
| `model_id` | String | Model identifier | "eleven_multilingual_v2" |
| `output_format` | String | Audio output format | "mp3_44100_128" |
| `language_code` | String | ISO 639-1 language code | nil |
| `enable_logging` | Boolean | Enable request logging | true |

### Voice Settings

```ruby
voice_settings = {
  stability: 0.5,              # 0.0 to 1.0
  similarity_boost: 0.8,       # 0.0 to 1.0
  style: 0.5,                  # 0.0 to 1.0
  use_speaker_boost: true      # Boolean
}
```

### Advanced Options

| Parameter | Type | Description |
|-----------|------|-------------|
| `pronunciation_dictionary_locators` | Array | Pronunciation dictionaries (max 3) |
| `seed` | Integer | Deterministic sampling seed (0-4294967295) |
| `previous_text` | String | Text from previous generation |
| `next_text` | String | Text for next generation |
| `previous_request_ids` | Array | Previous request IDs (max 3) |
| `next_request_ids` | Array | Next request IDs (max 3) |
| `apply_text_normalization` | String | "auto", "on", or "off" |
| `apply_language_text_normalization` | Boolean | Language-specific normalization |

## Response Format

### Non-Streaming Response

```ruby
{
  "audio_base64" => "base64_encoded_audio_string",
  "alignment" => {
    "characters" => ["H", "e", "l", "l", "o"],
    "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4],
    "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5]
  },
  "normalized_alignment" => {
    "characters" => ["H", "e", "l", "l", "o"],
    "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4],
    "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5]
  }
}
```

### Streaming Response Chunks

Each streaming chunk contains:

```ruby
{
  "audio_base64" => "base64_encoded_audio_chunk",
  "alignment" => {
    "characters" => ["w", "o", "r", "l", "d"],
    "character_start_times_seconds" => [0.5, 0.6, 0.7, 0.8, 0.9],
    "character_end_times_seconds" => [0.6, 0.7, 0.8, 0.9, 1.0]
  },
  "normalized_alignment" => {
    # Same structure as alignment
  }
}
```

## Examples

### Generate and Save Audio with Timing Data

```ruby
require 'elevenlabs_client'
require 'json'

client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

voice_id = "21m00Tcm4TlvDq8ikWAM"
text = "The quick brown fox jumps over the lazy dog."

# Generate speech with timestamps
response = client.text_to_speech.convert_with_timestamps(voice_id, text)

# Save audio file
audio_data = Base64.decode64(response["audio_base64"])
File.open("output.mp3", "wb") { |f| f.write(audio_data) }

# Save timing data
File.open("timing.json", "w") do |f|
  f.write(JSON.pretty_generate({
    alignment: response["alignment"],
    normalized_alignment: response["normalized_alignment"]
  }))
end

puts "Audio saved to output.mp3"
puts "Timing data saved to timing.json"
```

### Stream with Real-time Processing

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

voice_id = "21m00Tcm4TlvDq8ikWAM"
text = "This is a streaming example with character timing information."

audio_chunks = []
timing_data = []

client.text_to_speech.stream_with_timestamps(voice_id, text) do |chunk|
  if chunk["audio_base64"]
    # Collect audio chunks
    audio_data = Base64.decode64(chunk["audio_base64"])
    audio_chunks << audio_data
    
    # Collect timing data
    if chunk["alignment"]
      timing_data << chunk["alignment"]
    end
    
    # Real-time processing
    puts "Received chunk with #{chunk["alignment"]["characters"].length} characters" if chunk["alignment"]
  end
end

# Combine all audio chunks
complete_audio = audio_chunks.join
File.open("streamed_output.mp3", "wb") { |f| f.write(complete_audio) }

puts "Streaming complete. Audio saved to streamed_output.mp3"
puts "Received #{timing_data.length} timing chunks"
```

### Karaoke-style Text Display

```ruby
require 'elevenlabs_client'

def display_karaoke(text, alignment)
  characters = alignment["characters"]
  start_times = alignment["character_start_times_seconds"]
  
  start_time = Time.now
  
  characters.each_with_index do |char, index|
    # Wait until it's time to highlight this character
    target_time = start_time + start_times[index]
    sleep_time = target_time - Time.now
    sleep(sleep_time) if sleep_time > 0
    
    # Display character with highlight
    print "\e[31m#{char}\e[0m"  # Red color for current character
    $stdout.flush
  end
  
  puts "\n"
end

client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

voice_id = "21m00Tcm4TlvDq8ikWAM"
text = "This text will be highlighted as it's spoken!"

response = client.text_to_speech.convert_with_timestamps(voice_id, text)

# Play audio (you would use your preferred audio library)
# play_audio(Base64.decode64(response["audio_base64"]))

# Display karaoke-style text
display_karaoke(text, response["alignment"])
```

## Error Handling

```ruby
begin
  response = client.text_to_speech.convert_with_timestamps(voice_id, text)
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid parameters: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Output Formats

Supported output formats include:

- `mp3_22050_32` - MP3 at 22.05kHz, 32kbps
- `mp3_44100_32` - MP3 at 44.1kHz, 32kbps  
- `mp3_44100_64` - MP3 at 44.1kHz, 64kbps
- `mp3_44100_96` - MP3 at 44.1kHz, 96kbps
- `mp3_44100_128` - MP3 at 44.1kHz, 128kbps (default)
- `mp3_44100_192` - MP3 at 44.1kHz, 192kbps (requires Creator tier+)
- `pcm_16000` - PCM at 16kHz
- `pcm_22050` - PCM at 22.05kHz
- `pcm_24000` - PCM at 24kHz
- `pcm_44100` - PCM at 44.1kHz (requires Pro tier+)
- `ulaw_8000` - μ-law at 8kHz (commonly used for Twilio)

## API Reference

For complete API documentation, visit: [ElevenLabs API Documentation](https://elevenlabs.io/docs/api-reference/text-to-speech)
