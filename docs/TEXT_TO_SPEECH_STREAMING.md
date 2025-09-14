# Text-to-Speech Streaming API

Stream text-to-speech audio in real-time as it's generated, perfect for live applications and reducing latency.

## Available Methods

- `client.text_to_speech.stream(voice_id, text, **options) { |chunk| }` - Stream text-to-speech in real-time
- `client.text_to_speech.text_to_speech_stream(voice_id, text, **options) { |chunk| }` - Alias for stream method

## Usage Examples

### Basic Streaming

```ruby
voice_id = "21m00Tcm4TlvDq8ikWAM"
audio_chunks = []

client.text_to_speech.stream(voice_id, "Hello, this is streaming audio!") do |chunk|
  audio_chunks << chunk
  puts "Received chunk of size: #{chunk.bytesize} bytes"
end

# Save all chunks to a file
File.open("streaming_output.mp3", "wb") do |file|
  audio_chunks.each { |chunk| file.write(chunk) }
end
```

### Advanced Streaming Options

```ruby
# With custom model and output format
client.text_to_speech.stream(
  voice_id,
  "This uses a custom model and format.",
  model_id: "eleven_turbo_v2",
  output_format: "pcm_16000"
) do |chunk|
  # Process PCM audio chunk
  process_pcm_chunk(chunk)
end

# With voice settings
client.text_to_speech.stream(
  voice_id,
  "Custom voice settings for streaming.",
  voice_settings: {
    stability: 0.7,
    similarity_boost: 0.8
  }
) do |chunk|
  # Stream directly to response in Rails
  response.stream.write(chunk)
end
```

### Real-time Processing

```ruby
total_size = 0
start_time = Time.now

client.text_to_speech.stream(voice_id, "Real-time audio processing example.") do |chunk|
  total_size += chunk.bytesize
  elapsed = Time.now - start_time
  
  puts "Chunk: #{chunk.bytesize} bytes, Total: #{total_size} bytes, Time: #{elapsed.round(2)}s"
  
  # Could stream to WebSocket, save to file, or process in real-time
  websocket.send(chunk) if websocket&.open?
end
```

## Available Options

- `model_id` - Model to use (e.g., "eleven_turbo_v2")
- `output_format` - Audio format (e.g., "mp3_44100_128", "pcm_16000")
- `voice_settings` - Voice configuration hash

## Rails Streaming Controller

```ruby
class StreamingAudioController < ApplicationController
  include ActionController::Live

  def stream_text_to_speech
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Transfer-Encoding'] = 'chunked'
    
    client = ElevenlabsClient.new
    
    begin
      client.text_to_speech.stream(
        params[:voice_id],
        params[:text],
        model_id: params[:model_id] || "eleven_multilingual_v2"
      ) do |chunk|
        response.stream.write(chunk)
      end
    rescue IOError
      # Client disconnected
    ensure
      response.stream.close
    end
  end
end
```

## WebSocket Integration

```ruby
# Stream to WebSocket channel
client.text_to_speech.stream(voice_id, text) do |chunk|
  ActionCable.server.broadcast(
    "audio_stream_#{session_id}", 
    { type: 'audio_chunk', data: Base64.encode64(chunk) }
  )
end

# Signal completion
ActionCable.server.broadcast(
  "audio_stream_#{session_id}", 
  { type: 'stream_complete' }
)
```

## Error Handling

```ruby
begin
  client.text_to_speech.stream(voice_id, text) do |chunk|
    process_chunk(chunk)
  end
rescue ElevenlabsClient::AuthenticationError
  puts "Authentication failed"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue IOError
  puts "Client disconnected"
end
```

## Use Cases

- **Live Applications** - Real-time voice responses
- **Interactive Systems** - Chatbots, voice assistants
- **Streaming Services** - Audio content generation
- **Gaming** - Dynamic voice generation
- **Accessibility** - Real-time text reading

See [examples/streaming_audio_controller.rb](../examples/streaming_audio_controller.rb) for a complete implementation with WebSocket support, file saving, and error handling.
