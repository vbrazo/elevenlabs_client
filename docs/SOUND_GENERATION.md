# Sound Generation API

Generate custom sound effects and ambient audio from text descriptions using ElevenLabs' AI sound generation.

## Available Methods

- `client.sound_generation.generate(text, **options)` - Generate sound effects from text prompts
- `client.sound_generation.sound_generation(text, **options)` - Alias for generate method

## Usage Examples

### Basic Sound Generation

```ruby
# Generate a simple sound effect
audio_data = client.sound_generation.generate("Ocean waves crashing on rocks")

# Save the sound effect to a file
File.open("ocean_waves.mp3", "wb") do |file|
  file.write(audio_data)
end
```

### Advanced Sound Generation

```ruby
# Generate a looping sound effect
audio_data = client.sound_generation.generate(
  "Gentle rain falling on leaves",
  loop: true,
  duration_seconds: 30.0
)

# Generate with specific duration and prompt influence
audio_data = client.sound_generation.generate(
  "Crackling fireplace",
  duration_seconds: 15.0,
  prompt_influence: 0.7
)

# Generate with custom output format
audio_data = client.sound_generation.generate(
  "Birds chirping in a forest",
  output_format: "mp3_22050_32"
)

# Complete example with all options
audio_data = client.sound_generation.generate(
  "Ambient coffee shop with gentle chatter",
  loop: true,
  duration_seconds: 60.0,
  prompt_influence: 0.5,
  output_format: "mp3_44100_128"
)
```

## Available Options

- `loop` (Boolean) - Whether to create a looping sound effect (default: false)
- `duration_seconds` (Float) - Duration in seconds (0.5 to 30, default: auto-detection)
- `prompt_influence` (Float) - How closely to follow the prompt (0.0 to 1.0, default: 0.3)
- `output_format` (String) - Audio format (e.g., "mp3_44100_128", "mp3_22050_32", "pcm_16000")

## Sound Categories

### Nature Sounds

```ruby
nature_sounds = [
  "Gentle rain on leaves",
  "Ocean waves on beach", 
  "Wind through trees",
  "Thunder in distance",
  "Babbling brook",
  "Birds singing at dawn"
]

nature_sounds.each do |sound|
  audio_data = client.sound_generation.generate(
    sound,
    loop: true,
    duration_seconds: 30.0,
    prompt_influence: 0.6
  )
  
  filename = sound.gsub(/\s+/, '_').downcase + ".mp3"
  File.open(filename, "wb") { |f| f.write(audio_data) }
end
```

### Ambient Environments

```ruby
ambient_sounds = {
  "cafe" => "Busy coffee shop with gentle chatter and espresso sounds",
  "library" => "Quiet library with occasional page turning and whispers",
  "office" => "Modern office with keyboard typing and quiet conversations",
  "city" => "Urban street with distant traffic and pedestrian sounds"
}

ambient_sounds.each do |name, description|
  audio_data = client.sound_generation.generate(
    description,
    loop: true,
    duration_seconds: 60.0,
    prompt_influence: 0.5
  )
  
  File.open("ambient_#{name}.mp3", "wb") { |f| f.write(audio_data) }
end
```

### UI Sound Effects

```ruby
ui_sounds = {
  "notification" => "Gentle notification chime",
  "success" => "Positive success sound",
  "error" => "Subtle error indication",
  "click" => "Clean button click",
  "whoosh" => "Smooth transition sound",
  "pop" => "Light pop sound"
}

ui_sounds.each do |name, prompt|
  audio_data = client.sound_generation.generate(
    prompt,
    loop: false,
    duration_seconds: 1.0,
    prompt_influence: 0.8  # Higher influence for precise UI sounds
  )
  
  File.open("ui_#{name}.mp3", "wb") { |f| f.write(audio_data) }
end
```

## Output Formats

- `mp3_44100_128` - High quality MP3 (default)
- `mp3_22050_32` - Lower quality MP3 (smaller file size)
- `pcm_16000` - PCM audio at 16kHz
- `pcm_24000` - PCM audio at 24kHz

## Rails Integration

### Basic Controller

```ruby
class SoundGenerationController < ApplicationController
  def create
    client = ElevenlabsClient.new
    
    audio_data = client.sound_generation.generate(
      params[:text],
      loop: params[:loop] == 'true',
      duration_seconds: params[:duration_seconds]&.to_f,
      prompt_influence: params[:prompt_influence]&.to_f || 0.3
    )
    
    send_data audio_data,
              type: 'audio/mpeg',
              filename: 'sound_effect.mp3',
              disposition: 'attachment'
              
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
end
```

### Specialized Endpoints

```ruby
# Nature sounds endpoint
def nature_sounds
  sound_prompts = {
    'rain' => 'Gentle rain falling on leaves',
    'ocean' => 'Ocean waves on shore',
    'forest' => 'Birds chirping in forest'
  }
  
  prompt = sound_prompts[params[:type]]
  return render json: { error: 'Invalid sound type' }, status: :bad_request unless prompt
  
  audio_data = client.sound_generation.generate(
    prompt,
    loop: true,
    duration_seconds: params[:duration]&.to_f || 30.0,
    prompt_influence: 0.6
  )
  
  send_data audio_data, type: 'audio/mpeg', filename: "nature_#{params[:type]}.mp3"
end
```

## Error Handling

```ruby
begin
  audio_data = client.sound_generation.generate(text)
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid parameters: #{e.message}"
end
```

## Best Practices

1. **Prompt Quality** - Be descriptive and specific in your text prompts
2. **Duration** - Use appropriate durations (short for UI sounds, longer for ambient)
3. **Looping** - Enable looping for background/ambient sounds
4. **Prompt Influence** - Higher values (0.7-0.8) for precise sounds, lower (0.3-0.5) for creative interpretation
5. **Format Selection** - Use MP3 for general use, PCM for real-time processing

## Use Cases

- **Game Development** - Sound effects, ambient audio, UI sounds
- **App Development** - Notification sounds, interaction feedback
- **Content Creation** - Podcast intros, background music, sound effects
- **Accessibility** - Audio cues, environmental audio descriptions
- **Meditation Apps** - Nature sounds, ambient environments
- **Educational Content** - Sound illustrations, audio examples

See [examples/sound_generation_controller.rb](../examples/sound_generation_controller.rb) for a complete implementation with nature sounds, ambient environments, UI effects, and batch processing.
