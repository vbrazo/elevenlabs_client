# ElevenLabs Admin API Documentation

The ElevenLabs Admin API provides comprehensive administrative functionality for managing your account, monitoring usage, accessing your generation history, and managing your voice library. This documentation covers all available admin endpoints in the Ruby client.

## Available Admin Endpoints

### 🏠 [User Management](USER.md)
Access comprehensive user account information, subscription details, and feature availability.

```ruby
# Get user information
user_info = client.user.get_user
puts "Character usage: #{user_info['subscription']['character_count']} / #{user_info['subscription']['character_limit']}"
```

**Key Features:**
- Account information and settings
- Subscription tier and status
- Character and voice limits
- Feature availability checks
- API key management

---

### 📊 [Usage Analytics](USAGE.md)
Retrieve detailed character usage metrics with flexible breakdown and aggregation options.

```ruby
# Get usage stats for the last 30 days
usage_stats = client.usage.get_character_stats(
  start_unix: (Time.now - 30.days).to_i * 1000,
  end_unix: Time.now.to_i * 1000,
  breakdown_type: "voice"
)
```

**Key Features:**
- Character usage metrics over time
- Usage breakdown by voice, model, user, or source
- Flexible time aggregation (hour, day, week, month)
- Workspace-wide usage statistics
- Cost estimation and trend analysis

---

### 📚 [History Management](HISTORY.md)
Manage your generated audio history with comprehensive search, download, and cleanup capabilities.

```ruby
# Get recent history with filtering
history = client.history.list(
  search: "hello world",
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  page_size: 50
)

# Download audio
audio_data = client.history.get_audio(history_item_id)
```

**Key Features:**
- List and search generated audio items
- Retrieve detailed history item information
- Download individual or bulk audio files
- Delete unwanted history items
- Advanced filtering and pagination

---

### 🎤 [Voice Library](VOICE_LIBRARY.md)
Browse and manage shared voices from the ElevenLabs community with advanced filtering and search.

```ruby
# Browse professional voices
voices = client.voice_library.get_shared_voices(
  category: "professional",
  gender: "Female",
  language: "en"
)

# Add a voice to your collection
result = client.voice_library.add_shared_voice(
  public_user_id: voice['public_owner_id'],
  voice_id: voice['voice_id'],
  new_name: "My Custom Voice"
)
```

**Key Features:**
- Browse community shared voices
- Advanced filtering by category, gender, age, language
- Search by use case and descriptive terms
- Add shared voices to your personal collection
- Voice recommendation and curation tools

---

## Quick Start Guide

### Installation and Setup

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Or configure globally
ElevenlabsClient.configure do |config|
  config.elevenlabs_api_key = "your_api_key"
end
client = ElevenlabsClient.new
```

### Basic Admin Operations

```ruby
# Check account status
user_info = client.user.get_user
puts "Account: #{user_info['subscription']['tier']} (#{user_info['subscription']['status']})"
puts "Usage: #{user_info['subscription']['character_count']} / #{user_info['subscription']['character_limit']}"

# Get recent usage
usage = client.usage.get_character_stats(
  start_unix: (Time.now - 7.days).to_i * 1000,
  end_unix: Time.now.to_i * 1000
)
puts "7-day usage: #{usage['usage']['All'].sum} characters"

# Check recent history
history = client.history.list(page_size: 10)
puts "Recent generations: #{history['history'].length} items"

