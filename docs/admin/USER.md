# Admin User API

The Admin User API allows you to retrieve comprehensive information about the current user, including subscription details, usage limits, and account settings.

## Available Methods

- `client.user.get_user` - Get comprehensive user information
- `client.user.get_subscription` (alias: `client.user.subscription`) - Get extended subscription information

### Alias Methods

- `client.user.user` - Alias for `get_user`
- `client.user.info` - Alias for `get_user`

## Usage Examples

### Basic User Information

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Get user information
user_info = client.user.get_user

puts "User ID: #{user_info['user_id']}"
puts "First Name: #{user_info['first_name']}"
puts "Account Created: #{Time.at(user_info['created_at']).strftime('%Y-%m-%d')}" if user_info['created_at'] > 0
puts "Onboarding Complete: #{user_info['is_onboarding_completed']}"
```

### Subscription Information (from get_user)
### Extended Subscription Information (get_subscription)

```ruby
subscription = client.user.get_subscription

puts "Subscription: #{subscription['tier']} (#{subscription['status']})"
puts "Characters: #{subscription['character_count']} / #{subscription['character_limit']}"
puts "Voice slots: #{subscription['voice_slots_used']} / #{subscription['voice_limit']}"
puts "Currency: #{subscription['currency']}"
puts "Billing: #{subscription['billing_period']} | Refresh: #{subscription['character_refresh_period']}"

if subscription['has_open_invoices']
  puts "Open invoices: #{subscription['open_invoices'].length}"
end
```

```ruby
user_info = client.user.get_user
subscription = user_info['subscription']

puts "Subscription Details:"
puts "  Tier: #{subscription['tier']}"
puts "  Status: #{subscription['status']}"
puts "  Character Usage: #{subscription['character_count']} / #{subscription['character_limit']}"
puts "  Voice Slots Used: #{subscription['voice_slots_used']} / #{subscription['voice_limit']}"
puts "  Professional Voices: #{subscription['professional_voice_slots_used']} / #{subscription['professional_voice_limit']}"
puts "  Currency: #{subscription['currency']}"
puts "  Billing Period: #{subscription['billing_period']}"

# Calculate usage percentage
usage_percent = (subscription['character_count'].to_f / subscription['character_limit'] * 100).round(2)
puts "  Character Usage: #{usage_percent}%"

# Check if near limit
if usage_percent > 90
  puts "  ⚠️  Warning: Character usage is above 90%"
elsif usage_percent > 75
  puts "  📊 Character usage is above 75%"
end
```

### Voice Cloning Capabilities

```ruby
user_info = client.user.get_user
subscription = user_info['subscription']

puts "Voice Cloning Capabilities:"
puts "  Instant Voice Cloning: #{subscription['can_use_instant_voice_cloning'] ? '✅' : '❌'}"
puts "  Professional Voice Cloning: #{subscription['can_use_professional_voice_cloning'] ? '✅' : '❌'}"
puts "  Voice Add/Edit Counter: #{subscription['voice_add_edit_counter']} / #{subscription['max_voice_add_edits']}"

# Check voice limits
if subscription['voice_slots_used'] >= subscription['voice_limit']
  puts "  ⚠️  Voice limit reached!"
elsif subscription['voice_slots_used'] > subscription['voice_limit'] * 0.8
  puts "  📊 Voice usage above 80%"
end
```

### Character Limit Management

```ruby
user_info = client.user.get_user
subscription = user_info['subscription']

puts "Character Limit Information:"
puts "  Current: #{subscription['character_count']} / #{subscription['character_limit']}"
puts "  Can Extend Limit: #{subscription['can_extend_character_limit'] ? '✅' : '❌'}"
puts "  Allowed to Extend: #{subscription['allowed_to_extend_character_limit'] ? '✅' : '❌'}"
puts "  Max Extension: #{subscription['max_character_limit_extension']}"

