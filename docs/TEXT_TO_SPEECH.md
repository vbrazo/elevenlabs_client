# Text-to-Speech API

Convert text into natural-sounding speech using ElevenLabs' advanced AI voices.

## Available Methods

- `client.text_to_speech.convert(voice_id, text, **options)` - Convert text to speech
- `client.text_to_speech.text_to_speech(voice_id, text, **options)` - Alias for convert method

## Usage Examples

### Basic Text-to-Speech

```ruby
voice_id = "21m00Tcm4TlvDq8ikWAM"  # Rachel voice
text = "Hello, welcome to our service!"

audio_data = client.text_to_speech.convert(voice_id, text)

# Save to file
File.open("welcome.mp3", "wb") do |file|
  file.write(audio_data)
end
```

### Advanced Options

```ruby
# With model specification
audio_data = client.text_to_speech.convert(
  voice_id,
  text,
  model_id: "eleven_multilingual_v1"
)

# With voice settings
audio_data = client.text_to_speech.convert(
  voice_id,
  text,
  voice_settings: {
    stability: 0.7,
    similarity_boost: 0.8,
    style: 0.2,
    use_speaker_boost: true
  }
)

# With streaming optimization
audio_data = client.text_to_speech.convert(
  voice_id,
  text,
  optimize_streaming: true
)
```

## Available Models

- `eleven_monolingual_v1` - English only, high quality
- `eleven_multilingual_v1` - Multiple languages supported
- `eleven_multilingual_v2` - Latest multilingual model
- `eleven_turbo_v2` - Fast generation, good quality

## Voice Settings

- `stability` (0.0-1.0) - Voice consistency (0.0 = Creative, 1.0 = Stable)
- `similarity_boost` (0.0-1.0) - Voice similarity to original
- `style` (0.0-1.0) - Style exaggeration
- `use_speaker_boost` (Boolean) - Enhance speaker characteristics

## Error Handling

```ruby
begin
  audio_data = client.text_to_speech.convert(voice_id, text)
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid parameters: #{e.message}"
end
```

## Rails Integration

```ruby
class TextToSpeechController < ApplicationController
  def create
    client = ElevenlabsClient.new
    
    audio_data = client.text_to_speech.convert(
      params[:voice_id],
      params[:text],
      voice_settings: {
        stability: params[:stability]&.to_f || 0.5,
        similarity_boost: params[:similarity_boost]&.to_f || 0.7
      }
    )
    
    send_data audio_data,
              type: 'audio/mpeg',
              filename: 'speech.mp3',
              disposition: 'attachment'
              
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
end
```

See [examples/text_to_speech_controller.rb](../examples/text_to_speech_controller.rb) for a complete implementation.