# Browse voice library
voices = client.voice_library.get_shared_voices(featured: true, page_size: 5)
puts "Featured voices: #{voices['voices'].length} available"
```

## Common Use Cases

### 1. Account Health Monitoring

```ruby
def check_account_health
  user_info = client.user.get_user
  subscription = user_info['subscription']
  
  # Check usage levels
  char_usage = (subscription['character_count'].to_f / subscription['character_limit'] * 100).round(2)
  voice_usage = (subscription['voice_slots_used'].to_f / subscription['voice_limit'] * 100).round(2)
  
  puts "Character Usage: #{char_usage}%"
  puts "Voice Slots: #{voice_usage}%"
  
  # Check for issues
  warnings = []
  warnings << "High character usage" if char_usage > 80
  warnings << "High voice slot usage" if voice_usage > 80
  warnings << "Account in probation" if user_info.dig('subscription_extras', 'moderation', 'is_in_probation')
  
  puts warnings.any? ? "⚠️  Issues: #{warnings.join(', ')}" : "✅ Account healthy"
end
```

### 2. Usage Analytics Dashboard

```ruby
def generate_usage_report(days: 30)
  end_time = Time.now.to_i * 1000
  start_time = (Time.now - days.days).to_i * 1000
  
  # Overall usage
  total_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time
  )
  
  # Voice breakdown
  voice_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    breakdown_type: "voice"
  )
  
  # Model breakdown
  model_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    breakdown_type: "model"
  )
  
  puts "Usage Report (#{days} days):"
  puts "Total Characters: #{total_usage['usage']['All'].sum}"
  puts "Top Voice: #{voice_usage['usage'].max_by { |_, usage| usage.sum }&.first}"
  puts "Top Model: #{model_usage['usage'].max_by { |_, usage| usage.sum }&.first}"
end
```

### 3. History Management

```ruby
def cleanup_old_history(days: 30)
  cutoff_date = Time.now.to_i - (days * 24 * 60 * 60)
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
        puts "Deleted: #{item['text'][0..50]}..."
      end
    end
    
    break unless page['has_more']
    start_after_id = page['last_history_item_id']
  end
  
  puts "Cleanup complete: #{deleted_count} items deleted"
end
```

### 4. Voice Collection Building

```ruby
def build_voice_collection(theme: :professional, count: 5)
  filters = case theme
  when :professional
    { category: "professional", featured: true }
  when :diverse
    { page_size: 50 }  # Will filter for diversity
  when :narration
    { use_cases: ["narration", "audiobook"], descriptives: ["calm", "clear"] }
  end
  
  voices = client.voice_library.get_shared_voices(**filters)
  
  # Select diverse set if needed
  selected_voices = if theme == :diverse
    select_diverse_voices(voices['voices'], count)
  else
    voices['voices'].first(count)
  end
  
  # Add to collection
  added = []
  selected_voices.each do |voice|
    begin
      result = client.voice_library.add_shared_voice(
        public_user_id: voice['public_owner_id'],
        voice_id: voice['voice_id'],
        new_name: "#{theme.to_s.capitalize} #{voice['name']}"
      )
      added << result['voice_id']
      puts "✅ Added: #{voice['name']}"
    rescue ElevenlabsClient::UnprocessableEntityError
      puts "⚠️  Skipped: #{voice['name']} (already exists)"
    end
  end
  
  puts "Collection built: #{added.length} voices added"
  added
end

def select_diverse_voices(voices, count)
  # Ensure diversity across gender, age, accent
  diverse_set = []
  used_combinations = Set.new
  
  voices.sort_by { |v| -v['cloned_by_count'] }.each do |voice|
    combination = "#{voice['gender']}_#{voice['age']}_#{voice['accent']}"
    
    if !used_combinations.include?(combination) && diverse_set.length < count
      diverse_set << voice
      used_combinations.add(combination)
    end
    
    break if diverse_set.length >= count
  end
  
  diverse_set
end
```

## Error Handling Best Practices

```ruby
def safe_admin_operation
  begin
    # Your admin operations here
    result = client.user.get_user
    
  rescue ElevenlabsClient::AuthenticationError
    puts "❌ Authentication failed - check your API key"
    return nil
    
  rescue ElevenlabsClient::UnprocessableEntityError => e
    puts "❌ Invalid request: #{e.message}"
    return nil
    
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Resource not found"
    return nil
    
  rescue ElevenlabsClient::RateLimitError
    puts "⏱️  Rate limit exceeded - waiting..."
    sleep(60)  # Wait and retry
    retry
    
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    return nil
    
  rescue StandardError => e
    puts "❌ Unexpected error: #{e.message}"
    return nil
  end
  
  result
