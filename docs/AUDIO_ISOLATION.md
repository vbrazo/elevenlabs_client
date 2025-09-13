# Audio Isolation

The Audio Isolation endpoint allows you to remove background noise from audio files, isolating vocals or speech from the audio content.

## Usage

### Basic Audio Isolation

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Open an audio file
audio_file = File.open("path/to/your/audio.mp3", "rb")

# Isolate audio (remove background noise)
isolated_audio = client.audio_isolation.isolate(audio_file, "audio.mp3")

# Save the isolated audio
File.open("isolated_audio.mp3", "wb") do |file|
  file.write(isolated_audio)
end

audio_file.close
```

### Audio Isolation with File Format Option

```ruby
# Specify the input file format for better performance
isolated_audio = client.audio_isolation.isolate(
  audio_file, 
  "audio.wav",
  file_format: "pcm_s16le_16"  # or "other" (default)
)
```

### Streaming Audio Isolation

For real-time processing or when you want to handle the audio data as it's processed:

```ruby
# Stream the isolated audio
client.audio_isolation.isolate_stream(audio_file, "audio.mp3") do |chunk|
  # Process each chunk of isolated audio as it arrives
  puts "Received chunk of size: #{chunk.length}"
  # You could write to a file, stream to a client, etc.
end
```

### Streaming with File Format

```ruby
client.audio_isolation.isolate_stream(
  audio_file, 
  "audio.wav",
  file_format: "pcm_s16le_16"
) do |chunk|
  # Handle streaming chunks
  process_audio_chunk(chunk)
end
```

## Parameters

### `isolate(audio_file, filename, **options)`

- **audio_file** (IO, File, required): The audio file from which vocals/speech will be isolated
- **filename** (String, required): Original filename for the audio file
- **options** (Hash, optional):
  - **file_format** (String): Format of input audio
    - `"pcm_s16le_16"`: 16-bit PCM at 16kHz sample rate, single channel (mono), little-endian byte order (lower latency)
    - `"other"`: Default format for other encoded waveforms

### `isolate_stream(audio_file, filename, **options, &block)`

Same parameters as `isolate`, plus:
- **block** (Proc, optional): Block to handle each chunk of streaming audio data

## File Format Options

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

## Error Handling

```ruby
begin
  isolated_audio = client.audio_isolation.isolate(audio_file, "audio.mp3")
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid audio file: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Common Use Cases

### Podcast Cleanup
```ruby
# Remove background noise from podcast recordings
podcast_file = File.open("podcast_raw.wav", "rb")
clean_audio = client.audio_isolation.isolate(podcast_file, "podcast_raw.wav")

File.open("podcast_clean.wav", "wb") { |f| f.write(clean_audio) }
podcast_file.close
```

### Voice Message Enhancement
```ruby
# Clean up voice messages
voice_message = File.open("voice_message.m4a", "rb")
enhanced_voice = client.audio_isolation.isolate(
  voice_message, 
  "voice_message.m4a",
  file_format: "other"
)

File.open("enhanced_voice.m4a", "wb") { |f| f.write(enhanced_voice) }
voice_message.close
```

### Real-time Audio Processing
```ruby
# Stream processing for real-time applications
audio_stream = File.open("live_recording.wav", "rb")

client.audio_isolation.isolate_stream(
  audio_stream, 
  "live_recording.wav",
  file_format: "pcm_s16le_16"
) do |chunk|
  # Send cleaned audio to real-time stream
  broadcast_clean_audio(chunk)
end

audio_stream.close
```

## Best Practices

1. **File Format Selection**:
   - Use `pcm_s16le_16` for real-time applications requiring low latency
   - Use `other` for general-purpose audio isolation with various formats

2. **File Size Considerations**:
   - The API can handle various file sizes
   - For very large files, consider using streaming isolation

3. **Quality Optimization**:
   - Higher quality input audio produces better isolation results
   - Mono audio is preferred for speech isolation

4. **Error Handling**:
   - Always implement proper error handling for network and API errors
   - Check file format compatibility before processing

## Response Format

The `isolate` method returns binary audio data as a String that can be written directly to a file or processed further.

The `isolate_stream` method yields chunks of binary audio data to the provided block for real-time processing.

## Rate Limits

Audio isolation requests are subject to API rate limits. Implement appropriate retry logic and respect rate limit headers in production applications.
