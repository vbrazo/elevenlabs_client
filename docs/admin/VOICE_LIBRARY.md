# Admin Voice Library API

The Admin Voice Library API allows you to browse and manage shared voices from the ElevenLabs community, including searching, filtering, and adding voices to your collection.

## Available Methods

- `client.voice_library.get_shared_voices(**options)` - Get a list of shared voices with filtering options
- `client.voice_library.add_shared_voice(public_user_id:, voice_id:, new_name:)` - Add a shared voice to your collection

### Alias Methods

- `client.voice_library.shared_voices(**options)` - Alias for `get_shared_voices`
- `client.voice_library.list_shared_voices(**options)` - Alias for `get_shared_voices`
- `client.voice_library.add_voice(public_user_id:, voice_id:, new_name:)` - Alias for `add_shared_voice`

## Usage Examples

### Basic Voice Library Browsing

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Get all shared voices (default page size: 30)
shared_voices = client.voice_library.get_shared_voices

puts "Found #{shared_voices['voices'].length} voices"
puts "Has more: #{shared_voices['has_more']}"

shared_voices['voices'].each do |voice|
  puts "#{voice['name']} (#{voice['gender']}, #{voice['age']}) - #{voice['category']}"
  puts "  Language: #{voice['language']}, Accent: #{voice['accent']}"
  puts "  Usage: #{voice['usage_character_count_1y']} chars in last year"
  puts "  Cloned by: #{voice['cloned_by_count']} users"
  puts "  Preview: #{voice['preview_url']}"
  puts
end
```

### Filtered Voice Search

```ruby
# Search for professional female voices
professional_voices = client.voice_library.get_shared_voices(
  category: "professional",
  gender: "Female",
  language: "en",
  page_size: 50
)

puts "Professional female voices:"
professional_voices['voices'].each do |voice|
  puts "#{voice['name']} - #{voice['description']}"
  puts "  Age: #{voice['age']}, Accent: #{voice['accent']}"
  puts "  Rate: $#{voice['rate']}/month" if voice['rate'] > 1
end
```

### Search by Use Case and Descriptives

```ruby
# Find voices for specific use cases
narration_voices = client.voice_library.get_shared_voices(
  use_cases: ["narration", "audiobook"],
  descriptives: ["calm", "clear", "professional"],
  featured: true,
  page_size: 20
)

puts "Featured narration voices:"
narration_voices['voices'].each do |voice|
  puts "#{voice['name']} - #{voice['descriptive']}"
  puts "  Perfect for: #{voice['use_case']}"
  puts "  Description: #{voice['description']}"
end
```

### Advanced Filtering

```ruby
# Complex filtering with multiple criteria
filtered_voices = client.voice_library.get_shared_voices(
  category: "high_quality",
  gender: "Male",
  age: "middle_aged",
  accent: "american",
  language: "en",
  locale: "en-US",
  search: "deep voice",
  min_notice_period_days: 0,
  include_custom_rates: false,
  include_live_moderated: true,
  reader_app_enabled: true,
  page_size: 25
)

puts "Filtered results: #{filtered_voices['voices'].length} voices"
```

### Pagination

```ruby
# Browse all voices with pagination
all_voices = []
page = 0
page_size = 100

loop do
  result = client.voice_library.get_shared_voices(
    page: page,
    page_size: page_size,
    sort: "created_date_desc"
  )
  
  all_voices.concat(result['voices'])
  puts "Loaded page #{page + 1}: #{result['voices'].length} voices"
  
  break unless result['has_more']
  page += 1
end

puts "Total voices loaded: #{all_voices.length}"
```

### Voice Analysis

```ruby
# Analyze voice characteristics
voices = client.voice_library.get_shared_voices(page_size: 100)

# Group by category
by_category = voices['voices'].group_by { |v| v['category'] }
puts "Voices by category:"
by_category.each do |category, voice_list|
  puts "  #{category}: #{voice_list.length} voices"
end

# Group by language
by_language = voices['voices'].group_by { |v| v['language'] }
puts "\nVoices by language:"
by_language.each do |language, voice_list|
  puts "  #{language}: #{voice_list.length} voices"
