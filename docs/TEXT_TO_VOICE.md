# Text-to-Voice API

Design and create custom voices from text descriptions using ElevenLabs' advanced AI voice generation technology.

## Available Methods

- `client.text_to_voice.design(voice_description, **options)` - Design a voice from description
- `client.text_to_voice.create(voice_name, voice_description, generated_voice_id, **options)` - Create a voice from design
- `client.text_to_voice.stream_preview(generated_voice_id, &block)` - Stream a voice preview
- `client.text_to_voice.list_voices()` - List all available voices
- `client.text_to_voice.design_voice(voice_description, **options)` - Alias for design method
- `client.text_to_voice.create_from_generated_voice(...)` - Alias for create method
- `client.text_to_voice.stream_voice_preview(generated_voice_id, &block)` - Alias for stream_preview method

## Usage Examples

### Basic Voice Design

```ruby
# Design a voice from description
voice_description = "A warm, professional female voice with a slight British accent"

result = client.text_to_voice.design(voice_description)

# The result contains previews with generated voice IDs and audio samples
previews = result["previews"]
generated_voice_id = previews.first["generated_voice_id"]
audio_preview = previews.first["audio_base_64"]

puts "Generated voice ID: #{generated_voice_id}"
```

### Streaming Voice Preview

```ruby
# After designing a voice, you can stream the preview audio
voice_description = "Professional narrator voice with clear diction"
design_result = client.text_to_voice.design(voice_description)

generated_voice_id = design_result["previews"].first["generated_voice_id"]

# Stream the preview audio in real-time
audio_chunks = []
client.text_to_voice.stream_preview(generated_voice_id) do |chunk|
  audio_chunks << chunk
  puts "Received audio chunk: #{chunk.bytesize} bytes"
end

# Save the complete audio
File.open("voice_preview.mp3", "wb") do |file|
  file.write(audio_chunks.join)
end

# Using the alias method
client.text_to_voice.stream_voice_preview(generated_voice_id) do |chunk|
  # Process each audio chunk as it arrives
  play_audio_chunk(chunk)
end
```

### Advanced Voice Design

```ruby
# Design with custom options
result = client.text_to_voice.design(
  "Energetic sports commentator with American accent",
  model_id: "eleven_multilingual_ttv_v2",
  text: "And here comes the final play of the game! This is absolutely incredible!",
  auto_generate_text: false,
  loudness: 0.8,
  guidance_scale: 7.0,
  seed: 12345
)
```

### Voice Creation from Design

```ruby
# First, design a voice
design_result = client.text_to_voice.design(
  "Calm meditation instructor voice"
)

generated_voice_id = design_result["previews"].first["generated_voice_id"]

# Then create the voice
voice_result = client.text_to_voice.create(
  "Meditation Guide",
  "Calm meditation instructor voice",
  generated_voice_id,
  labels: {
    "use_case" => "meditation",
    "tone" => "calm",
    "accent" => "neutral"
  }
)

final_voice_id = voice_result["voice_id"]
puts "Created voice with ID: #{final_voice_id}"
```

### List Available Voices

```ruby
voices = client.text_to_voice.list_voices

voices["voices"].each do |voice|
  puts "#{voice['name']} (#{voice['voice_id']}) - #{voice['category']}"
end
```

## Design Options

### Required Parameters
- `voice_description` (String) - Description of the voice (20-1000 characters)

### Optional Parameters

#### Model Selection
- `model_id` (String) - Model to use:
  - `"eleven_multilingual_ttv_v2"` - Multilingual model v2
  - `"eleven_ttv_v3"` - Latest model with advanced features

#### Text Options
- `text` (String) - Custom text for preview (100-1000 characters)
- `auto_generate_text` (Boolean) - Auto-generate preview text (default: false)

#### Voice Characteristics
- `loudness` (Float) - Voice loudness (-1 to 1, default: 0.5)
- `quality` (Float) - Voice quality (-1 to 1, optional)

#### Generation Control
- `seed` (Integer) - Random seed for reproducible results (0 to 2147483647)
- `guidance_scale` (Float) - Generation guidance (0 to 100, default: 5)

#### Advanced Features (eleven_ttv_v3)
- `reference_audio_base64` (String) - Base64 encoded reference audio
- `prompt_strength` (Float) - Reference audio influence (0 to 1)

#### Output Options
- `output_format` (String) - Audio format (e.g., "mp3_44100_192")
- `stream_previews` (Boolean) - Enable streaming previews (default: false)

#### Remixing (Advanced)
- `remixing_session_id` (String) - Session ID for voice remixing
- `remixing_session_iteration_id` (String) - Iteration ID for remixing

## Create Options