# Next reset information
if subscription['next_character_count_reset_unix']
  reset_date = Time.at(subscription['next_character_count_reset_unix']).strftime('%Y-%m-%d %H:%M:%S')
  puts "  Next Reset: #{reset_date}"
  
  # Time until reset
  time_until_reset = subscription['next_character_count_reset_unix'] - Time.now.to_i
  days_until_reset = (time_until_reset / (24 * 60 * 60)).round(1)
  puts "  Days Until Reset: #{days_until_reset}"
end
```

### Subscription Extras and Features

```ruby
user_info = client.user.get_user
extras = user_info['subscription_extras']

if extras
  puts "Subscription Extras:"
  puts "  Concurrency Limit: #{extras['concurrency']}"
  puts "  ConvAI Concurrency: #{extras['convai_concurrency']}"
  puts "  Force Logging Disabled: #{extras['force_logging_disabled']}"
  puts "  Manual Pro Voice Verification: #{extras['can_request_manual_pro_voice_verification'] ? '✅' : '❌'}"
  puts "  Voice Captcha Bypass: #{extras['can_bypass_voice_captcha'] ? '✅' : '❌'}"
  
  # Moderation settings
  moderation = extras['moderation']
  if moderation
    puts "\n  Moderation Status:"
    puts "    In Probation: #{moderation['is_in_probation'] ? '⚠️ Yes' : '✅ No'}"
    puts "    On Watchlist: #{moderation['on_watchlist'] ? '⚠️ Yes' : '✅ No'}"
    puts "    Enterprise Check NoGo Voice: #{moderation['enterprise_check_nogo_voice']}"
    puts "    Background Moderation: #{moderation['enterprise_background_moderation_enabled'] ? '✅' : '❌'}"
  end
  
  # Usage rollover information
  if extras['unused_characters_rolled_over_from_previous_period']
    puts "\n  Character Rollover:"
    puts "    Unused from Previous Period: #{extras['unused_characters_rolled_over_from_previous_period']}"
    puts "    Overused from Previous Period: #{extras['overused_characters_rolled_over_from_previous_period']}"
  end
end
```

### Detailed Usage Breakdown

```ruby
user_info = client.user.get_user
extras = user_info['subscription_extras']

if extras&.dig('usage')
  usage = extras['usage']
  
  puts "Detailed Usage Breakdown:"
  puts "  Rollover Credits Quota: #{usage['rollover_credits_quota']}"
  puts "  Rollover Credits Used: #{usage['rollover_credits_used']}"
  puts "  Subscription Cycle Quota: #{usage['subscription_cycle_credits_quota']}"
  puts "  Subscription Cycle Used: #{usage['subscription_cycle_credits_used']}"
  puts "  Manually Gifted Quota: #{usage['manually_gifted_credits_quota']}"
  puts "  Manually Gifted Used: #{usage['manually_gifted_credits_used']}"
  puts "  Paid Usage Credits Used: #{usage['paid_usage_based_credits_used']}"
  puts "  Actual Reported Credits: #{usage['actual_reported_credits']}"
  
  # Calculate total available vs used
  total_quota = usage['rollover_credits_quota'] + usage['subscription_cycle_credits_quota'] + usage['manually_gifted_credits_quota']
  total_used = usage['rollover_credits_used'] + usage['subscription_cycle_credits_used'] + usage['manually_gifted_credits_used']
  
  puts "\n  Summary:"
  puts "    Total Available: #{total_quota}"
  puts "    Total Used: #{total_used}"
  puts "    Remaining: #{total_quota - total_used}"
end
```

### API Key Information

```ruby
user_info = client.user.get_user

puts "API Key Information:"
if user_info['xi_api_key']
  puts "  API Key: #{user_info['xi_api_key']}"
  puts "  Is Hashed: #{user_info['is_api_key_hashed'] ? '✅' : '❌'}"
else
  puts "  API Key: Hidden for security"
end

if user_info['xi_api_key_preview']
  puts "  API Key Preview: #{user_info['xi_api_key_preview']}"
