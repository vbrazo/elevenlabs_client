# Dubbing API

The ElevenLabs Dubbing API allows you to create dubbed versions of your audio and video content in multiple languages.

## Available Methods

- `client.dubs.create(file_io:, filename:, target_languages:, **options)` - Create a new dubbing job
- `client.dubs.get(dubbing_id)` - Get dubbing job details
- `client.dubs.list(params = {})` - List dubbing jobs with optional filters
- `client.dubs.resources(dubbing_id)` - Get dubbing resources for editing

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
```

## Supported File Formats

- **Video**: MP4, MOV, AVI, MKV
- **Audio**: MP3, WAV, FLAC, M4A

## Available Options

- `name` - Custom name for the dubbing job
- `drop_background_audio` - Remove background audio (Boolean)
- `use_profanity_filter` - Filter profanity (Boolean)
- `highest_resolution` - Use highest resolution (Boolean)
- `dubbing_studio` - Enable dubbing studio features (Boolean)
- `watermark` - Add watermark to output
- `start_time` - Start time in seconds (Integer)
- `end_time` - End time in seconds (Integer)

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
