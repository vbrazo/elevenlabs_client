# Admin History API

The Admin History API allows you to manage your generated audio history, including listing, retrieving, downloading, and deleting history items.

## Available Methods

- `client.history.list(**options)` - Get a list of generated audio items
- `client.history.get(history_item_id)` - Get details for a specific history item
- `client.history.delete(history_item_id)` - Delete a history item
- `client.history.get_audio(history_item_id)` - Get the audio data for a history item
- `client.history.download(history_item_ids, **options)` - Download one or more history items

### Alias Methods

- `client.history.get_generated_items(**options)` - Alias for `list`
- `client.history.get_history_item(history_item_id)` - Alias for `get`
- `client.history.delete_history_item(history_item_id)` - Alias for `delete`
- `client.history.get_audio_from_history_item(history_item_id)` - Alias for `get_audio`
- `client.history.download_history_items(history_item_ids, **options)` - Alias for `download`

## Usage Examples

### Basic History Listing

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Get all history items
history = client.history.list

puts "Total items: #{history['history'].length}"
puts "Has more: #{history['has_more']}"

history['history'].each do |item|
  puts "#{item['date_unix']}: #{item['text']} (Voice: #{item['voice_name']})"
end
```

### Paginated History Listing

```ruby
# Get history with pagination
page_size = 50
start_after_id = nil
all_items = []

loop do
  options = { page_size: page_size }
  options[:start_after_history_item_id] = start_after_id if start_after_id

  page = client.history.list(**options)
  all_items.concat(page['history'])
  
  break unless page['has_more']
  start_after_id = page['last_history_item_id']
end

puts "Retrieved #{all_items.length} total history items"
```

### Filtered History Search

```ruby
# Search for specific content
search_results = client.history.list(
  search: "hello world",
  source: "TTS",
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  page_size: 25
)

puts "Found #{search_results['history'].length} matching items"
```

### Get Specific History Item

```ruby
# Get detailed information about a history item
history_item_id = "ja9xsmfGhxYcymxGcOGB"
item = client.history.get(history_item_id)

puts "Text: #{item['text']}"
puts "Voice: #{item['voice_name']} (#{item['voice_category']})"
puts "Model: #{item['model_id']}"
puts "Character count: #{item['character_count_change_from']} → #{item['character_count_change_to']}"
puts "Settings: #{item['settings']}"
```

### Download Audio from History

```ruby
# Get the audio data for a history item
history_item_id = "ja9xsmfGhxYcymxGcOGB"
audio_data = client.history.get_audio(history_item_id)

# Save to file
File.open("history_audio.mp3", "wb") do |file|
  file.write(audio_data)
end
```

### Bulk Download History Items

```ruby
# Download multiple history items
history_item_ids = ["id1", "id2", "id3"]

# Download as ZIP file (multiple items)
zip_data = client.history.download(history_item_ids)
File.open("history_items.zip", "wb") { |f| f.write(zip_data) }

# Download single item as audio file
single_audio = client.history.download(["single_id"])
File.open("single_item.mp3", "wb") { |f| f.write(single_audio) }

# Download with specific format
wav_data = client.history.download(history_item_ids, output_format: "wav")
File.open("history_items_wav.zip", "wb") { |f| f.write(wav_data) }
```

### Delete History Items

```ruby
# Delete a specific history item
history_item_id = "ja9xsmfGhxYcymxGcOGB"
result = client.history.delete(history_item_id)
puts result["status"]  # "ok"

# Bulk delete old items
old_items = client.history.list(page_size: 100)
cutoff_date = Time.now.to_i - (30 * 24 * 60 * 60)  # 30 days ago

old_items['history'].each do |item|
  if item['date_unix'] < cutoff_date
    client.history.delete(item['history_item_id'])
    puts "Deleted: #{item['text'][0..50]}..."
  end