end
```

## Methods

### `get_user`

Retrieves comprehensive information about the current user, including subscription details, usage limits, and account settings.

**Parameters:** None

**Returns:** Hash containing detailed user information

## Response Structure

### User Information Response

```ruby
{
  "user_id" => "1234567890",
  "subscription" => {
    "tier" => "trial",
    "character_count" => 17231,
    "character_limit" => 100000,
    "max_character_limit_extension" => 10000,
    "can_extend_character_limit" => false,
    "allowed_to_extend_character_limit" => false,
    "voice_slots_used" => 1,
    "professional_voice_slots_used" => 0,
    "voice_limit" => 120,
    "voice_add_edit_counter" => 212,
    "professional_voice_limit" => 1,
    "can_extend_voice_limit" => false,
    "can_use_instant_voice_cloning" => true,
    "can_use_professional_voice_cloning" => true,
    "status" => "free",
    "next_character_count_reset_unix" => 1738356858,
    "max_voice_add_edits" => 230,
    "currency" => "usd",
    "billing_period" => "monthly_period",
    "character_refresh_period" => "monthly_period"
  },
  "is_onboarding_completed" => true,
  "is_onboarding_checklist_completed" => true,
  "created_at" => 1753999199,
  "is_new_user" => false,
  "can_use_delayed_payment_methods" => false,
  "subscription_extras" => {
    "concurrency" => 10,
    "convai_concurrency" => 10,
    "force_logging_disabled" => false,
    "can_request_manual_pro_voice_verification" => true,
    "can_bypass_voice_captcha" => true,
    "moderation" => {
      "is_in_probation" => false,
      "enterprise_check_nogo_voice" => false,
      "enterprise_check_block_nogo_voice" => false,
      "never_live_moderate" => false,
      "nogo_voice_similar_voice_upload_count" => 0,
      "enterprise_background_moderation_enabled" => false,
      "on_watchlist" => false
    },
    "unused_characters_rolled_over_from_previous_period" => 1000,
    "overused_characters_rolled_over_from_previous_period" => 1000,
    "usage" => {
      "rollover_credits_quota" => 1000,
      "subscription_cycle_credits_quota" => 1000,
      "manually_gifted_credits_quota" => 1000,
      "rollover_credits_used" => 1000,
      "subscription_cycle_credits_used" => 1000,
      "manually_gifted_credits_used" => 1000,
      "paid_usage_based_credits_used" => 1000,
      "actual_reported_credits" => 1000
    }
  },
  "xi_api_key" => "8so27l7327189x0h939ekx293380l920",
  "first_name" => "John",
  "is_api_key_hashed" => false
}
```

## Subscription Tiers and Status

### Tier Types
- **trial** - Trial account
- **starter** - Starter plan
- **creator** - Creator plan  
- **pro** - Pro plan
- **scale** - Scale plan
- **enterprise** - Enterprise plan

### Status Types
- **free** - Free tier
- **active** - Active subscription
- **cancelled** - Cancelled subscription
- **past_due** - Payment overdue
- **trialing** - In trial period

### Billing Periods
- **monthly_period** - Monthly billing
- **yearly_period** - Annual billing
- **one_time** - One-time payment

## Advanced Usage Patterns

### Subscription Health Check

```ruby
def check_subscription_health
  user_info = client.user.get_user
  subscription = user_info['subscription']
  issues = []
  
  # Check character usage
  usage_percent = (subscription['character_count'].to_f / subscription['character_limit'] * 100)
  if usage_percent > 95
    issues << "Critical: Character usage at #{usage_percent.round(1)}%"
  elsif usage_percent > 80
    issues << "Warning: Character usage at #{usage_percent.round(1)}%"
  end
  
  # Check voice slots
  voice_usage_percent = (subscription['voice_slots_used'].to_f / subscription['voice_limit'] * 100)
  if voice_usage_percent > 95
    issues << "Critical: Voice slots at #{voice_usage_percent.round(1)}%"
  elsif voice_usage_percent > 80
    issues << "Warning: Voice slots at #{voice_usage_percent.round(1)}%"
  end
  
  # Check voice add/edit limit
  edit_usage_percent = (subscription['voice_add_edit_counter'].to_f / subscription['max_voice_add_edits'] * 100)
  if edit_usage_percent > 95
    issues << "Critical: Voice edit limit at #{edit_usage_percent.round(1)}%"
  elsif edit_usage_percent > 80
    issues << "Warning: Voice edit limit at #{edit_usage_percent.round(1)}%"
  end
  
  # Check moderation status
  extras = user_info['subscription_extras']
  if extras&.dig('moderation', 'is_in_probation')
    issues << "Critical: Account is in probation"
  end
  
  if extras&.dig('moderation', 'on_watchlist')
    issues << "Warning: Account is on watchlist"
  end
  
  if issues.empty?
    puts "✅ Subscription health: All good!"
  else
    puts "⚠️  Subscription issues found:"
    issues.each { |issue| puts "  - #{issue}" }
  end
  
  issues
