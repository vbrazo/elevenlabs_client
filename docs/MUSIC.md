# Music API

Generate AI-powered music compositions using ElevenLabs' music generation models. Create everything from background tracks to full compositions with detailed control over style, structure, and output format.

## Available Methods

- `client.music.compose(options)` - Generate music from a text prompt
- `client.music.compose_stream(options, &block)` - Generate music with streaming audio
- `client.music.compose_detailed(options)` - Generate music with metadata and audio
- `client.music.create_plan(options)` - Create a composition plan for structured music

### Alias Methods
- `client.music.compose_music(options)` - Alias for compose
- `client.music.compose_music_stream(options, &block)` - Alias for compose_stream
- `client.music.compose_music_detailed(options)` - Alias for compose_detailed
- `client.music.create_music_plan(options)` - Alias for create_plan

## Usage Examples

### Basic Music Composition

```ruby
# Simple music generation from text prompt
audio_data = client.music.compose(
  prompt: "Create an upbeat electronic dance track with synthesizers and a driving beat"
)

# Save the audio to a file
File.open("dance_track.mp3", "wb") do |file|
  file.write(audio_data)
end

puts "Generated #{audio_data.bytesize} bytes of audio"
```

### Music with Specific Parameters

```ruby
# Generate music with detailed parameters
audio_data = client.music.compose(
  prompt: "Epic orchestral soundtrack for a fantasy movie scene",
  music_length_ms: 60000,  # 60 seconds
  model_id: "music_v1",
  output_format: "mp3_44100_192"
)

File.open("epic_soundtrack.mp3", "wb") { |f| f.write(audio_data) }
```

### Streaming Music Generation

```ruby
# Stream music as it's generated for real-time playback
audio_chunks = []

client.music.compose_stream(
  prompt: "Relaxing ambient music for meditation",
  music_length_ms: 120000,  # 2 minutes
  output_format: "mp3_44100_128"
) do |chunk|
  # Process each audio chunk as it arrives
  audio_chunks << chunk
  puts "Received chunk: #{chunk.bytesize} bytes"
  
  # You could play the chunk immediately or buffer it
  # AudioPlayer.play(chunk) # Example real-time playback
end

# Combine all chunks into final audio
final_audio = audio_chunks.join
File.open("meditation_music.mp3", "wb") { |f| f.write(final_audio) }
```

### Detailed Music Composition

```ruby
# Generate music with metadata and detailed response
response = client.music.compose_detailed(
  prompt: "Classical piano piece in the style of Chopin",
  music_length_ms: 180000,  # 3 minutes
  model_id: "music_v1"
)

# The response contains both metadata and audio in multipart format
# You'll need to parse the multipart response to extract:
# - JSON metadata (composition details, structure, etc.)
# - Binary audio data

puts "Received multipart response: #{response.length} bytes"
# Parse multipart response to extract metadata and audio separately
```

### Composition Planning

```ruby
# Create a structured composition plan first
plan = client.music.create_plan(
  prompt: "Create a plan for a 3-minute pop song with verse, chorus, and bridge",
  music_length_ms: 180000
)

puts "Composition Plan:"
puts "ID: #{plan['composition_plan_id']}"
puts "Total Duration: #{plan['total_duration_ms']}ms"

plan['sections'].each do |section|
  puts "- #{section['name']}: #{section['duration_ms']}ms at #{section['tempo']} BPM"
end

# Use the plan to generate structured music
structured_audio = client.music.compose(
  prompt: "Pop song with catchy melody and modern production",
  composition_plan: plan['sections'],
  music_length_ms: plan['total_duration_ms']
)

File.open("structured_pop_song.mp3", "wb") { |f| f.write(structured_audio) }
```

### Advanced Composition with Custom Structure

