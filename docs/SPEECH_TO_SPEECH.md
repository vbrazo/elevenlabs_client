# Speech-to-Speech (Voice Changer)

The Speech-to-Speech endpoint allows you to transform audio from one voice to another while maintaining full control over emotion, timing, and delivery. This is perfect for voice changing, voice cloning, and audio style transfer applications.

## Usage

### Basic Voice Conversion

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Open an audio file
audio_file = File.open("path/to/input_audio.mp3", "rb")
voice_id = "21m00Tcm4TlvDq8ikWAM"  # Target voice ID

# Convert speech to different voice
converted_audio = client.speech_to_speech.convert(voice_id, audio_file, "input_audio.mp3")

# Save the converted audio
File.open("converted_audio.mp3", "wb") do |file|
  file.write(converted_audio)
end

audio_file.close
```

### Voice Conversion with Options

```ruby
# Convert with full customization
converted_audio = client.speech_to_speech.convert(
  voice_id,
  audio_file,
  "input_audio.wav",
  model_id: "eleven_multilingual_sts_v2",
  output_format: "mp3_44100_128",
  enable_logging: false,
  remove_background_noise: true,
  file_format: "pcm_s16le_16",
  voice_settings: '{"stability": 0.7, "similarity_boost": 0.9}',
  seed: 12345
)
```

### Streaming Voice Conversion

For real-time processing or when you want to handle the audio data as it's processed:

```ruby
# Stream the converted audio
client.speech_to_speech.convert_stream(voice_id, audio_file, "input_audio.mp3") do |chunk|
  # Process each chunk of converted audio as it arrives
  puts "Received chunk of size: #{chunk.length}"
  # You could write to a file, stream to a client, etc.
end
```

### Streaming with Options

```ruby
client.speech_to_speech.convert_stream(
  voice_id,
  audio_file,
  "input_audio.wav",
  output_format: "mp3_22050_32",
  optimize_streaming_latency: 2,
  model_id: "eleven_multilingual_sts_v2",
  remove_background_noise: true
) do |chunk|
  # Handle streaming chunks
  process_audio_chunk(chunk)
end
```

## Methods

### `convert(voice_id, audio_file, filename, **options)`

Transforms audio from one voice to another.

**Parameters:**
- **voice_id** (String, required): ID of the target voice
- **audio_file** (IO, File, required): The source audio file
- **filename** (String, required): Original filename for the audio file
- **options** (Hash, optional):

**Query Parameters:**
- **enable_logging** (Boolean): Enable logging (default: true)
- **optimize_streaming_latency** (Integer): Latency optimization level (0-4, deprecated)
- **output_format** (String): Output format (default: "mp3_44100_128")

**Form Parameters:**
- **model_id** (String): Model identifier (default: "eleven_english_sts_v2")
- **voice_settings** (String): JSON encoded voice settings
- **seed** (Integer): Deterministic sampling seed (0-4294967295)
- **remove_background_noise** (Boolean): Remove background noise (default: false)
- **file_format** (String): Input file format ("pcm_s16le_16" or "other")

**Returns:** Binary audio data as String

### `convert_stream(voice_id, audio_file, filename, **options, &block)`

Same parameters as `convert`, plus:
- **block** (Proc, optional): Block to handle each chunk of streaming audio data

**Returns:** Faraday::Response for streaming

## Output Formats

The `output_format` parameter supports various audio formats:

### Common Formats
- `"mp3_44100_128"` - MP3, 44.1kHz, 128kbps (default)
- `"mp3_44100_192"` - MP3, 44.1kHz, 192kbps (requires Creator tier+)
- `"mp3_22050_32"` - MP3, 22.05kHz, 32kbps
- `"pcm_44100"` - PCM, 44.1kHz (requires Pro tier+)
- `"pcm_22050"` - PCM, 22.05kHz
- `"pcm_16000"` - PCM, 16kHz
- `"pcm_8000"` - PCM, 8kHz
- `"ulaw_8000"` - μ-law, 8kHz (for Twilio)

### Format Structure
Formats follow the pattern: `codec_sample_rate_bitrate`
- **codec**: mp3, pcm, ulaw
- **sample_rate**: 8000, 16000, 22050, 44100
- **bitrate**: 32, 64, 128, 192 (for MP3 only)

## Input File Formats

### PCM Format (`pcm_s16le_16`)
- **Sample Rate**: 16kHz
- **Bit Depth**: 16-bit
- **Channels**: Single channel (mono)
- **Byte Order**: Little-endian
- **Advantage**: Lower latency processing

### Other Format (`other`)
- **Default**: Used for all other audio formats
- **Supports**: MP3, WAV, FLAC, M4A, and other common audio formats
- **Processing**: Higher latency but supports more formats

## Voice Settings

Voice settings can be provided as a JSON string to fine-tune the output:

```ruby
voice_settings = {
  stability: 0.7,           # 0.0 to 1.0 - Voice consistency
  similarity_boost: 0.9,    # 0.0 to 1.0 - Voice similarity to original
  style: 0.2,              # 0.0 to 1.0 - Style exaggeration
  use_speaker_boost: true   # Boolean - Enhance speaker characteristics
}.to_json

