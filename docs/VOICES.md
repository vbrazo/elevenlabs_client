# Voices API

Manage individual voices in your ElevenLabs account - get details, create custom voices from audio samples, edit existing voices, and delete voices.

## Available Methods

- `client.voices.get(voice_id)` - Get details of a specific voice
- `client.voices.list()` - List all voices in your account
- `client.voices.create(name, samples, **options)` - Create a new voice from audio samples
- `client.voices.edit(voice_id, samples, **options)` - Edit an existing voice
- `client.voices.delete(voice_id)` - Delete a voice from your account
- `client.voices.banned?(voice_id)` - Check if a voice is banned
- `client.voices.active?(voice_id)` - Check if a voice is active

### Alias Methods
- `client.voices.get_voice(voice_id)` - Alias for get
- `client.voices.list_voices()` - Alias for list
- `client.voices.create_voice(name, samples, **options)` - Alias for create
- `client.voices.edit_voice(voice_id, samples, **options)` - Alias for edit
- `client.voices.delete_voice(voice_id)` - Alias for delete

## Usage Examples

### Get Voice Details

```ruby
# Get detailed information about a specific voice
voice_id = "21m00Tcm4TlvDq8ikWAM"  # Rachel voice
voice = client.voices.get(voice_id)

puts "Voice: #{voice['name']}"
puts "Category: #{voice['category']}"
puts "Description: #{voice['description']}"
puts "Labels: #{voice['labels']}"
puts "Settings: #{voice['settings']}"

# Check voice samples
voice['samples'].each do |sample|
  puts "Sample: #{sample['file_name']} (#{sample['size_bytes']} bytes)"
end
```

### List All Voices

```ruby
# Get all voices in your account
voices = client.voices.list

puts "Total voices: #{voices['voices'].length}"

voices['voices'].each do |voice|
  puts "#{voice['name']} (#{voice['voice_id']}) - #{voice['category']}"
  
  # Show labels if available
  if voice['labels'] && !voice['labels'].empty?
    labels = voice['labels'].map { |k, v| "#{k}: #{v}" }.join(", ")
    puts "  Labels: #{labels}"
  end
end
```

### Create Custom Voice

```ruby
# Create a voice from audio samples
voice_name = "My Custom Narrator"

# Prepare audio samples (multiple files recommended for better quality)
samples = [
  File.open("sample1.mp3", "rb"),
  File.open("sample2.mp3", "rb"),
  File.open("sample3.mp3", "rb")
]

begin
  result = client.voices.create(
    voice_name,
    samples,
    description: "A warm, professional narrator voice for audiobooks",
    labels: {
      "accent" => "american",
      "gender" => "male",
      "age" => "adult",
      "use_case" => "narration",
      "tone" => "professional"
    }
  )
  
  puts "Voice created successfully!"
  puts "Voice ID: #{result['voice_id']}"
  puts "Name: #{result['name']}"
  
ensure
  # Always close file handles
  samples.each(&:close)
end
```

### Edit Existing Voice

```ruby
voice_id = "your_custom_voice_id"

# Update voice name and description only
result = client.voices.edit(
  voice_id,
  [], # No new samples
  name: "Updated Voice Name",
  description: "Updated description for the voice"
)

puts "Voice updated: #{result['name']}"
```

### Edit Voice with New Samples

```ruby
voice_id = "your_custom_voice_id"

# Add new audio samples to improve the voice
new_samples = [
  File.open("additional_sample1.mp3", "rb"),
  File.open("additional_sample2.mp3", "rb")
]

begin
  result = client.voices.edit(
    voice_id,
    new_samples,
    name: "Enhanced Voice",
    description: "Voice enhanced with additional samples",
    labels: {
      "accent" => "american",
      "gender" => "female",
      "quality" => "enhanced"
    }
  )
  
  puts "Voice enhanced successfully!"
  
ensure
  new_samples.each(&:close)
end
```

### Delete Voice

```ruby
voice_id = "voice_to_delete"

begin
  result = client.voices.delete(voice_id)
  puts "Voice deleted: #{result['message']}"
rescue ElevenlabsClient::ValidationError => e
  puts "Error: #{e.message}"
end
```

### Voice Status Checking