```ruby
# Define a custom composition structure
custom_plan = {
  "sections" => [
    {
      "name" => "intro",
      "duration_ms" => 8000,
      "tempo" => 80,
      "key" => "C major",
      "instruments" => ["piano", "strings"]
    },
    {
      "name" => "main_theme",
      "duration_ms" => 32000,
      "tempo" => 120,
      "key" => "C major",
      "instruments" => ["full_orchestra"]
    },
    {
      "name" => "climax",
      "duration_ms" => 16000,
      "tempo" => 140,
      "key" => "D major",
      "instruments" => ["full_orchestra", "choir"]
    },
    {
      "name" => "outro",
      "duration_ms" => 12000,
      "tempo" => 90,
      "key" => "C major",
      "instruments" => ["piano", "strings"]
    }
  ]
}

# Generate music using the custom structure
orchestral_piece = client.music.compose(
  prompt: "Epic orchestral piece with dramatic crescendo",
  composition_plan: custom_plan["sections"],
  music_length_ms: 68000  # Total of all sections
)

File.open("custom_orchestral.mp3", "wb") { |f| f.write(orchestral_piece) }
```

## Music Generation Parameters

### Core Parameters

- **`prompt`** (String, required) - Text description of the desired music
  - Be specific about genre, mood, instruments, and style
  - Examples: "Upbeat jazz with saxophone", "Dark ambient electronic music"

- **`model_id`** (String, optional) - Music generation model to use
  - Default: `"music_v1"`
  - Available models may include: `"music_v1"`, `"music_v2"`

- **`music_length_ms`** (Integer, optional) - Duration in milliseconds
  - Range: 5000ms (5 seconds) to 300000ms (5 minutes)
  - Default: Model-determined based on prompt

- **`output_format`** (String, optional) - Audio output format
  - Examples: `"mp3_44100_128"`, `"mp3_44100_192"`, `"wav_44100"`
  - Default: `"mp3_44100_128"`

### Composition Plan Structure

When creating or using composition plans, each section can include:

```ruby
{
  "name" => "section_name",           # String: Section identifier
  "duration_ms" => 15000,             # Integer: Section length in milliseconds
  "tempo" => 120,                     # Integer: BPM (beats per minute)
  "key" => "C major",                 # String: Musical key
  "instruments" => ["piano", "drums"], # Array: Instruments to feature
  "mood" => "energetic",              # String: Emotional tone
  "dynamics" => "forte"               # String: Volume/intensity level
}
```

## Music Styles and Genres

### Supported Genres

The music generation supports a wide variety of genres:

**Electronic:**
- EDM, House, Techno, Trance, Dubstep
- Ambient, Chillout, Downtempo
- Synthwave, Retrowave, Cyberpunk

**Orchestral:**
- Classical, Romantic, Baroque
- Film Score, Epic Orchestral
- Chamber Music, String Quartet

**Popular:**
- Pop, Rock, Alternative
- Hip-Hop, R&B, Funk
- Country, Folk, Indie

**Jazz & Blues:**
- Traditional Jazz, Smooth Jazz
- Blues, Soul, Gospel
- Fusion, Bebop

**World Music:**
- Celtic, Medieval, Renaissance
- World Fusion, Ethnic
- New Age, Meditation

### Mood and Atmosphere

Specify emotional qualities in your prompts:

- **Energy Levels:** Calm, Relaxed, Moderate, Energetic, Intense
- **Emotions:** Happy, Sad, Mysterious, Dramatic, Peaceful, Aggressive
- **Atmospheres:** Dark, Bright, Ethereal, Gritty, Polished, Raw

### Instrumentation

Be specific about instruments you want featured:

**Orchestral:** Strings, Brass, Woodwinds, Percussion, Harp, Piano
**Electronic:** Synthesizers, Drum Machines, Samples, Effects
**Band:** Guitar, Bass, Drums, Vocals, Keyboards
**Solo:** Piano, Guitar, Violin, Saxophone, etc.

## Rails Integration