end
```

## Methods

### `list(**options)`

Gets a list of your generated audio items with optional filtering and pagination.

**Parameters:**
- **page_size** (Integer): How many items to return (max 1000, default 100)
- **start_after_history_item_id** (String): ID to start fetching after (for pagination)
- **voice_id** (String): Filter by specific voice ID
- **search** (String): Search term for filtering (requires source parameter)
- **source** (String): Source type filter ("TTS" or "STS")

**Returns:** Hash containing history items, pagination info

### `get(history_item_id)`

Retrieves detailed information for a specific history item.

**Parameters:**
- **history_item_id** (String, required): The ID of the history item

**Returns:** Hash with detailed history item data

### `delete(history_item_id)`

Deletes a history item by its ID.

**Parameters:**
- **history_item_id** (String, required): The ID of the history item to delete

**Returns:** Hash with status confirmation

### `get_audio(history_item_id)`

Returns the audio data for a history item.

**Parameters:**
- **history_item_id** (String, required): The ID of the history item

**Returns:** String containing binary audio data

### `download(history_item_ids, **options)`

Downloads one or more history items. Returns a single audio file for one item, or a ZIP file for multiple items.

**Parameters:**
- **history_item_ids** (Array<String>, required): List of history item IDs to download
- **output_format** (String): Output format ("wav" or "default")

**Returns:** String containing binary audio/zip data

## Response Structure

### History List Response

```ruby
{
  "history" => [
    {
      "history_item_id" => "ja9xsmfGhxYcymxGcOGB",
      "date_unix" => 1714650306,
      "character_count_change_from" => 17189,
      "character_count_change_to" => 17231,
      "content_type" => "audio/mpeg",
      "state" => nil,
      "request_id" => "BF0BZg4IwLGBlaVjv9Im",
      "voice_id" => "21m00Tcm4TlvDq8ikWAM",
      "model_id" => "eleven_multilingual_v2",
      "voice_name" => "Rachel",
      "voice_category" => "premade",
      "text" => "Hello, world!",
      "settings" => {
        "similarity_boost" => 0.5,
        "stability" => 0.71,
        "style" => 0,
        "use_speaker_boost" => true
      },
      "source" => "TTS"
    }
  ],
  "has_more" => true,
  "last_history_item_id" => "ja9xsmfGhxYcymxGcOGB",
  "scanned_until" => 1714650306
}
```

### History Item Response

```ruby
{
  "history_item_id" => "ja9xsmfGhxYcymxGcOGB",
  "date_unix" => 1714650306,
  "character_count_change_from" => 17189,
  "character_count_change_to" => 17231,
  "content_type" => "audio/mpeg",
  "voice_id" => "21m00Tcm4TlvDq8ikWAM",
  "model_id" => "eleven_multilingual_v2",
  "voice_name" => "Rachel",
  "voice_category" => "premade",
  "text" => "Hello, world!",
  "settings" => {
    "similarity_boost" => 0.5,
    "stability" => 0.71,
    "style" => 0,
    "use_speaker_boost" => true
  },
  "source" => "TTS",
  "feedback" => nil,
  "share_link_id" => nil,
  "alignments" => nil,
  "dialogue" => nil
}
```

## Pagination

The History API supports cursor-based pagination for efficient handling of large datasets:

```ruby
def fetch_all_history_items
  all_items = []
  start_after_id = nil
  
  loop do
    page = client.history.list(
      page_size: 100,
      start_after_history_item_id: start_after_id
    )
    
    all_items.concat(page['history'])
    
    break unless page['has_more']
    start_after_id = page['last_history_item_id']
  end
  
  all_items
end
```

## Filtering and Search

### By Voice

```ruby
# Get history for a specific voice
rachel_items = client.history.list(voice_id: "21m00Tcm4TlvDq8ikWAM")
```

### By Source

```ruby
# Get only Text-to-Speech items
tts_items = client.history.list(source: "TTS")

# Get only Speech-to-Speech items  
sts_items = client.history.list(source: "STS")
```

### Text Search

```ruby
# Search for specific content (requires source parameter)
search_results = client.history.list(
  search: "hello world",
  source: "TTS"
)
```

### Combined Filters

```ruby
# Complex filtering
filtered_items = client.history.list(
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  source: "TTS",
  search: "professional",
  page_size: 50
)
```

## Bulk Operations

### Bulk Download

```ruby
# Get list of items to download
history_list = client.history.list(page_size: 10)
item_ids = history_list['history'].map { |item| item['history_item_id'] }

# Download all as ZIP
zip_data = client.history.download(item_ids)
File.open("bulk_download.zip", "wb") { |f| f.write(zip_data) }

# Download as WAV format
wav_zip = client.history.download(item_ids, output_format: "wav")
File.open("bulk_download_wav.zip", "wb") { |f| f.write(wav_zip) }
```

### Bulk Cleanup

```ruby
# Delete items older than 30 days
cutoff_date = Time.now.to_i - (30 * 24 * 60 * 60)
deleted_count = 0

# Process in batches
start_after_id = nil

loop do
  page = client.history.list(
    page_size: 100,
    start_after_history_item_id: start_after_id
  )
  
  page['history'].each do |item|
    if item['date_unix'] < cutoff_date
      client.history.delete(item['history_item_id'])
      deleted_count += 1
    end
  end
  
  break unless page['has_more']
  start_after_id = page['last_history_item_id']
end

puts "Deleted #{deleted_count} old history items"
```

## Error Handling

```ruby
begin
  history = client.history.list
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid parameters: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end

begin
  item = client.history.get("invalid_id")
rescue ElevenlabsClient::NotFoundError
  puts "History item not found"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid history item ID: #{e.message}"
end

begin
  audio = client.history.get_audio("history_item_id")
rescue ElevenlabsClient::NotFoundError
  puts "Audio not found for this history item"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Audio not available: #{e.message}"
end

begin
  result = client.history.download(["id1", "invalid_id"])
rescue ElevenlabsClient::BadRequestError => e
  puts "Invalid download request: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Some items not found: #{e.message}"