end

# Find most popular voices (by clones)
popular_voices = voices['voices'].sort_by { |v| -v['cloned_by_count'] }.first(10)
puts "\nMost cloned voices:"
popular_voices.each_with_index do |voice, index|
  puts "  #{index + 1}. #{voice['name']}: #{voice['cloned_by_count']} clones"
end
```

### Adding Shared Voices to Your Collection

```ruby
# Browse and add a voice
voices = client.voice_library.get_shared_voices(
  category: "professional",
  gender: "Female",
  page_size: 10
)

if voices['voices'].any?
  selected_voice = voices['voices'].first
  
  puts "Adding voice: #{selected_voice['name']}"
  puts "Owner: #{selected_voice['public_owner_id']}"
  puts "Description: #{selected_voice['description']}"
  
  # Add the voice with a custom name
  result = client.voice_library.add_shared_voice(
    public_user_id: selected_voice['public_owner_id'],
    voice_id: selected_voice['voice_id'],
    new_name: "My #{selected_voice['name']} Voice"
  )
  
  puts "Voice added successfully! New voice ID: #{result['voice_id']}"
else
  puts "No voices found matching criteria"
end
```

### Batch Voice Addition

```ruby
# Add multiple voices at once
target_voices = client.voice_library.get_shared_voices(
  category: "professional",
  featured: true,
  page_size: 5
)

added_voices = []

target_voices['voices'].each do |voice|
  begin
    result = client.voice_library.add_shared_voice(
      public_user_id: voice['public_owner_id'],
      voice_id: voice['voice_id'],
      new_name: "Pro #{voice['name']}"
    )
    
    added_voices << {
      original_name: voice['name'],
      new_voice_id: result['voice_id'],
      new_name: "Pro #{voice['name']}"
    }
    
    puts "✅ Added: #{voice['name']}"
    
  rescue ElevenlabsClient::UnprocessableEntityError
    puts "⚠️  Skipped: #{voice['name']} (already in collection or unavailable)"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Failed: #{voice['name']} - #{e.message}"
  end
end

