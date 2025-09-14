# WebSocket Streaming Text-to-Speech

This document provides examples and documentation for ElevenLabs' WebSocket streaming functionality using the `elevenlabs_client` gem.

## Features

- Real-time text-to-speech streaming over WebSockets
- Single-context streaming for continuous audio generation
- Multi-context streaming for managing multiple independent audio streams
- Character-level alignment information with timing data
- Low-latency audio generation suitable for conversational AI

## Table of Contents

- [Single Context WebSocket Streaming](#single-context-websocket-streaming)
- [Multi-Context WebSocket Streaming](#multi-context-websocket-streaming)
- [Configuration Options](#configuration-options)
- [Message Types](#message-types)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Single Context WebSocket Streaming

The single-context WebSocket API allows for real-time text-to-speech generation where you can stream text input and receive audio output chunks with timing information.

### Basic Usage

```ruby
require 'elevenlabs_client'
require 'base64'

# Initialize the client
client = ElevenlabsClient::Client.new(api_key: "your-api-key")

voice_id = "21m00Tcm4TlvDq8ikWAM"

# Connect to WebSocket
ws = client.websocket_text_to_speech.connect_stream_input(
  voice_id,
  model_id: "eleven_multilingual_v2",
  output_format: "mp3_44100_128",
  sync_alignment: true
)

# Set up event handlers
ws.on :open do |event|
  puts "WebSocket connected"
  
  # Initialize connection
  client.websocket_text_to_speech.send_initialize_connection(
    ws,
    text: " ",  # Initial space
    voice_settings: {
      stability: 0.5,
      similarity_boost: 0.8
    }
  )
  
  # Send text chunks
  client.websocket_text_to_speech.send_text(ws, "Hello there! ")
  client.websocket_text_to_speech.send_text(ws, "How are you doing today? ")
  client.websocket_text_to_speech.send_text(ws, "This is streaming text-to-speech!", try_trigger_generation: true)
  
  # Close connection
  client.websocket_text_to_speech.send_close_connection(ws)
end

ws.on :message do |event|
  data = JSON.parse(event.data)
  
  if data['audio']
    # Decode and process audio
    audio_data = Base64.decode64(data['audio'])
    puts "Received audio chunk: #{audio_data.length} bytes"
    
    # Process timing information if available
    if data['alignment']
      characters = data['alignment']['chars']
      start_times = data['alignment']['charStartTimesMs']
      puts "Characters: #{characters.join('')}"
    end
  end
  
  if data['isFinal']
    puts "Final audio chunk received"
  end
end

ws.on :error do |event|
  puts "WebSocket error: #{event.message}"
end

ws.on :close do |event|
  puts "WebSocket closed"
end

# Keep the connection alive
sleep(10)
```

### Convenient Streaming Method

```ruby
# Use the convenient streaming method
voice_id = "21m00Tcm4TlvDq8ikWAM"
text_chunks = [
  "Hello there! ",
  "This is a streaming example. ",
  "Each chunk will be processed in real-time."
]

ws = client.websocket_text_to_speech.stream_text_to_speech(
  voice_id,
  text_chunks,
  voice_settings: { stability: 0.5, similarity_boost: 0.8 },
  sync_alignment: true
) do |audio_data, metadata|
  # Process each audio chunk
  puts "Received #{audio_data.length} bytes of audio"
  
  if metadata['alignment']
    puts "With timing for: #{metadata['alignment']['chars'].join('')}"
  end
end

# Keep connection alive
sleep(5)
```

## Multi-Context WebSocket Streaming

The multi-context WebSocket API allows you to manage multiple independent audio generation streams over a single WebSocket connection. This is useful for conversational AI applications where you need to handle multiple speakers or contexts.

### Basic Multi-Context Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
voice_id = "21m00Tcm4TlvDq8ikWAM"

# Connect to multi-context WebSocket
ws = client.websocket_text_to_speech.connect_multi_stream_input(
  voice_id,
  model_id: "eleven_multilingual_v2",
  sync_alignment: true
)

ws.on :open do |event|
  puts "Multi-context WebSocket connected"
  
  # Initialize first context
  client.websocket_text_to_speech.send_initialize_connection_multi(
    ws,
    "conversation_1",
    text: " ",
    voice_settings: { stability: 0.5, similarity_boost: 0.8 }
  )
  
  # Send text to first context
  client.websocket_text_to_speech.send_text_multi(
    ws,
    "conversation_1",
    "Hello from conversation one! "
  )
  
  # Initialize second context with different settings
  client.websocket_text_to_speech.send_initialize_connection_multi(
    ws,
    "conversation_2", 
    text: " ",
    voice_settings: { stability: 0.3, similarity_boost: 0.9 }
  )
  
  # Send text to second context
  client.websocket_text_to_speech.send_text_multi(
    ws,
    "conversation_2",
    "Hi there from conversation two! "
  )
  
  # Flush contexts to generate audio
  client.websocket_text_to_speech.send_flush_context(ws, "conversation_1")
  client.websocket_text_to_speech.send_flush_context(ws, "conversation_2")
end

ws.on :message do |event|
  data = JSON.parse(event.data)
  
  if data['audio']
    context_id = data['contextId']
    audio_data = Base64.decode64(data['audio'])
    
    puts "Received audio from #{context_id}: #{audio_data.length} bytes"
    
    # Process based on context
    case context_id
    when "conversation_1"
      # Handle audio from first conversation
      handle_conversation_1_audio(audio_data)
    when "conversation_2"
      # Handle audio from second conversation
      handle_conversation_2_audio(audio_data)
    end
  end
  
  if data['is_final']
    puts "Final chunk for context: #{data['contextId']}"
  end
end

ws.on :error do |event|
  puts "WebSocket error: #{event.message}"
end

# Keep connection alive
sleep(15)
```

### Advanced Multi-Context Example

```ruby
class MultiContextManager
  def initialize(client, voice_id)
    @client = client
    @voice_id = voice_id
    @contexts = {}
    @ws = nil
  end
  
  def connect
    @ws = @client.websocket_text_to_speech.connect_multi_stream_input(
      @voice_id,
      sync_alignment: true,
      auto_mode: true
    )
    
    setup_event_handlers
    @ws
  end
  
  def create_context(context_id, voice_settings = {})
    @contexts[context_id] = {
      voice_settings: voice_settings,
      buffer: []
    }
    
    @client.websocket_text_to_speech.send_initialize_connection_multi(
      @ws,
      context_id,
      voice_settings: voice_settings
    )
  end
  
  def send_text(context_id, text, flush: false)
    return unless @contexts[context_id]
    
    @client.websocket_text_to_speech.send_text_multi(
      @ws,
      context_id,
      text,
      flush: flush
    )
  end
  
  def flush_context(context_id)
    @client.websocket_text_to_speech.send_flush_context(@ws, context_id)
  end
  
  def close_context(context_id)
    @client.websocket_text_to_speech.send_close_context(@ws, context_id)
    @contexts.delete(context_id)
  end
  
  def close_all
    @client.websocket_text_to_speech.send_close_socket(@ws)
  end
  
  private
  
  def setup_event_handlers
    @ws.on :message do |event|
      data = JSON.parse(event.data)
      handle_audio_message(data)
    end
    
    @ws.on :error do |event|
      puts "WebSocket error: #{event.message}"
    end
  end
  
  def handle_audio_message(data)
    return unless data['audio']
    
    context_id = data['contextId']
    audio_data = Base64.decode64(data['audio'])
    
    # Store in context buffer
    @contexts[context_id][:buffer] << audio_data if @contexts[context_id]
    
    puts "Audio received for #{context_id}: #{audio_data.length} bytes"
    
    # Handle timing data
    if data['alignment']
      handle_timing_data(context_id, data['alignment'])
    end
  end
  
  def handle_timing_data(context_id, alignment)
    characters = alignment['chars']
    start_times = alignment['charStartTimesMs']
    
    puts "Timing for #{context_id}: #{characters.join('')}"
  end
end

# Usage
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
manager = MultiContextManager.new(client, "21m00Tcm4TlvDq8ikWAM")

manager.connect

# Create different contexts for different speakers
manager.create_context("speaker_1", { stability: 0.5, similarity_boost: 0.8 })
manager.create_context("speaker_2", { stability: 0.3, similarity_boost: 0.9 })

# Send text to different contexts
manager.send_text("speaker_1", "Hello, I'm speaker one. ")
manager.send_text("speaker_2", "And I'm speaker two! ")

# Flush to generate audio
manager.flush_context("speaker_1")
manager.flush_context("speaker_2")

sleep(10)
manager.close_all
```

## Configuration Options

### Connection Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `voice_id` | String | Voice ID for TTS | Required |
| `model_id` | String | Model identifier | nil |
| `language_code` | String | ISO 639-1 language code | nil |
| `enable_logging` | Boolean | Enable request logging | true |
| `enable_ssml_parsing` | Boolean | Enable SSML parsing | false |
| `output_format` | String | Audio output format | nil |
| `inactivity_timeout` | Integer | Timeout in seconds (max 180) | 20 |
| `sync_alignment` | Boolean | Include timing data | false |
| `auto_mode` | Boolean | Reduce latency mode | false |
| `apply_text_normalization` | String | Text normalization mode | "auto" |
| `seed` | Integer | Deterministic sampling seed | nil |

### Voice Settings

```ruby
voice_settings = {
  stability: 0.5,              # 0.0 to 1.0 - Lower values make speech more varied
  similarity_boost: 0.8,       # 0.0 to 1.0 - Higher values make voice more similar to original
  style: 0.5,                  # 0.0 to 1.0 - Style exaggeration
  use_speaker_boost: true,     # Boolean - Boost speaker characteristics
  speed: 1.0                   # Speed multiplier for single-context streams
}
```

## Message Types

### Send Messages (Client to Server)

#### Initialize Connection (Single Context)
```ruby
{
  text: " ",
  voice_settings: { stability: 0.5, similarity_boost: 0.8 },
  xi_api_key: "your-api-key"
}
```

#### Send Text (Single Context)
```ruby
{
  text: "Hello world!",
  try_trigger_generation: true  # Optional
}
```

#### Initialize Connection (Multi-Context)
```ruby
{
  text: " ",
  voice_settings: { stability: 0.5, similarity_boost: 0.8 },
  context_id: "conv_1"
}
```

#### Send Text (Multi-Context)
```ruby
{
  text: "Hello from conversation one!",
  context_id: "conv_1",
  flush: true  # Optional
}
```

#### Flush Context
```ruby
{
  context_id: "conv_1",
  flush: true
}
```

#### Close Context
```ruby
{
  context_id: "conv_1",
  close_context: true
}
```

#### Close Socket
```ruby
{
  close_socket: true
}
```

### Receive Messages (Server to Client)

#### Audio Output (Single Context)
```ruby
{
  audio: "base64_encoded_audio_data",
  isFinal: false,
  alignment: {
    chars: ["H", "e", "l", "l", "o"],
    charStartTimesMs: [0, 100, 200, 300, 400],
    charsDurationsMs: [100, 100, 100, 100, 100]
  },
  normalizedAlignment: {
    # Same structure as alignment
  }
}
```

#### Audio Output (Multi-Context)
```ruby
{
  audio: "base64_encoded_audio_data",
  is_final: false,
  contextId: "conv_1",
  alignment: {
    chars: ["H", "e", "l", "l", "o"],
    charStartTimesMs: [0, 100, 200, 300, 400],
    charsDurationsMs: [100, 100, 100, 100, 100]
  }
}
```

## Examples

### Real-time Conversation Handler

```ruby
class ConversationHandler
  def initialize(client, voice_id)
    @client = client
    @voice_id = voice_id
    @ws = nil
    @audio_buffer = []
  end
  
  def start_conversation
    @ws = @client.websocket_text_to_speech.connect_stream_input(
      @voice_id,
      sync_alignment: true,
      auto_mode: true
    )
    
    @ws.on :open do
      initialize_connection
    end
    
    @ws.on :message do |event|
      handle_message(JSON.parse(event.data))
    end
  end
  
  def speak(text)
    @client.websocket_text_to_speech.send_text(@ws, text, try_trigger_generation: true)
  end
  
  def stop_conversation
    @client.websocket_text_to_speech.send_close_connection(@ws)
  end
  
  private
  
  def initialize_connection
    @client.websocket_text_to_speech.send_initialize_connection(
      @ws,
      voice_settings: { stability: 0.4, similarity_boost: 0.9 }
    )
  end
  
  def handle_message(data)
    if data['audio']
      audio_data = Base64.decode64(data['audio'])
      @audio_buffer << audio_data
      
      # Play audio immediately for real-time conversation
      play_audio_chunk(audio_data)
      
      # Process timing data for lip sync or visualization
      if data['alignment']
        process_lip_sync(data['alignment'])
      end
    end
    
    if data['isFinal']
      puts "Finished speaking"
    end
  end
  
  def play_audio_chunk(audio_data)
    # Implement audio playback with your preferred library
    # For example, using ruby-audio or system calls
    puts "Playing #{audio_data.length} bytes of audio"
  end
  
  def process_lip_sync(alignment)
    # Process character timing for lip synchronization
    characters = alignment['chars']
    start_times = alignment['charStartTimesMs']
    
    characters.each_with_index do |char, index|
      puts "Character '#{char}' starts at #{start_times[index]}ms"
    end
  end
end

# Usage
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
conversation = ConversationHandler.new(client, "21m00Tcm4TlvDq8ikWAM")

conversation.start_conversation
sleep(1)  # Wait for connection

conversation.speak("Hello! How can I help you today?")
sleep(3)

conversation.speak("I'm here to assist with any questions you might have.")
sleep(5)

conversation.stop_conversation
```

### Interactive Chat Bot

```ruby
class ChatBot
  def initialize(client, voice_id)
    @client = client
    @voice_id = voice_id
    @contexts = {}
  end
  
  def start
    @ws = @client.websocket_text_to_speech.connect_multi_stream_input(
      @voice_id,
      sync_alignment: true
    )
    
    setup_handlers
    puts "ChatBot started. Type 'quit' to exit."
    
    # Create default context
    create_user_context("default")
    
    # Interactive loop
    loop do
      print "You: "
      input = gets.chomp
      break if input.downcase == 'quit'
      
      respond_to_user(input)
    end
    
    @client.websocket_text_to_speech.send_close_socket(@ws)
  end
  
  private
  
  def setup_handlers
    @ws.on :message do |event|
      data = JSON.parse(event.data)
      
      if data['audio']
        context_id = data['contextId']
        audio_data = Base64.decode64(data['audio'])
        
        puts "\n🔊 Bot speaking (#{context_id}): #{audio_data.length} bytes"
        
        # Here you would play the audio
        # play_audio(audio_data)
      end
    end
  end
  
  def create_user_context(context_id)
    @contexts[context_id] = true
    
    @client.websocket_text_to_speech.send_initialize_connection_multi(
      @ws,
      context_id,
      voice_settings: { stability: 0.5, similarity_boost: 0.8 }
    )
  end
  
  def respond_to_user(user_input)
    # Simple response generation (in practice, you'd use an LLM)
    response = generate_response(user_input)
    
    puts "Bot: #{response}"
    
    # Send to TTS
    @client.websocket_text_to_speech.send_text_multi(
      @ws,
      "default",
      response,
      flush: true
    )
  end
  
  def generate_response(input)
    responses = [
      "That's interesting! Tell me more about #{input}.",
      "I understand you mentioned #{input}. What would you like to know?",
      "#{input} is a great topic. How can I help you with that?",
      "Thanks for sharing about #{input}. What else is on your mind?"
    ]
    
    responses.sample
  end
end

# Usage
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
bot = ChatBot.new(client, "21m00Tcm4TlvDq8ikWAM")
bot.start
```

## Best Practices

### Performance Optimization

1. **Use Auto Mode**: Enable `auto_mode` for better latency when sending complete sentences or phrases.

```ruby
ws = client.websocket_text_to_speech.connect_stream_input(
  voice_id,
  auto_mode: true
)
```

2. **Optimal Text Chunking**: Send text in logical chunks (sentences or phrases) rather than character by character.

```ruby
# Good
send_text(ws, "Hello there! ")
send_text(ws, "How are you today? ")

# Avoid
text.each_char { |char| send_text(ws, char) }
```

3. **Manage Context Lifecycle**: Close contexts when they're no longer needed to free up resources.

```ruby
# Clean up contexts
send_close_context(ws, "conversation_1")
```

### Error Handling

```ruby
ws.on :error do |event|
  puts "WebSocket error: #{event.message}"
  
  # Implement reconnection logic
  reconnect_websocket
end

ws.on :close do |event|
  puts "WebSocket closed: Code #{event.code}, Reason: #{event.reason}"
  
  # Handle unexpected closures
  if event.code != 1000  # Normal closure
    schedule_reconnection
  end
end
```

### Memory Management

```ruby
# Limit buffer sizes for long-running applications
class AudioBuffer
  MAX_BUFFER_SIZE = 1000  # Maximum number of audio chunks
  
  def initialize
    @chunks = []
  end
  
  def add_chunk(audio_data)
    @chunks << audio_data
    @chunks.shift if @chunks.length > MAX_BUFFER_SIZE
  end
  
  def get_audio
    @chunks.join
  end
end
```

### Timing Synchronization

```ruby
def synchronize_audio_with_text(audio_data, alignment)
  characters = alignment['chars']
  start_times_ms = alignment['charStartTimesMs']
  
  # Calculate real-world timing
  audio_start_time = Time.now
  
  characters.each_with_index do |char, index|
    char_time = audio_start_time + (start_times_ms[index] / 1000.0)
    
    # Schedule character highlighting
    schedule_highlight(char, char_time)
  end
end
```

## Troubleshooting

### Common Issues

1. **Connection Timeouts**: Increase `inactivity_timeout` for longer pauses between text inputs.

2. **Audio Quality**: Adjust voice settings like `stability` and `similarity_boost` for better quality.

3. **Latency**: Use `auto_mode` and optimize text chunking for lower latency.

4. **Memory Usage**: Implement proper buffer management for long-running applications.

### Debug Mode

```ruby
# Enable detailed logging
ws = client.websocket_text_to_speech.connect_stream_input(
  voice_id,
  enable_logging: true
)

# Log all messages
ws.on :message do |event|
  puts "Received: #{event.data}"
end
```

For more information, visit the [ElevenLabs WebSocket Documentation](https://elevenlabs.io/docs/api-reference/websockets).
