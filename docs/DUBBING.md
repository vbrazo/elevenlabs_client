# Dubbing API

The ElevenLabs Dubbing API allows you to create dubbed versions of your audio and video content in multiple languages.

## Available Methods

### Core Dubbing Operations
- `client.dubs.create(file_io:, filename:, target_languages:, **options)` - Create a new dubbing job
- `client.dubs.get(dubbing_id)` - Get dubbing job details
- `client.dubs.list(params = {})` - List dubbing jobs with optional filters
- `client.dubs.delete(dubbing_id)` - Delete a dubbing project
- `client.dubs.resources(dubbing_id)` - Get dubbing resources for editing

### Dubbing Studio Resource Management
- `client.dubs.get_resource(dubbing_id)` - Get detailed dubbing resource information
- `client.dubs.create_segment(dubbing_id:, speaker_id:, start_time:, end_time:, **options)` - Create a new segment
- `client.dubs.delete_segment(dubbing_id, segment_id)` - Delete a segment
- `client.dubs.update_segment(dubbing_id:, segment_id:, language:, **options)` - Update segment text/timing

### Processing Operations
- `client.dubs.transcribe_segment(dubbing_id, segments)` - Regenerate transcriptions
- `client.dubs.translate_segment(dubbing_id, segments, languages = nil)` - Regenerate translations
- `client.dubs.dub_segment(dubbing_id, segments, languages = nil)` - Regenerate dubs
- `client.dubs.render_project(dubbing_id:, language:, render_type:, **options)` - Render output media

### Speaker Management
- `client.dubs.update_speaker(dubbing_id:, speaker_id:, **options)` - Update speaker voice/settings
- `client.dubs.get_similar_voices(dubbing_id, speaker_id)` - Get similar voice recommendations

## Usage Examples

### Basic Dubbing

```ruby
# Create a dubbing job
File.open("video.mp4", "rb") do |file|
  result = client.dubs.create(
    file_io: file,
    filename: "video.mp4",
    target_languages: ["es", "fr", "de"]
  )
  
  dubbing_id = result["dubbing_id"]
  puts "Dubbing job created: #{dubbing_id}"
end

# Check dubbing status
status = client.dubs.get(dubbing_id)
puts "Status: #{status['status']}"

# List all dubbing jobs
dubs = client.dubs.list
puts "Total dubs: #{dubs['dubs'].length}"
```

### Advanced Dubbing Options

```ruby
File.open("presentation.mp4", "rb") do |file|
  result = client.dubs.create(
    file_io: file,
    filename: "presentation.mp4",
    target_languages: ["es", "pt", "fr"],
    name: "Marketing Presentation Q1",
    drop_background_audio: true,
    use_profanity_filter: true,
    highest_resolution: true,
    dubbing_studio: true
  )
end
```

### Filtering Dubbing Jobs

```ruby
# Filter by status
completed_dubs = client.dubs.list(dubbing_status: "dubbed")

# Pagination
page_1 = client.dubs.list(page_size: 10, page: 1)
page_2 = client.dubs.list(page_size: 10, page: 2)
```

### Getting Dubbing Resources

```ruby
# Get resources for editing (requires dubbing_studio: true)
resources = client.dubs.resources(dubbing_id)
puts "Available resources: #{resources['resources'].keys}"

# Get detailed resource information
resource = client.dubs.get_resource(dubbing_id)
puts "Source language: #{resource['source_language']}"
puts "Target languages: #{resource['target_languages'].join(', ')}"
puts "Version: #{resource['version']}"
```

### Dubbing Studio Workflow