puts "\nSummary: #{added_voices.length} voices added successfully"
```

## Methods

### `get_shared_voices(**options)`

Retrieves a list of shared voices from the ElevenLabs community with extensive filtering and pagination options.

**Optional Parameters:**
- **page_size** (Integer): Number of voices to return (max 100, default 30)
- **category** (String): Filter by voice category ("professional", "famous", "high_quality")
- **gender** (String): Filter by gender ("Male", "Female", etc.)
- **age** (String): Filter by age group ("young", "middle_aged", "old", etc.)
- **accent** (String): Filter by accent ("american", "british", "australian", etc.)
- **language** (String): Filter by language code ("en", "es", "fr", etc.)
- **locale** (String): Filter by specific locale ("en-US", "en-GB", etc.)
- **search** (String): Search term for filtering voice names and descriptions
- **use_cases** (Array<String>): Filter by use cases (["narration", "characters_animation", etc.])
- **descriptives** (Array<String>): Filter by descriptive terms (["calm", "energetic", etc.])
- **featured** (Boolean): Filter for featured voices only (default: false)
- **min_notice_period_days** (Integer): Filter voices with minimum notice period
- **include_custom_rates** (Boolean): Include/exclude voices with custom pricing
- **include_live_moderated** (Boolean): Include/exclude live moderated voices
- **reader_app_enabled** (Boolean): Filter voices enabled for reader app (default: false)
- **owner_id** (String): Filter by public owner ID
- **sort** (String): Sort criteria for results
- **page** (Integer): Page number for pagination (default: 0)

**Returns:** Hash containing voices array and pagination information

### `add_shared_voice(public_user_id:, voice_id:, new_name:)`

Adds a shared voice from the community to your personal voice collection.

**Required Parameters:**
- **public_user_id** (String): Public user ID of the voice owner
- **voice_id** (String): ID of the voice to add
- **new_name** (String): Name for the voice in your collection

**Returns:** Hash containing the new voice ID

## Response Structure

### Shared Voices List Response

```ruby
{
  "voices" => [
    {
      "public_owner_id" => "63e84100a6bf7874ba37a1bab9a31828a379ec94b891b401653b655c5110880f",
      "voice_id" => "sB1b5zUrxQVAFl2PhZFp",
      "date_unix" => 1714423232,
      "name" => "Alita",
      "accent" => "american",
      "gender" => "Female",
      "age" => "young",
      "descriptive" => "calm",
      "use_case" => "characters_animation",
      "category" => "professional",
      "usage_character_count_1y" => 12852,
      "usage_character_count_7d" => 12852,
      "play_api_usage_character_count_1y" => 12852,
      "cloned_by_count" => 11,
      "free_users_allowed" => true,
      "live_moderation_enabled" => false,
      "featured" => false,
      "language" => "en",
      "description" => "Perfectly calm, neutral and strong voice. Great for a young female protagonist.",
      "preview_url" => "https://storage.googleapis.com/eleven-public-prod/.../preview.mp3",
      "rate" => 1,
      "verified_languages" => [
        {
          "language" => "en",
          "model_id" => "eleven_multilingual_v2",
          "accent" => "american",
          "locale" => "en-US",
          "preview_url" => "https://storage.googleapis.com/eleven-public-prod/.../preview.mp3"
        }
      ]
    }
  ],
  "has_more" => false,
  "last_sort_id" => "string_id_for_pagination"
}
```

### Add Voice Response

```ruby
{
  "voice_id" => "b38kUX8pkfYO2kHyqfFy"
}
```

## Voice Categories

### Category Types
- **professional** - Professional voice actor voices
- **famous** - Celebrity and famous personality voices
- **high_quality** - High-quality community voices

### Gender Options
- **Male** - Male voices
- **Female** - Female voices
- **Non-binary** - Non-binary voices

### Age Groups
- **young** - Young voices (teens to early 20s)
- **middle_aged** - Middle-aged voices (30s to 50s)
- **old** - Older voices (60+)

### Common Use Cases
- **narration** - Audiobook and documentary narration
- **characters_animation** - Character voices for animation
- **news** - News broadcasting
- **audiobook** - Audiobook reading
- **conversational** - Conversational AI
- **asmr** - ASMR content
- **meditation** - Meditation and wellness

### Descriptive Terms
- **calm** - Calm and soothing
- **energetic** - High energy and enthusiastic
- **authoritative** - Authoritative and commanding
- **friendly** - Warm and friendly
- **professional** - Business and professional
- **dramatic** - Dramatic and expressive

## Advanced Search Patterns

### Multi-Criteria Search

```ruby
def find_perfect_voice(criteria)
  voices = client.voice_library.get_shared_voices(
    category: criteria[:category],
    gender: criteria[:gender],
    age: criteria[:age],
    language: criteria[:language],
    use_cases: criteria[:use_cases],
    descriptives: criteria[:descriptives],
    featured: criteria[:featured_only],
    page_size: 100
  )
  
  # Additional filtering
  filtered_voices = voices['voices'].select do |voice|
    # Filter by usage (popularity)
    next false if criteria[:min_clones] && voice['cloned_by_count'] < criteria[:min_clones]
    
    # Filter by rate
    next false if criteria[:max_rate] && voice['rate'] > criteria[:max_rate]
    
    # Filter by free user access
    next false if criteria[:free_users_only] && !voice['free_users_allowed']
    
    true
  end
  
  # Sort by relevance
  filtered_voices.sort_by do |voice|
    score = 0
    score += voice['cloned_by_count'] * 0.1  # Popularity
    score += voice['featured'] ? 100 : 0     # Featured bonus
    score += voice['usage_character_count_1y'] * 0.001  # Usage
    -score  # Descending order
  end
end