```ruby
class MusicController < ApplicationController
  def generate
    prompt = params[:prompt]
    duration = params[:duration_ms]&.to_i || 30000
    
    begin
      client = ElevenlabsClient.new
      
      audio_data = client.music.compose(
        prompt: prompt,
        music_length_ms: duration,
        output_format: "mp3_44100_128"
      )
      
      # Send audio directly to client
      send_data audio_data,
                type: "audio/mpeg",
                filename: "generated_music.mp3",
                disposition: "attachment"
                
    rescue ElevenlabsClient::BadRequestError => e
      render json: { error: "Invalid parameters: #{e.message}" }, status: :bad_request
    rescue ElevenlabsClient::RateLimitError => e
      render json: { error: "Rate limit exceeded. Please try again later." }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: { error: "Music generation failed: #{e.message}" }, status: :service_unavailable
    end
  end
  
  def stream_generate
    prompt = params[:prompt]
    
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    
    client = ElevenlabsClient.new
    
    client.music.compose_stream(
      prompt: prompt,
      music_length_ms: 60000
    ) do |chunk|
      # Stream each chunk to the client
      response.stream.write(chunk)
    end
    
  ensure
    response.stream.close
  end
  
  def create_composition
    plan_params = params.require(:composition).permit(:prompt, :duration_ms, sections: [])
    
    client = ElevenlabsClient.new
    
    # Create composition plan
    plan = client.music.create_plan(
      prompt: plan_params[:prompt],
      music_length_ms: plan_params[:duration_ms]
    )
    
    # Generate music using the plan
    audio_data = client.music.compose(
      prompt: plan_params[:prompt],
      composition_plan: plan["sections"],
      music_length_ms: plan["total_duration_ms"]
    )
    
    # Store composition metadata and audio
    composition = Composition.create!(
      prompt: plan_params[:prompt],
      plan_data: plan,
      audio_data: audio_data,
      duration_ms: plan["total_duration_ms"]
    )
    
    render json: {
      composition_id: composition.id,
      plan: plan,
      audio_url: composition_audio_path(composition)
    }
  end
end
```

## Advanced Use Cases

### Interactive Music Generation

```ruby
class InteractiveMusicGenerator
  def initialize
    @client = ElevenlabsClient.new
  end
  
  def generate_adaptive_music(base_prompt, user_preferences)
    # Create base composition plan
    plan = @client.music.create_plan(
      prompt: base_prompt,
      music_length_ms: 120000
    )
    
    # Modify plan based on user preferences
    adapted_plan = adapt_plan_to_preferences(plan, user_preferences)
    
    # Generate final music
    @client.music.compose(
      prompt: enhance_prompt_with_preferences(base_prompt, user_preferences),
      composition_plan: adapted_plan["sections"],
      music_length_ms: adapted_plan["total_duration_ms"]
    )
  end
  
  private
  
  def adapt_plan_to_preferences(plan, preferences)
    plan["sections"].each do |section|
      section["tempo"] = adjust_tempo(section["tempo"], preferences[:energy_level])
      section["instruments"] = filter_instruments(section["instruments"], preferences[:instrument_preference])
    end
    plan
  end
  
  def enhance_prompt_with_preferences(base_prompt, preferences)
    enhancements = []
    enhancements << "with #{preferences[:mood]} mood" if preferences[:mood]
    enhancements << "featuring #{preferences[:instruments].join(', ')}" if preferences[:instruments]
    enhancements << "at #{preferences[:tempo]} tempo" if preferences[:tempo]
    
    [base_prompt, *enhancements].join(" ")
  end
end
```

### Music Library Management

```ruby
class MusicLibraryService
  def initialize
    @client = ElevenlabsClient.new
  end
  
  def generate_music_collection(theme, count: 5)
    variations = [
      "upbeat and energetic",
      "calm and relaxing", 
      "dramatic and intense",
      "mysterious and atmospheric",
      "happy and uplifting"
    ]
    
    music_collection = []
    
    variations.first(count).each_with_index do |mood, index|
      prompt = "#{theme} music that is #{mood}"
      
      audio_data = @client.music.compose(
        prompt: prompt,
        music_length_ms: 45000,  # 45 seconds each
        output_format: "mp3_44100_192"
      )
      
      filename = "#{theme.downcase.gsub(' ', '_')}_#{mood.downcase.gsub(' ', '_')}.mp3"
      
      music_collection << {
        filename: filename,
        prompt: prompt,
        mood: mood,
        audio_data: audio_data,
        duration_ms: 45000
      }
      
      # Save to file
      File.open("music_library/#{filename}", "wb") { |f| f.write(audio_data) }
      
      puts "Generated: #{filename}"
    end
    
    music_collection
  end
end

# Usage
service = MusicLibraryService.new
collection = service.generate_music_collection("Fantasy Adventure", count: 3)
```

### Real-time Music Streaming