end
```

## Rails Integration

### Admin Dashboard Controller

```ruby
class AdminDashboardController < ApplicationController
  before_action :initialize_client
  
  def index
    @user_info = safe_api_call { @client.user.get_user }
    @recent_usage = safe_api_call { get_recent_usage }
    @recent_history = safe_api_call { @client.history.list(page_size: 10) }
    @featured_voices = safe_api_call { @client.voice_library.get_shared_voices(featured: true, page_size: 5) }
  end
  
  def usage
    days = params[:days]&.to_i || 30
    @usage_stats = safe_api_call { get_usage_stats(days) }
  end
  
  def history
    @history = safe_api_call do
      @client.history.list(
        page_size: params[:page_size] || 50,
        start_after_history_item_id: params[:after],
        voice_id: params[:voice_id],
        search: params[:search],
        source: params[:source]
      )
    end
  end
  
  def voice_library
    @voices = safe_api_call do
      @client.voice_library.get_shared_voices(
        category: params[:category],
        gender: params[:gender],
        language: params[:language],
        search: params[:search],
        page_size: params[:page_size] || 30,
        page: params[:page] || 0
      )
    end
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def safe_api_call(&block)
    block.call
  rescue ElevenlabsClient::APIError => e
    flash[:error] = "API Error: #{e.message}"
    nil
  rescue StandardError => e
    flash[:error] = "Unexpected error: #{e.message}"
    nil
  end
  
  def get_recent_usage
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - 7.days).to_i * 1000
    
    @client.usage.get_character_stats(
      start_unix: start_time,
      end_unix: end_time
    )
  end
  
  def get_usage_stats(days)
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    {
      total: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time
      ),
      by_voice: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "voice"
      ),
      by_model: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "model"
      )
    }
  end
end
```

## API Reference Summary

### User Endpoint
- **Method**: `client.user.get_user`
- **Purpose**: Get comprehensive user account information
- **Returns**: User details, subscription info, limits, and features

### Usage Endpoint
- **Method**: `client.usage.get_character_stats(start_unix:, end_unix:, **options)`
- **Purpose**: Retrieve character usage analytics
- **Returns**: Time-series usage data with flexible breakdowns

### History Endpoint
- **Methods**: `list`, `get`, `delete`, `get_audio`, `download`
- **Purpose**: Manage generated audio history
- **Returns**: History items, audio data, or operation confirmations

### Voice Library Endpoint
- **Methods**: `get_shared_voices`, `add_shared_voice`
- **Purpose**: Browse and manage community voices
- **Returns**: Voice listings or addition confirmations

## Rate Limits and Best Practices

1. **Respect Rate Limits**: All admin API calls count toward your rate limits
2. **Cache When Possible**: Cache frequently accessed data (user info, voice lists)
3. **Use Pagination**: Implement proper pagination for large datasets
4. **Handle Errors Gracefully**: Implement comprehensive error handling
5. **Background Processing**: Use background jobs for bulk operations
6. **Monitor Usage**: Set up alerts for approaching limits
7. **Optimize Queries**: Use specific filters to reduce data transfer

## Getting Help

- **Documentation**: Refer to individual endpoint documentation for detailed examples
- **Error Messages**: Check error messages for specific guidance
- **Rate Limits**: Monitor your rate limit usage in responses
- **Support**: Contact ElevenLabs support for account-specific issues

---

For detailed examples and advanced usage patterns, see the individual endpoint documentation:
- [User Management](USER.md)
- [Usage Analytics](USAGE.md)  
- [History Management](HISTORY.md)
- [Voice Library](VOICE_LIBRARY.md)