# Usage
perfect_voice = find_perfect_voice(
  category: "professional",
  gender: "Female",
  age: "middle_aged",
  language: "en",
  use_cases: ["narration", "audiobook"],
  descriptives: ["calm", "professional"],
  featured_only: false,
  min_clones: 5,
  max_rate: 2,
  free_users_only: true
)
```

### Voice Recommendation Engine

```ruby
def recommend_voices(preferences)
  # Get base set of voices
  all_voices = []
  page = 0
  
  # Collect voices matching basic criteria
  loop do
    result = client.voice_library.get_shared_voices(
      language: preferences[:language],
      gender: preferences[:gender],
      category: preferences[:category],
      page: page,
      page_size: 100
    )
    
    all_voices.concat(result['voices'])
    break unless result['has_more']
    page += 1
  end
  
  # Score voices based on preferences
  scored_voices = all_voices.map do |voice|
    score = calculate_voice_score(voice, preferences)
    voice.merge('recommendation_score' => score)
  end
  
  # Return top recommendations
  scored_voices
    .sort_by { |v| -v['recommendation_score'] }
    .first(preferences[:limit] || 10)
end

def calculate_voice_score(voice, preferences)
  score = 0
  
  # Age preference
  if preferences[:age] && voice['age'] == preferences[:age]
    score += 20
  end
  
  # Accent preference
  if preferences[:accent] && voice['accent'] == preferences[:accent]
    score += 15
  end
  
  # Use case match
  if preferences[:use_cases]
    use_case_match = preferences[:use_cases].include?(voice['use_case'])
    score += use_case_match ? 25 : 0
  end
  
  # Descriptive match
  if preferences[:descriptives] && preferences[:descriptives].include?(voice['descriptive'])
    score += 20
  end
  
  # Popularity bonus
  score += [voice['cloned_by_count'], 50].min * 0.5
  
  # Featured bonus
  score += voice['featured'] ? 30 : 0
  
  # Free access bonus if needed
  if preferences[:free_only] && voice['free_users_allowed']
    score += 10
  end
  
  # Rate penalty for expensive voices
  if voice['rate'] > 1
    score -= (voice['rate'] - 1) * 5
  end
  
  score
end

# Usage
recommendations = recommend_voices(
  language: "en",
  gender: "Female",
  category: "professional",
  age: "middle_aged",
  accent: "american",
  use_cases: ["narration", "audiobook"],
  descriptives: ["calm", "professional"],
  free_only: true,
  limit: 5
)
```

### Voice Collection Manager

```ruby
class VoiceCollectionManager
  def initialize(client)
    @client = client
    @added_voices = []
  end
  
  def curate_collection(theme:, max_voices: 10)
    case theme
    when :narration
      curate_narration_voices(max_voices)
    when :characters
      curate_character_voices(max_voices)
    when :professional
      curate_professional_voices(max_voices)
    when :diverse
      curate_diverse_voices(max_voices)
    end
  end
  
  private
  
  def curate_narration_voices(max_voices)
    puts "Curating narration voice collection..."
    
    # Get high-quality narration voices
    voices = @client.voice_library.get_shared_voices(
      use_cases: ["narration", "audiobook"],
      descriptives: ["calm", "clear", "professional"],
      category: "professional",
      page_size: 50
    )
    
    # Select diverse set
    selected = select_diverse_voices(voices['voices'], max_voices)
    
    # Add to collection
    selected.each do |voice|
      add_voice_safely(voice, "Narration #{voice['name']}")
    end
  end
  
  def curate_character_voices(max_voices)
    puts "Curating character voice collection..."
    
    voices = @client.voice_library.get_shared_voices(
      use_cases: ["characters_animation"],
      descriptives: ["expressive", "dramatic", "energetic"],
      page_size: 50
    )
    
    selected = select_diverse_voices(voices['voices'], max_voices)
    
    selected.each do |voice|
      add_voice_safely(voice, "Character #{voice['name']}")
    end
  end
  
  def select_diverse_voices(voices, max_count)
    # Ensure diversity in gender, age, and accent
    selected = []
    used_combinations = Set.new
    
    # Sort by quality indicators
    sorted_voices = voices.sort_by do |v|
      -(v['cloned_by_count'] + v['usage_character_count_1y'] * 0.001)
    end
    
    sorted_voices.each do |voice|
      combination = "#{voice['gender']}_#{voice['age']}_#{voice['accent']}"
      
      if !used_combinations.include?(combination) && selected.length < max_count
        selected << voice
        used_combinations.add(combination)
      end
      
      break if selected.length >= max_count
    end
    
    # Fill remaining slots with best available
    if selected.length < max_count
      remaining = max_count - selected.length
      additional = (sorted_voices - selected).first(remaining)
      selected.concat(additional)
    end
    
    selected
  end
  
  def add_voice_safely(voice, custom_name)
    result = @client.voice_library.add_shared_voice(
      public_user_id: voice['public_owner_id'],
      voice_id: voice['voice_id'],
      new_name: custom_name
    )
    
    @added_voices << {
      original: voice,
      new_voice_id: result['voice_id'],
      custom_name: custom_name
    }
    
    puts "✅ Added: #{custom_name}"
    
  rescue ElevenlabsClient::UnprocessableEntityError
    puts "⚠️  Skipped: #{custom_name} (already exists or unavailable)"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Failed: #{custom_name} - #{e.message}"
  end
  
  def summary
    puts "\n=== Collection Summary ==="
    puts "Successfully added: #{@added_voices.length} voices"
    
    @added_voices.each do |voice_info|
      puts "- #{voice_info[:custom_name]} (#{voice_info[:new_voice_id]})"
    end
  end