```ruby
class LiveMusicStreamer
  def initialize
    @client = ElevenlabsClient.new
  end
  
  def stream_continuous_music(prompts, &audio_handler)
    prompts.each do |prompt_config|
      puts "Generating: #{prompt_config[:prompt]}"
      
      @client.music.compose_stream(
        prompt: prompt_config[:prompt],
        music_length_ms: prompt_config[:duration] || 30000,
        output_format: "mp3_22050_64"  # Lower quality for streaming
      ) do |chunk|
        # Handle each audio chunk
        audio_handler.call(chunk, prompt_config) if audio_handler
        
        # Could also broadcast to multiple listeners
        # WebSocket.broadcast(chunk)
        # AudioStream.push(chunk)
      end
      
      # Brief pause between tracks
      sleep(0.5)
    end
  end
end

# Usage
streamer = LiveMusicStreamer.new
playlist = [
  { prompt: "Energetic workout music", duration: 45000 },
  { prompt: "Relaxing cool-down music", duration: 30000 },
  { prompt: "Motivational finale", duration: 20000 }
]

streamer.stream_continuous_music(playlist) do |chunk, config|
  puts "Streaming #{config[:prompt]}: #{chunk.bytesize} bytes"
  # Process audio chunk (play, save, broadcast, etc.)
end
```

## Best Practices

### Prompt Writing

1. **Be Specific:** Include genre, mood, instruments, and tempo
   - Good: "Upbeat jazz with saxophone and piano at 120 BPM"
   - Avoid: "Nice music"

2. **Use Musical Terms:** Leverage music terminology for better results
   - Tempo: Allegro, Andante, Presto
   - Dynamics: Forte, Piano, Crescendo
   - Styles: Legato, Staccato, Syncopated

3. **Reference Styles:** Mention specific artists or eras when appropriate
   - "In the style of 1980s synthwave"
   - "Classical baroque composition like Bach"

### Performance Optimization

1. **Choose Appropriate Formats:**
   - High quality: `mp3_44100_192` or `wav_44100`
   - Streaming: `mp3_22050_64` or `mp3_44100_128`
   - Storage efficient: `mp3_44100_128`

2. **Manage Duration:**
   - Shorter pieces (15-60 seconds) generate faster
   - Longer pieces (2-5 minutes) provide more musical development
   - Consider splitting long compositions into movements

3. **Use Streaming for Long Pieces:**
   - Stream audio for pieces longer than 1 minute
   - Enables real-time playback and reduces memory usage
   - Better user experience for long-form content

### Error Handling

```ruby
begin
  audio = client.music.compose(prompt: prompt)
rescue ElevenlabsClient::BadRequestError => e
  # Invalid parameters (prompt too short, invalid format, etc.)
  handle_invalid_request(e.message)
rescue ElevenlabsClient::RateLimitError => e
  # Too many requests, implement backoff
  retry_with_backoff
rescue ElevenlabsClient::APIError => e
  # General API error, log and notify user
  log_error(e)
  notify_user("Music generation temporarily unavailable")
end
```

## Output Formats

### Audio Formats

- **MP3 Formats:**
  - `mp3_22050_64` - Low quality, small file size
  - `mp3_44100_128` - Standard quality (default)
  - `mp3_44100_192` - High quality
  - `mp3_44100_320` - Premium quality

- **WAV Formats:**
  - `wav_44100` - Uncompressed, highest quality
  - `wav_22050` - Lower sample rate WAV

### Choosing the Right Format

- **Streaming/Real-time:** `mp3_22050_64` or `mp3_44100_128`
- **Background Music:** `mp3_44100_128`
- **Professional Use:** `mp3_44100_192` or `wav_44100`
- **Mobile Apps:** `mp3_44100_128`
- **Web Applications:** `mp3_44100_128`

## Limitations and Considerations

1. **Generation Time:** Longer compositions take more time to generate
2. **Rate Limits:** Respect API rate limits, especially for batch generation
3. **Quality vs Speed:** Higher quality formats take longer to generate
4. **Prompt Limitations:** Very short or vague prompts may produce inconsistent results
5. **Copyright:** Generated music is original, but avoid prompts that reference copyrighted material
6. **File Size:** Longer, higher-quality audio results in larger files

The Music API provides powerful tools for creating custom music compositions tailored to your specific needs, from background tracks to full musical pieces with detailed structural control.