```ruby
voice_id = "voice_to_check"

# Check if voice is banned
if client.voices.banned?(voice_id)
  puts "Voice is banned and cannot be used"
else
  puts "Voice is allowed for use"
end

# Check if voice is active (exists in your account)
if client.voices.active?(voice_id)
  puts "Voice is active in your account"
else
  puts "Voice not found in your account"
end
```

## Voice Categories

Voices are categorized into different types:

- **`premade`** - Pre-built voices provided by ElevenLabs
- **`cloned`** - Custom voices created from audio samples
- **`generated`** - Voices created using text-to-voice generation
- **`professional`** - Professional voice actor recordings

## Voice Information Structure

Each voice contains the following information:

### Basic Information
- `voice_id` (String) - Unique identifier
- `name` (String) - Voice name
- `description` (String) - Voice description
- `category` (String) - Voice category (premade, cloned, generated, professional)

### Audio Samples
- `samples` (Array) - Audio samples used to create the voice
  - `sample_id` (String) - Sample identifier
  - `file_name` (String) - Original filename
  - `mime_type` (String) - Audio format
  - `size_bytes` (Integer) - File size
  - `hash` (String) - File hash

### Voice Settings
- `settings` (Hash) - Default voice settings
  - `stability` (Float) - Voice stability (0.0-1.0)
  - `similarity_boost` (Float) - Similarity boost (0.0-1.0)
  - `style` (Float) - Style setting (0.0-1.0)
  - `use_speaker_boost` (Boolean) - Speaker boost enabled

### Labels and Metadata
- `labels` (Hash) - Voice characteristics and metadata
  - `accent` - Voice accent (e.g., "american", "british")
  - `gender` - Voice gender (e.g., "male", "female")
  - `age` - Voice age (e.g., "young", "adult", "elderly")
  - `use_case` - Intended use (e.g., "narration", "conversation")

### Safety and Verification
- `safety_control` (String) - Safety status ("ALLOW", "BAN")
- `voice_verification` (Hash) - Verification status
- `permission_on_resource` (String) - Your permission level

## Voice Creation Best Practices

### Audio Sample Guidelines

1. **Quality Requirements**
   - Use high-quality audio (44.1kHz, 16-bit minimum)
   - Clear, noise-free recordings
   - Consistent volume levels

2. **Content Guidelines**
   - 1-5 minutes of audio per sample
   - Multiple samples (3-10) for better quality
   - Varied content (different sentences, emotions)
   - Single speaker only

3. **Technical Requirements**
   - Supported formats: MP3, WAV, FLAC, M4A
   - Maximum file size: 25MB per sample
   - Total audio: 30 minutes maximum

### Label Best Practices

```ruby
# Good labeling example
labels = {
  "accent" => "american",           # Specific accent
  "gender" => "female",             # Clear gender
  "age" => "adult",                 # Age category
  "use_case" => "narration",        # Intended use
  "tone" => "professional",         # Voice tone
  "industry" => "healthcare",       # Industry context
  "emotion" => "calm"               # Emotional quality
}
```

## Rails Integration