converted_audio = client.speech_to_speech.convert(
  voice_id,
  audio_file,
  filename,
  voice_settings: voice_settings
)
```

## Models

### Available Models
- `"eleven_english_sts_v2"` - English Speech-to-Speech v2 (default)
- `"eleven_multilingual_sts_v2"` - Multilingual Speech-to-Speech v2
- `"eleven_turbo_v2_5"` - Turbo model for faster processing

Check model capabilities using the Models endpoint to ensure speech-to-speech support.

## Latency Optimization (Deprecated)

The `optimize_streaming_latency` parameter offers different latency levels:

- `0` - Default mode (no optimizations)
- `1` - Normal optimizations (~50% improvement)
- `2` - Strong optimizations (~75% improvement)
- `3` - Maximum optimizations
- `4` - Maximum + text normalizer off (best latency, may affect quality)

## Error Handling

```ruby
begin
  converted_audio = client.speech_to_speech.convert(voice_id, audio_file, filename)
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid audio file or parameters: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Common Use Cases

### Voice Cloning
```ruby
# Clone a voice from one recording to another
source_audio = File.open("source_voice.wav", "rb")
target_voice_id = "cloned_voice_id"

cloned_audio = client.speech_to_speech.convert(
  target_voice_id,
  source_audio,
  "source_voice.wav",
  model_id: "eleven_multilingual_sts_v2",
  voice_settings: '{"stability": 0.8, "similarity_boost": 0.9}',
  remove_background_noise: true
)

File.open("cloned_voice.wav", "wb") { |f| f.write(cloned_audio) }
source_audio.close
```

### Real-time Voice Changing
```ruby
# Stream processing for real-time applications
input_stream = File.open("live_audio.wav", "rb")

client.speech_to_speech.convert_stream(
  voice_id,
  input_stream,
  "live_audio.wav",
  output_format: "pcm_16000",
  file_format: "pcm_s16le_16",
  optimize_streaming_latency: 3
) do |chunk|
  # Send converted audio to real-time stream
  broadcast_converted_audio(chunk)
end

input_stream.close
```

### Podcast Voice Enhancement
```ruby
# Enhance podcast audio with different voice
podcast_audio = File.open("podcast_raw.mp3", "rb")

enhanced_audio = client.speech_to_speech.convert(
  professional_voice_id,
  podcast_audio,
  "podcast_raw.mp3",
  model_id: "eleven_english_sts_v2",
  output_format: "mp3_44100_192",
  remove_background_noise: true,
  voice_settings: '{"stability": 0.9, "similarity_boost": 0.7, "style": 0.1}'
)

File.open("podcast_enhanced.mp3", "wb") { |f| f.write(enhanced_audio) }
podcast_audio.close
```

### Multilingual Voice Transfer
```ruby
# Transfer voice characteristics across languages
foreign_audio = File.open("spanish_speech.wav", "rb")

english_voice_audio = client.speech_to_speech.convert(
  english_voice_id,
  foreign_audio,
  "spanish_speech.wav",
  model_id: "eleven_multilingual_sts_v2",
  voice_settings: '{"stability": 0.6, "similarity_boost": 0.8}'
)

File.open("english_voice_spanish_content.wav", "wb") { |f| f.write(english_voice_audio) }
foreign_audio.close
```

## Alias Methods

For convenience, the following alias methods are available:

```ruby
# Aliases for convert
client.speech_to_speech.voice_changer(voice_id, audio_file, filename, **options)

# Aliases for convert_stream
client.speech_to_speech.voice_changer_stream(voice_id, audio_file, filename, **options, &block)
```

## Best Practices

1. **Audio Quality**:
   - Use high-quality source audio for better results
   - Consider using `remove_background_noise: true` for noisy inputs
   - Match input format to expected quality (PCM for best results)

2. **Voice Selection**:
   - Choose target voices that match the content style
   - Test different voice settings for optimal results
   - Use voices from the same language family when possible

3. **Performance Optimization**:
   - Use `file_format: "pcm_s16le_16"` for lower latency
   - Choose appropriate output format for your use case
   - Consider streaming for real-time applications

4. **Deterministic Results**:
   - Use `seed` parameter for reproducible results
   - Keep voice settings consistent for similar outputs

5. **Error Handling**:
   - Always implement proper error handling
   - Check voice availability before processing
   - Validate audio file format and size

## Response Format

The `convert` method returns binary audio data as a String that can be written directly to a file or processed further.

The `convert_stream` method yields chunks of binary audio data to the provided block for real-time processing.

## Rate Limits

Speech-to-speech requests are subject to API rate limits. The processing time depends on audio file size, complexity, and chosen model. Implement appropriate retry logic and respect rate limit headers in production applications.

## Subscription Requirements

- **MP3 192kbps**: Requires Creator tier or above
- **PCM 44.1kHz**: Requires Pro tier or above
- **Background noise removal**: Available on all tiers
- **Streaming**: Available on all tiers