end
```

### Usage Monitoring

```ruby
def monitor_usage_limits
  user_info = client.user.get_user
  subscription = user_info['subscription']
  
  # Calculate days until reset
  if subscription['next_character_count_reset_unix']
    days_until_reset = (subscription['next_character_count_reset_unix'] - Time.now.to_i) / (24 * 60 * 60)
    
    # Calculate daily usage budget
    remaining_chars = subscription['character_limit'] - subscription['character_count']
    daily_budget = remaining_chars / days_until_reset if days_until_reset > 0
    
    puts "Usage Budget Analysis:"
    puts "  Remaining characters: #{remaining_chars}"
    puts "  Days until reset: #{days_until_reset.round(1)}"
    puts "  Daily budget: #{daily_budget&.round(0) || 'N/A'} characters"
    
    if daily_budget && daily_budget < 1000
      puts "  ⚠️  Low daily budget - consider upgrading plan"
    end
  end
end
```

### Feature Availability Check

```ruby
def check_feature_availability
  user_info = client.user.get_user
  subscription = user_info['subscription']
  extras = user_info['subscription_extras']
  
  features = {
    "Instant Voice Cloning" => subscription['can_use_instant_voice_cloning'],
    "Professional Voice Cloning" => subscription['can_use_professional_voice_cloning'],
    "Character Limit Extension" => subscription['can_extend_character_limit'],
    "Voice Limit Extension" => subscription['can_extend_voice_limit'],
    "Delayed Payment Methods" => user_info['can_use_delayed_payment_methods'],
    "Voice Captcha Bypass" => extras&.dig('can_bypass_voice_captcha'),
    "Manual Pro Voice Verification" => extras&.dig('can_request_manual_pro_voice_verification'),
    "Force Logging Disabled" => extras&.dig('force_logging_disabled')
  }
  
  puts "Feature Availability:"
  features.each do |feature, available|
    status = available ? "✅" : "❌"
    puts "  #{feature}: #{status}"
  end
  
  features
end
```

## Error Handling

```ruby
begin
  user_info = client.user.get_user
  puts "User loaded successfully: #{user_info['user_id']}"
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key - please check your credentials"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Request error: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Rails Integration Example