```ruby
# Complete workflow for dubbing studio projects
dubbing_id = "your_dubbing_id"
speaker_id = "speaker_123"
segment_id = "segment_456"

# 1. Create a new segment
segment_result = client.dubs.create_segment(
  dubbing_id: dubbing_id,
  speaker_id: speaker_id,
  start_time: 10.5,
  end_time: 15.2,
  text: "Hello world",
  translations: { "es" => "Hola mundo", "fr" => "Bonjour le monde" }
)
segment_id = segment_result["new_segment"]

# 2. Update segment text or timing
client.dubs.update_segment(
  dubbing_id: dubbing_id,
  segment_id: segment_id,
  language: "es",
  text: "Updated Spanish text",
  start_time: 10.0,
  end_time: 16.0
)

# 3. Transcribe segments
client.dubs.transcribe_segment(dubbing_id, [segment_id])

# 4. Translate segments to specific languages
client.dubs.translate_segment(dubbing_id, [segment_id], ["es", "fr"])

# 5. Generate dubs for segments
client.dubs.dub_segment(dubbing_id, [segment_id], ["es", "fr"])

# 6. Update speaker voice
client.dubs.update_speaker(
  dubbing_id: dubbing_id,
  speaker_id: speaker_id,
  voice_id: "voice_from_library",
  languages: ["es", "fr"]
)

# 7. Get similar voice recommendations
similar_voices = client.dubs.get_similar_voices(dubbing_id, speaker_id)
similar_voices["voices"].each do |voice|
  puts "#{voice['name']}: #{voice['description']}"
end

# 8. Render final output
render_result = client.dubs.render_project(
  dubbing_id: dubbing_id,
  language: "es",
  render_type: "mp4",
  normalize_volume: true
)
render_id = render_result["render_id"]

# 9. Clean up - delete segment if needed
client.dubs.delete_segment(dubbing_id, segment_id)
```

### Voice Cloning Workflow

```ruby
# Use voice cloning for speakers
client.dubs.update_speaker(
  dubbing_id: dubbing_id,
  speaker_id: speaker_id,
  voice_id: "track-clone"  # or "clip-clone"
)

# Get similar voices to help with voice selection
similar_voices = client.dubs.get_similar_voices(dubbing_id, speaker_id)
best_match = similar_voices["voices"].first
puts "Best match: #{best_match['name']} - #{best_match['description']}"

# Apply the recommended voice
client.dubs.update_speaker(
  dubbing_id: dubbing_id,
  speaker_id: speaker_id,
  voice_id: best_match["voice_id"]
)
```

### Rendering Different Formats

```ruby
# Render different output formats
formats = ["mp4", "aac", "mp3", "wav", "aaf", "tracks_zip", "clips_zip"]

formats.each do |format|
  result = client.dubs.render_project(
    dubbing_id: dubbing_id,
    language: "es",
    render_type: format,
    normalize_volume: true
  )
  puts "#{format.upcase} render started: #{result['render_id']}"
end
```

### Project Management

```ruby
# Delete a dubbing project when done
result = client.dubs.delete(dubbing_id)
puts "Project deleted: #{result['status']}"
```

## Supported File Formats

- **Video**: MP4, MOV, AVI, MKV
- **Audio**: MP3, WAV, FLAC, M4A

## Available Options

### Core Dubbing Options
- `name` - Custom name for the dubbing job
- `drop_background_audio` - Remove background audio (Boolean)
- `use_profanity_filter` - Filter profanity (Boolean)
- `highest_resolution` - Use highest resolution (Boolean)
- `dubbing_studio` - Enable dubbing studio features (Boolean)
- `watermark` - Add watermark to output
- `start_time` - Start time in seconds (Integer)
- `end_time` - End time in seconds (Integer)

### Segment Creation Options
- `text` - Text content for the segment (String)
- `translations` - Hash of language codes to translated text (Hash)

### Segment Update Options
- `start_time` - New start time in seconds (Float)
- `end_time` - New end time in seconds (Float)
- `text` - Updated text content (String)

### Rendering Options
- `render_type` - Output format: "mp4", "aac", "mp3", "wav", "aaf", "tracks_zip", "clips_zip"
- `normalize_volume` - Whether to normalize audio volume (Boolean)

### Speaker Update Options
- `voice_id` - Voice ID from library, "track-clone", or "clip-clone" (String)
- `languages` - Array of language codes to apply changes to (Array)

## Error Handling

```ruby
begin
  result = client.dubs.create(
    file_io: file,
    filename: "video.mp4",
    target_languages: ["es"]
  )
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

## Rails Integration

See [examples/dubs_controller.rb](../examples/dubs_controller.rb) for a complete Rails controller implementation with:

- File upload handling
- Batch processing
- Download functionality
- Comprehensive error handling
- Parameter validation