### Required Parameters
- `voice_name` (String) - Name for the new voice
- `voice_description` (String) - Description of the voice (20-1000 characters)
- `generated_voice_id` (String) - ID from design preview

### Optional Parameters
- `labels` (Hash) - Metadata for voice organization
- `played_not_selected_voice_ids` (Array) - IDs of previews that were played but not selected

## Complete Workflow Example

```ruby
# Step 1: Design multiple voice options
design_result = client.text_to_voice.design(
  "Professional business presenter with confident tone",
  model_id: "eleven_multilingual_ttv_v2",
  auto_generate_text: true,
  loudness: 0.6,
  guidance_scale: 6.0
)

# Step 2: Review previews (in a real app, you'd let users listen)
previews = design_result["previews"]
selected_preview = previews.first
generated_voice_id = selected_preview["generated_voice_id"]

# Step 3: Create the final voice
voice_result = client.text_to_voice.create(
  "Business Presenter Pro",
  "Professional business presenter with confident tone",
  generated_voice_id,
  labels: {
    "use_case" => "business",
    "tone" => "confident",
    "industry" => "corporate"
  },
  played_not_selected_voice_ids: previews[1..-1].map { |p| p["generated_voice_id"] }
)

final_voice_id = voice_result["voice_id"]

# Step 4: Use the voice for text-to-speech
audio = client.text_to_speech.convert(
  final_voice_id,
  "Welcome to our quarterly business review presentation."
)
```

## Voice Categories

When listing voices, you'll see different categories:

- **`premade`** - Pre-built voices provided by ElevenLabs
- **`generated`** - Custom voices created via text-to-voice
- **`cloned`** - Voices cloned from audio samples
- **`professional`** - Professional voice actor recordings

## Rails Integration

```ruby
class VoiceDesignController < ApplicationController
  def design
    client = ElevenlabsClient.new
    
    result = client.text_to_voice.design(
      params[:voice_description],
      model_id: params[:model_id] || "eleven_multilingual_ttv_v2",
      auto_generate_text: params[:auto_generate_text] == 'true',
      loudness: params[:loudness]&.to_f || 0.5,
      guidance_scale: params[:guidance_scale]&.to_f || 5.0
    )
    
    render json: {
      previews: result["previews"].map do |preview|
        {
          generated_voice_id: preview["generated_voice_id"],
          audio_url: data_url_from_base64(preview["audio_base_64"]),
          text: preview["text"]
        }
      end
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def create_voice
    client = ElevenlabsClient.new
    
    result = client.text_to_voice.create(
      params[:voice_name],
      params[:voice_description],
      params[:generated_voice_id],
      labels: params[:labels] || {},
      played_not_selected_voice_ids: params[:played_not_selected_voice_ids] || []
    )
    
    render json: {
      voice_id: result["voice_id"],
      name: result["name"],
      message: "Voice created successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def list_voices
    client = ElevenlabsClient.new
    voices = client.text_to_voice.list_voices
    
    render json: {
      voices: voices["voices"].map do |voice|
        {
          voice_id: voice["voice_id"],
          name: voice["name"],
          category: voice["category"],
          labels: voice["labels"] || {}
        }
      end
    }
  end
  
  private
  
  def data_url_from_base64(base64_audio)
    "data:audio/mpeg;base64,#{base64_audio}"
  end
end
```

## Error Handling

```ruby
begin
  result = client.text_to_voice.design(voice_description)
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

## Best Practices

### Voice Description
1. **Be Specific** - Include accent, age, tone, and use case
2. **Length** - Keep descriptions between 20-1000 characters
3. **Examples**:
   - ❌ "Nice voice"
   - ✅ "Warm, professional female voice with slight British accent for corporate presentations"

### Model Selection
- Use `eleven_multilingual_ttv_v2` for general purposes
- Use `eleven_ttv_v3` for advanced features like reference audio

### Preview Management
- Always listen to multiple previews before creating
- Track `played_not_selected_voice_ids` for better recommendations

### Voice Organization
- Use meaningful `labels` for categorization
- Include use case, tone, accent, and other relevant metadata

### Performance
- Use `seed` parameter for consistent results during development
- Cache voice IDs to avoid repeated creation calls

## Use Cases

- **Content Creation** - Narrators, podcasters, audiobook voices
- **Business** - Corporate presentations, training materials
- **Gaming** - Character voices, NPCs, narration
- **Education** - Course instructors, language learning
- **Accessibility** - Screen readers, audio descriptions
- **Marketing** - Advertisement voices, promotional content

See [examples/text_to_voice_controller.rb](../examples/text_to_voice_controller.rb) for a complete Rails implementation with voice design workflow, preview management, and voice creation.