end

# Usage
manager = VoiceCollectionManager.new(client)
manager.curate_collection(theme: :narration, max_voices: 5)
manager.summary
```

## Error Handling

```ruby
begin
  voices = client.voice_library.get_shared_voices(category: "professional")
  puts "Found #{voices['voices'].length} professional voices"
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid parameters: #{e.message}"
  # Common issues:
  # - Invalid category, gender, age values
  # - Page size exceeds maximum (100)
  # - Invalid language or locale codes
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end

begin
  result = client.voice_library.add_shared_voice(
    public_user_id: "user_id",
    voice_id: "voice_id",
    new_name: "My Voice"
  )
  puts "Voice added: #{result['voice_id']}"
rescue ElevenlabsClient::NotFoundError
  puts "Voice not found or not available"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Cannot add voice: #{e.message}"
  # Common issues:
  # - Voice already in your collection
  # - Voice requires payment/subscription
  # - Invalid voice or user ID
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
end
```

## Rails Integration Example

```ruby
class VoiceLibraryController < ApplicationController
  before_action :initialize_client
  
  def index
    @voices = @client.voice_library.get_shared_voices(
      category: params[:category],
      gender: params[:gender],
      age: params[:age],
      language: params[:language],
      search: params[:search],
      use_cases: params[:use_cases]&.split(','),
      featured: params[:featured] == 'true',
      page_size: params[:page_size] || 30,
      page: params[:page] || 0
    )
    
    @categories = %w[professional famous high_quality]
    @genders = %w[Male Female]
    @ages = %w[young middle_aged old]
    @languages = %w[en es fr de it pt]
    
  rescue ElevenlabsClient::APIError => e
    flash[:error] = "Unable to load voice library: #{e.message}"
    @voices = { 'voices' => [], 'has_more' => false }
  end
  
  def show
    @voice = find_voice_by_id(params[:id])
    
    if @voice.nil?
      redirect_to voice_library_index_path, alert: "Voice not found"
    end
  end
  
  def add_to_collection
    result = @client.voice_library.add_shared_voice(
      public_user_id: params[:public_user_id],
      voice_id: params[:voice_id],
      new_name: params[:new_name]
    )
    
    redirect_to voice_library_path(params[:voice_id]),
                notice: "Voice added to your collection! New ID: #{result['voice_id']}"
                
  rescue ElevenlabsClient::UnprocessableEntityError => e
    redirect_to voice_library_path(params[:voice_id]),
                alert: "Cannot add voice: #{e.message}"
  rescue ElevenlabsClient::NotFoundError
    redirect_to voice_library_index_path,
                alert: "Voice not found or no longer available"
  end
  
  def search_suggestions
    # AJAX endpoint for search suggestions
    query = params[:q]
    
    if query.length >= 2
      voices = @client.voice_library.get_shared_voices(
        search: query,
        page_size: 10
      )
      
      suggestions = voices['voices'].map do |voice|
        {
          name: voice['name'],
          description: voice['description'],
          category: voice['category'],
          gender: voice['gender'],
          preview_url: voice['preview_url']
        }
      end
      
      render json: { suggestions: suggestions }
    else
      render json: { suggestions: [] }
    end
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def find_voice_by_id(voice_id)
    # Since there's no direct get method, we need to search
    # This could be optimized with caching
    voices = @client.voice_library.get_shared_voices(page_size: 100)
    voices['voices'].find { |v| v['voice_id'] == voice_id }
  end
