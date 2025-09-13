# Text-to-Dialogue API

Convert dialogue scripts with multiple speakers into natural-sounding conversations using different voices.

## Available Methods

- `client.text_to_dialogue.convert(inputs, **options)` - Convert dialogue inputs to speech
- `client.text_to_dialogue.text_to_dialogue(inputs, **options)` - Alias for convert method

## Usage Examples

### Basic Dialogue Conversion

```ruby
dialogue_inputs = [
  { text: "Hello, how are you today?", voice_id: "21m00Tcm4TlvDq8ikWAM" },
  { text: "I'm doing great, thank you for asking!", voice_id: "pNInz6obpgDQGcFmaJgB" },
  { text: "That's wonderful to hear.", voice_id: "21m00Tcm4TlvDq8ikWAM" }
]

audio_data = client.text_to_dialogue.convert(dialogue_inputs)

# Save the dialogue audio to a file
File.open("dialogue.mp3", "wb") do |file|
  file.write(audio_data)
end
```

### Advanced Dialogue Options

```ruby
# With model specification
audio_data = client.text_to_dialogue.convert(
  dialogue_inputs,
  model_id: "eleven_multilingual_v1"
)

# With dialogue settings
audio_data = client.text_to_dialogue.convert(
  dialogue_inputs,
  settings: {
    stability: 0.7,
    use_speaker_boost: true
  }
)

# With deterministic seed for consistent results
audio_data = client.text_to_dialogue.convert(
  dialogue_inputs,
  seed: 12345
)

# Complete example with all options
conversation = [
  { text: "Welcome to our customer service.", voice_id: "agent_voice_id" },
  { text: "Hi, I need help with my order.", voice_id: "customer_voice_id" },
  { text: "I'd be happy to help you with that.", voice_id: "agent_voice_id" }
]

audio_data = client.text_to_dialogue.convert(
  conversation,
  model_id: "eleven_multilingual_v1",
  settings: {
    stability: 0.6,
    use_speaker_boost: false
  },
  seed: 98765
)
```

## Available Options

- `model_id` - Model to use for generation
- `settings` - Dialogue generation settings
  - `stability` (0.0-1.0) - Voice stability across dialogue
  - `use_speaker_boost` (Boolean) - Enhance speaker characteristics
- `seed` (Integer) - Deterministic seed for consistent results

## Use Cases

### Customer Service Training

```ruby
customer_service_dialogue = [
  { text: "Thank you for calling. How can I help you?", voice_id: "agent_voice" },
  { text: "I have a problem with my recent order.", voice_id: "customer_voice" },
  { text: "I'm sorry to hear that. Let me look into it for you.", voice_id: "agent_voice" },
  { text: "I appreciate your help.", voice_id: "customer_voice" }
]

training_audio = client.text_to_dialogue.convert(
  customer_service_dialogue,
  settings: { stability: 0.8, use_speaker_boost: true }
)
```

### Educational Content

```ruby
lesson_dialogue = [
  { text: "Today we'll learn about photosynthesis.", voice_id: "teacher_voice" },
  { text: "What is photosynthesis?", voice_id: "student_voice" },
  { text: "Great question! It's how plants make food from sunlight.", voice_id: "teacher_voice" }
]

lesson_audio = client.text_to_dialogue.convert(lesson_dialogue)
```

### Storytelling

```ruby
story_dialogue = [
  { text: "Once upon a time, in a faraway kingdom...", voice_id: "narrator_voice" },
  { text: "I must find the magical crystal!", voice_id: "hero_voice" },
  { text: "You'll never succeed!", voice_id: "villain_voice" },
  { text: "And so the adventure began...", voice_id: "narrator_voice" }
]

story_audio = client.text_to_dialogue.convert(story_dialogue, seed: 12345)
```

## Rails Integration

```ruby
class DialogueController < ApplicationController
  def create_conversation
    client = ElevenlabsClient.new
    
    dialogue_inputs = params[:dialogue].map do |input|
      {
        text: input[:text],
        voice_id: input[:voice_id]
      }
    end
    
    audio_data = client.text_to_dialogue.convert(
      dialogue_inputs,
      model_id: params[:model_id],
      settings: {
        stability: params[:stability]&.to_f || 0.5,
        use_speaker_boost: params[:use_speaker_boost] == 'true'
      }
    )
    
    send_data audio_data, 
              type: 'audio/mpeg', 
              filename: 'dialogue.mp3',
              disposition: 'attachment'
              
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: 'Invalid dialogue inputs', details: e.message }, status: :bad_request
  end
end
```

## Error Handling

```ruby
begin
  audio_data = client.text_to_dialogue.convert(dialogue_inputs)
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid dialogue format: #{e.message}"
end
```

## Best Practices

1. **Voice Selection** - Use distinct voices for different speakers
2. **Text Length** - Keep individual dialogue pieces reasonable (< 1000 chars)
3. **Consistency** - Use the same voice_id for the same character throughout
4. **Settings** - Use higher stability (0.7-0.8) for professional content
5. **Seeds** - Use consistent seeds for reproducible results

See [examples/text_to_dialogue_controller.rb](../examples/text_to_dialogue_controller.rb) for specialized endpoints including customer service, educational content, and storytelling implementations.