end
```

## Source Types

- **TTS** - Text-to-Speech generated audio
- **STS** - Speech-to-Speech converted audio
- **AN** - Audio Native projects
- **Projects** - Project-based generations
- **Dubbing** - Dubbing operations
- **PlayAPI** - Play API generations
- **PD** - Pronunciation Dictionary
- **ConvAI** - Agents Platform (Conversational AI)

## Voice Categories

- **premade** - ElevenLabs premade voices
- **cloned** - User-cloned voices
- **generated** - AI-generated voices (Text-to-Voice)
- **professional** - Professional voice actor voices

## Best Practices

### Efficient Pagination

```ruby
def process_all_history_items(&block)
  start_after_id = nil
  
  loop do
    page = client.history.list(
      page_size: 100,  # Use larger page sizes for efficiency
      start_after_history_item_id: start_after_id
    )
    
    page['history'].each(&block)
    
    break unless page['has_more']
    start_after_id = page['last_history_item_id']
  end
end

# Usage
process_all_history_items do |item|
  puts "Processing: #{item['text']}"
end
```

### Efficient Bulk Downloads

```ruby
# Download in batches to avoid large memory usage
def download_history_in_batches(item_ids, batch_size: 10)
  item_ids.each_slice(batch_size).with_index do |batch, index|
    zip_data = client.history.download(batch)
    File.open("batch_#{index}.zip", "wb") { |f| f.write(zip_data) }
    puts "Downloaded batch #{index + 1}: #{batch.length} items"
  end
end
```

### Smart Cleanup

```ruby
# Intelligent cleanup based on usage patterns
def cleanup_old_history(keep_days: 30, keep_favorites: true)
  cutoff_date = Time.now.to_i - (keep_days * 24 * 60 * 60)
  deleted_count = 0
  
  start_after_id = nil
  
  loop do
    page = client.history.list(
      page_size: 100,
      start_after_history_item_id: start_after_id
    )
    
    page['history'].each do |item|
      # Skip if too recent
      next if item['date_unix'] >= cutoff_date
      
      # Skip favorites if requested
      if keep_favorites && item['feedback']&.dig('thumbs_up')
        next
      end
      
      # Skip if it's a professional voice (might be expensive to regenerate)
      if item['voice_category'] == 'professional'
        next
      end
      
      client.history.delete(item['history_item_id'])
      deleted_count += 1
    end
    
    break unless page['has_more']
    start_after_id = page['last_history_item_id']
  end
  
  puts "Cleaned up #{deleted_count} old history items"
end
```

## Rails Integration Example

```ruby
class HistoryController < ApplicationController
  before_action :initialize_client
  
  def index
    @history = @client.history.list(
      page_size: params[:page_size] || 50,
      start_after_history_item_id: params[:after],
      voice_id: params[:voice_id],
      search: params[:search],
      source: params[:source]
    )
  end
  
  def show
    @item = @client.history.get(params[:id])
  rescue ElevenlabsClient::NotFoundError
    render json: { error: "History item not found" }, status: :not_found
  end
  
  def download_audio
    audio_data = @client.history.get_audio(params[:id])
    
    send_data audio_data,
              type: "audio/mpeg",
              filename: "history_#{params[:id]}.mp3",
              disposition: "attachment"
  rescue ElevenlabsClient::NotFoundError
    render json: { error: "Audio not found" }, status: :not_found
  end
  
  def bulk_download
    item_ids = params[:history_item_ids]
    
    if item_ids.length == 1
      audio_data = @client.history.download(item_ids)
      send_data audio_data, type: "audio/mpeg", filename: "audio.mp3"
    else
      zip_data = @client.history.download(item_ids, output_format: params[:format])
      send_data zip_data, type: "application/zip", filename: "history_items.zip"
    end
  rescue ElevenlabsClient::BadRequestError => e
    render json: { error: e.message }, status: :bad_request
  end
  
  def destroy
    result = @client.history.delete(params[:id])
    render json: { status: result["status"] }
  rescue ElevenlabsClient::NotFoundError
    render json: { error: "History item not found" }, status: :not_found
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
end
```

## Use Cases

### Content Management
- **Audit Trail** - Track all generated content
- **Usage Analytics** - Analyze voice and model usage patterns
- **Content Backup** - Download important generated audio
- **Storage Management** - Clean up old or unused items

### Business Intelligence
- **Cost Analysis** - Track character usage and costs
- **Voice Performance** - Compare different voices and settings
- **Model Comparison** - Analyze model effectiveness
- **User Behavior** - Understand content generation patterns

### Automation
- **Scheduled Cleanup** - Automatically delete old items
- **Backup Systems** - Regular downloads of important content
- **Monitoring** - Track generation volume and patterns
- **Compliance** - Maintain audit logs for regulatory requirements

## Limitations

- **Maximum Page Size**: 1000 items per request
- **Search Requirement**: Search parameter requires source parameter
- **Retention Policy**: Items may be automatically deleted based on your plan
- **Download Limits**: Large bulk downloads may have rate limits

## Performance Tips

1. **Use Pagination**: Always use appropriate page sizes for large datasets
2. **Filter Early**: Use voice_id and source filters to reduce data transfer
3. **Batch Operations**: Group multiple operations for efficiency
4. **Cache Results**: Cache frequently accessed history data
5. **Async Processing**: Use background jobs for large bulk operations