```ruby
class UserDashboardController < ApplicationController
  before_action :initialize_client
  
  def show
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    @subscription_extras = @user_info['subscription_extras']
    
    # Calculate usage percentages
    @character_usage_percent = calculate_usage_percent(
      @subscription['character_count'],
      @subscription['character_limit']
    )
    
    @voice_usage_percent = calculate_usage_percent(
      @subscription['voice_slots_used'],
      @subscription['voice_limit']
    )
    
    @voice_edit_percent = calculate_usage_percent(
      @subscription['voice_add_edit_counter'],
      @subscription['max_voice_add_edits']
    )
    
    # Check for warnings
    @warnings = generate_warnings
    
  rescue ElevenlabsClient::APIError => e
    flash[:error] = "Unable to load user information: #{e.message}"
    @user_info = {}
  end
  
  def usage_json
    user_info = @client.user.get_user
    
    render json: {
      character_usage: {
        used: user_info['subscription']['character_count'],
        limit: user_info['subscription']['character_limit'],
        percentage: calculate_usage_percent(
          user_info['subscription']['character_count'],
          user_info['subscription']['character_limit']
        )
      },
      voice_usage: {
        used: user_info['subscription']['voice_slots_used'],
        limit: user_info['subscription']['voice_limit'],
        percentage: calculate_usage_percent(
          user_info['subscription']['voice_slots_used'],
          user_info['subscription']['voice_limit']
        )
      },
      next_reset: user_info['subscription']['next_character_count_reset_unix']
    }
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def calculate_usage_percent(used, limit)
    return 0 if limit.zero?
    ((used.to_f / limit) * 100).round(2)
  end
  
  def generate_warnings
    warnings = []
    
    if @character_usage_percent > 90
      warnings << "Character usage is critically high (#{@character_usage_percent}%)"
    elsif @character_usage_percent > 75
      warnings << "Character usage is high (#{@character_usage_percent}%)"
    end
    
    if @voice_usage_percent > 90
      warnings << "Voice slots are critically high (#{@voice_usage_percent}%)"
    elsif @voice_usage_percent > 75
      warnings << "Voice slots usage is high (#{@voice_usage_percent}%)"
    end
    
    if @subscription_extras&.dig('moderation', 'is_in_probation')
      warnings << "Account is currently in probation"
    end
    
    warnings
  end
end
```

## Best Practices

### Caching User Information

```ruby
# Cache user info to reduce API calls
def cached_user_info(cache_duration: 5.minutes)
  Rails.cache.fetch("user_info_#{current_user.id}", expires_in: cache_duration) do
    client.user.get_user
  end
end

# Invalidate cache when needed
def invalidate_user_cache
  Rails.cache.delete("user_info_#{current_user.id}")
end
```

### Monitoring and Alerts

```ruby
def setup_usage_alerts
  user_info = client.user.get_user
  subscription = user_info['subscription']
  
  # Set up alerts at different thresholds
  character_percent = (subscription['character_count'].to_f / subscription['character_limit'] * 100)
  
  case character_percent
  when 90..Float::INFINITY
    send_critical_alert("Character usage at #{character_percent.round(1)}%")
  when 75..90
    send_warning_alert("Character usage at #{character_percent.round(1)}%")
  when 50..75
    send_info_alert("Character usage at #{character_percent.round(1)}%")
  end
end

def send_critical_alert(message)
  # Send to Slack, email, or other alerting system
  puts "🚨 CRITICAL: #{message}"
end

def send_warning_alert(message)
  puts "⚠️  WARNING: #{message}"
end

def send_info_alert(message)
  puts "ℹ️  INFO: #{message}"
end
```

## Use Cases

### Account Management
- **Usage Monitoring** - Track character and voice usage
- **Limit Management** - Monitor approaching limits
- **Feature Access** - Check available features and capabilities
- **Billing Information** - View subscription and billing details

### Application Logic
- **Feature Gates** - Enable/disable features based on subscription
- **Usage Limits** - Enforce client-side limits
- **User Experience** - Customize UI based on user capabilities
- **Upgrade Prompts** - Show upgrade suggestions when appropriate

### Monitoring and Alerts
- **Usage Alerts** - Notify when approaching limits
- **Account Status** - Monitor for moderation issues
- **Subscription Health** - Track subscription status changes
- **API Key Management** - Monitor API key status

## Limitations

- **Real-time Data**: Some information may have slight delays
- **API Key Visibility**: API key may be hidden for security
- **Rate Limits**: User info calls count toward rate limits
- **Caching**: Consider caching to reduce API calls

## Performance Tips

1. **Cache User Data**: Cache user information for short periods
2. **Selective Updates**: Only fetch user info when needed
3. **Background Checks**: Use background jobs for monitoring
4. **Error Handling**: Implement robust error handling
5. **Graceful Degradation**: Handle API failures gracefully