end
```

## Best Practices

### Efficient Browsing

```ruby
# Cache popular voices to reduce API calls
def cached_popular_voices
  Rails.cache.fetch("popular_voices", expires_in: 1.hour) do
    client.voice_library.get_shared_voices(
      featured: true,
      page_size: 50,
      sort: "usage_desc"
    )
  end
end

# Use pagination efficiently
def browse_all_voices(&block)
  page = 0
  
  loop do
    result = client.voice_library.get_shared_voices(
      page: page,
      page_size: 100
    )
    
    result['voices'].each(&block)
    
    break unless result['has_more']
    page += 1
  end
end
```

### Voice Selection Strategies

```ruby
def select_voices_by_strategy(strategy, count: 5)
  case strategy
  when :popular
    # Most cloned voices
    voices = client.voice_library.get_shared_voices(page_size: 100)
    voices['voices']
      .sort_by { |v| -v['cloned_by_count'] }
      .first(count)
      
  when :trending
    # Recently popular voices
    voices = client.voice_library.get_shared_voices(
      sort: "created_date_desc",
      page_size: 50
    )
    voices['voices']
      .select { |v| v['usage_character_count_7d'] > 1000 }
      .first(count)
      
  when :professional
    # High-quality professional voices
    client.voice_library.get_shared_voices(
      category: "professional",
      featured: true,
      page_size: count
    )['voices']
    
  when :diverse
    # Diverse set across categories
    select_diverse_voice_set(count)
  end
end

def select_diverse_voice_set(count)
  voices_per_category = (count / 3.0).ceil
  
  categories = %w[professional famous high_quality]
  all_selected = []
  
  categories.each do |category|
    voices = client.voice_library.get_shared_voices(
      category: category,
      page_size: voices_per_category * 2
    )
    
    selected = voices['voices'].first(voices_per_category)
    all_selected.concat(selected)
  end
  
  all_selected.first(count)
end
```

## Use Cases

### Voice Discovery
- **Browse Community** - Explore available shared voices
- **Search by Criteria** - Find voices matching specific needs
- **Preview Voices** - Listen to voice samples before adding
- **Trending Voices** - Discover popular and featured voices

### Collection Building
- **Curated Collections** - Build themed voice collections
- **Diverse Libraries** - Create diverse voice libraries
- **Professional Sets** - Assemble professional voice sets
- **Character Banks** - Build character voice collections

### Content Production
- **Voice Matching** - Find perfect voices for projects
- **Quality Assurance** - Select high-quality voices
- **Cost Management** - Choose appropriate pricing tiers
- **Workflow Integration** - Integrate with production workflows

## Limitations

- **Search Scope**: Search is limited to name and description fields
- **Preview Access**: Preview URLs may have access restrictions
- **Rate Limits**: API calls count toward your rate limits
- **Voice Availability**: Shared voices may become unavailable
- **Pricing**: Some voices may require additional payments

## Performance Tips

1. **Use Pagination**: Implement proper pagination for large result sets
2. **Cache Results**: Cache frequently accessed voice lists
3. **Batch Operations**: Group multiple voice additions
4. **Optimize Filters**: Use specific filters to reduce result sets
5. **Preview Management**: Cache or lazy-load voice previews