```ruby
class VoicesController < ApplicationController
  def index
    client = ElevenlabsClient.new
    voices = client.voices.list
    
    render json: {
      voices: voices["voices"].map do |voice|
        {
          id: voice["voice_id"],
          name: voice["name"],
          category: voice["category"],
          description: voice["description"],
          labels: voice["labels"] || {},
          sample_count: voice["samples"]&.length || 0
        }
      end
    }
  end
  
  def show
    client = ElevenlabsClient.new
    voice = client.voices.get(params[:id])
    
    render json: {
      voice: {
        id: voice["voice_id"],
        name: voice["name"],
        category: voice["category"],
        description: voice["description"],
        labels: voice["labels"] || {},
        settings: voice["settings"],
        samples: voice["samples"].map do |sample|
          {
            id: sample["sample_id"],
            filename: sample["file_name"],
            size: sample["size_bytes"]
          }
        end,
        safety_status: voice["safety_control"],
        is_banned: voice["safety_control"] == "BAN"
      }
    }
    
  rescue ElevenlabsClient::ValidationError
    render json: { error: "Voice not found" }, status: :not_found
  end
  
  def create
    client = ElevenlabsClient.new
    
    # Handle file uploads
    samples = params[:samples] || []
    sample_files = samples.map { |upload| upload.tempfile }
    
    result = client.voices.create(
      params[:name],
      sample_files,
      description: params[:description],
      labels: parse_labels(params[:labels])
    )
    
    render json: {
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice created successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def update
    client = ElevenlabsClient.new
    
    # Handle optional file uploads
    samples = params[:samples] || []
    sample_files = samples.map { |upload| upload.tempfile }
    
    result = client.voices.edit(
      params[:id],
      sample_files,
      name: params[:name],
      description: params[:description],
      labels: parse_labels(params[:labels])
    )
    
    render json: {
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice updated successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def destroy
    client = ElevenlabsClient.new
    
    result = client.voices.delete(params[:id])
    
    render json: { message: result["message"] }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def check_status
    client = ElevenlabsClient.new
    voice_id = params[:id]
    
    render json: {
      voice_id: voice_id,
      is_active: client.voices.active?(voice_id),
      is_banned: client.voices.banned?(voice_id)
    }
  end
  
  private
  
  def parse_labels(labels_param)
    return {} unless labels_param
    
    case labels_param
    when String
      JSON.parse(labels_param)
    when Hash
      labels_param
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end
end
```

## Voice Management Workflows

### Complete Voice Creation Workflow

```ruby
class VoiceCreationService
  def initialize(client = ElevenlabsClient.new)
    @client = client
  end
  
  def create_voice_from_files(name, file_paths, metadata = {})
    # Step 1: Validate files
    validate_audio_files(file_paths)
    
    # Step 2: Open files
    samples = file_paths.map { |path| File.open(path, "rb") }
    
    # Step 3: Create voice
    result = @client.voices.create(
      name,
      samples,
      description: metadata[:description] || "Custom voice",
      labels: build_labels(metadata)
    )
    
    # Step 4: Verify creation
    voice_id = result["voice_id"]
    
    if @client.voices.active?(voice_id)
      { success: true, voice_id: voice_id, name: result["name"] }
    else
      { success: false, error: "Voice creation failed verification" }
    end
    
  ensure
    # Always close files
    samples&.each(&:close)
  end
  
  private
  
  def validate_audio_files(file_paths)
    file_paths.each do |path|
      raise ArgumentError, "File not found: #{path}" unless File.exist?(path)
      raise ArgumentError, "File too large: #{path}" if File.size(path) > 25.megabytes
    end
  end
  
  def build_labels(metadata)
    {
      "accent" => metadata[:accent] || "neutral",
      "gender" => metadata[:gender] || "neutral",
      "age" => metadata[:age] || "adult",
      "use_case" => metadata[:use_case] || "general",
      "created_at" => Time.current.iso8601
    }
  end
end
```

### Voice Quality Enhancement

```ruby
def enhance_voice_quality(voice_id, additional_samples)
  # Get current voice details
  current_voice = client.voices.get(voice_id)
  
  # Add new samples to improve quality
  result = client.voices.edit(
    voice_id,
    additional_samples,
    description: "#{current_voice['description']} (Enhanced with additional samples)"
  )
  
  puts "Voice enhanced with #{additional_samples.length} new samples"
  result
end
```

## Error Handling

```ruby
begin
  voice = client.voices.get(voice_id)
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::ValidationError => e
  puts "Voice not found or invalid: #{e.message}"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Use Cases

- **Content Creation** - Create custom narrator voices for videos, podcasts
- **Brand Voice** - Develop consistent brand voices for marketing
- **Accessibility** - Create personalized voices for assistive technology
- **Gaming** - Character voices for games and interactive media
- **Education** - Teacher or instructor voices for e-learning
- **Customer Service** - Branded voices for automated support systems

## Limitations and Considerations

1. **Voice Cloning Ethics** - Only clone voices you have permission to use
2. **Quality Requirements** - Higher quality samples produce better voices
3. **Processing Time** - Voice creation may take several minutes
4. **Storage Limits** - Account limits on number of custom voices
5. **Usage Rights** - Respect copyright and personality rights

The Voices API provides complete control over voice management in your ElevenLabs account, enabling you to create, customize, and maintain a library of voices tailored to your specific needs.
