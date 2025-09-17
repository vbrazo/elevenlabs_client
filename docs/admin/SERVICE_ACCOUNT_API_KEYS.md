# Service Account API Keys

The service account API keys endpoints allow you to manage API keys for service accounts, including creating, updating, listing, and deleting keys.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
service_account_api_keys = client.service_account_api_keys
```

## Available Methods

### List API Keys

Get all API keys for a specific service account.

```ruby
service_account_id = "service_account_user_id_here"
api_keys = client.service_account_api_keys.list(service_account_id)

api_keys["api-keys"].each do |key|
  puts "API Key: #{key['name']}"
  puts "  Key ID: #{key['key_id']}"
  puts "  Hint: #{key['hint']}"
  puts "  Enabled: #{!key['is_disabled']}"
  puts "  Created: #{Time.at(key['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
  puts "  Permissions: #{key['permissions'].join(', ')}"
  puts "  Character Limit: #{key['character_limit'] || 'Unlimited'}"
  puts "  Characters Used: #{key['character_count']}"
  puts
end
```

### Create API Key

Create a new API key for a service account.

```ruby
# Create API key with specific permissions
new_key = client.service_account_api_keys.create(
  service_account_id,
  name: "Production TTS Key",
  permissions: ["text_to_speech", "voices"]
)

puts "New API Key created: #{new_key['xi-api-key']}"

# Create API key with all permissions
admin_key = client.service_account_api_keys.create(
  service_account_id,
  name: "Admin Key",
  permissions: "all"
)

# Create API key with character limit
limited_key = client.service_account_api_keys.create(
  service_account_id,
  name: "Limited Usage Key",
  permissions: ["text_to_speech"],
  character_limit: 100000  # 100k characters per month
)
```

### Update API Key

Update an existing API key's settings.

```ruby
api_key_id = "api_key_id_here"

# Update API key settings
client.service_account_api_keys.update(
  service_account_id,
  api_key_id,
  is_enabled: true,
  name: "Updated Production Key",
  permissions: ["text_to_speech", "voices", "models"]
)

# Disable an API key
client.service_account_api_keys.update(
  service_account_id,
  api_key_id,
  is_enabled: false,
  name: "Disabled Development Key",
  permissions: ["text_to_speech"]
)

# Update character limit
client.service_account_api_keys.update(
  service_account_id,
  api_key_id,
  is_enabled: true,
  name: "Limited Production Key",
  permissions: ["text_to_speech"],
  character_limit: 500000  # Increase to 500k characters
)
```

### Delete API Key

Delete an API key permanently.

```ruby
api_key_id = "api_key_id_here"

client.service_account_api_keys.delete(service_account_id, api_key_id)
puts "API key deleted successfully"
```

## Examples

### Complete API Key Management Workflow

```ruby
def manage_service_account_api_keys(service_account_id)
  puts "🔑 Service Account API Key Management"
  puts "=" * 45
  puts "Service Account ID: #{service_account_id}"
  
  # Step 1: List existing API keys
  puts "\n1️⃣ Current API Keys:"
  api_keys = client.service_account_api_keys.list(service_account_id)
  
  if api_keys["api-keys"].empty?
    puts "No API keys found."
  else
    api_keys["api-keys"].each do |key|
      status = key['is_disabled'] ? "❌ Disabled" : "✅ Enabled"
      usage_percent = key['character_limit'] ? (key['character_count'].to_f / key['character_limit'] * 100).round(1) : 0
      
      puts "#{key['name']} (#{key['key_id']})"
      puts "  Status: #{status}"
      puts "  Permissions: #{key['permissions'].join(', ')}"
      puts "  Usage: #{key['character_count']} chars"
      
      if key['character_limit']
        puts "  Limit: #{key['character_limit']} chars (#{usage_percent}% used)"
        if usage_percent > 80
          puts "  ⚠️  WARNING: High usage (#{usage_percent}%)"
        end
      else
        puts "  Limit: Unlimited"
      end
      puts
    end
  end
  
  # Step 2: Create a new API key
  puts "\n2️⃣ Creating New API Key:"
  new_key = client.service_account_api_keys.create(
    service_account_id,
    name: "Ruby Client Demo Key",
    permissions: ["text_to_speech", "voices"],
    character_limit: 50000
  )
  
  puts "✅ Created new API key"
  puts "Key: #{new_key['xi-api-key']}"
  puts "⚠️  Save this key securely - it won't be shown again!"
  
  # Step 3: List keys again to see the new one
  puts "\n3️⃣ Updated API Keys List:"
  updated_keys = client.service_account_api_keys.list(service_account_id)
  new_key_info = updated_keys["api-keys"].find { |k| k['name'] == "Ruby Client Demo Key" }
  
  if new_key_info
    puts "New key successfully created:"
    puts "  ID: #{new_key_info['key_id']}"
    puts "  Name: #{new_key_info['name']}"
    puts "  Permissions: #{new_key_info['permissions'].join(', ')}"
    puts "  Character Limit: #{new_key_info['character_limit']}"
  end
  
  # Step 4: Update the key (for demo purposes)
  puts "\n4️⃣ Updating API Key:"
  if new_key_info
    client.service_account_api_keys.update(
      service_account_id,
      new_key_info['key_id'],
      is_enabled: true,
      name: "Ruby Client Demo Key (Updated)",
      permissions: ["text_to_speech", "voices", "models"],
      character_limit: 75000
    )
    puts "✅ API key updated successfully"
  end
  
  # Step 5: Clean up (delete the demo key)
  puts "\n5️⃣ Cleaning Up:"
  if new_key_info
    client.service_account_api_keys.delete(service_account_id, new_key_info['key_id'])
    puts "✅ Demo API key deleted"
  end
  
  puts "\n🎉 API key management workflow completed!"
end

# Usage
manage_service_account_api_keys("your_service_account_id")
```

### API Key Security Audit

```ruby
def audit_api_key_security(service_account_id)
  puts "🔒 API Key Security Audit"
  puts "=" * 30
  
  api_keys = client.service_account_api_keys.list(service_account_id)
  
  if api_keys["api-keys"].empty?
    puts "No API keys to audit."
    return
  end
  
  security_issues = []
  
  api_keys["api-keys"].each do |key|
    puts "\n🔑 #{key['name']} (#{key['key_id']})"
    
    # Check if key is enabled
    if key['is_disabled']
      puts "  ✅ Status: Disabled (secure)"
    else
      puts "  ⚠️  Status: Enabled"
    end
    
    # Check permissions
    if key['permissions'].include?("all") || key['permissions'] == "all"
      puts "  ❌ SECURITY RISK: Has 'all' permissions"
      security_issues << "#{key['name']}: Overprivileged (all permissions)"
    else
      puts "  ✅ Permissions: Limited to #{key['permissions'].join(', ')}"
    end
    
    # Check character limit
    if key['character_limit']
      usage_percent = (key['character_count'].to_f / key['character_limit'] * 100).round(1)
      puts "  ✅ Character Limit: #{key['character_limit']} (#{usage_percent}% used)"
      
      if usage_percent > 90
        security_issues << "#{key['name']}: Near usage limit (#{usage_percent}%)"
      end
    else
      puts "  ⚠️  Character Limit: Unlimited"
      security_issues << "#{key['name']}: No usage limits set"
    end
    
    # Check age
    created_time = Time.at(key['created_at_unix'])
    days_old = (Time.now - created_time) / (60 * 60 * 24)
    
    if days_old > 365
      puts "  ⚠️  Age: #{days_old.round} days (consider rotation)"
      security_issues << "#{key['name']}: Very old key (#{days_old.round} days)"
    elsif days_old > 180
      puts "  ⚠️  Age: #{days_old.round} days"
    else
      puts "  ✅ Age: #{days_old.round} days"
    end
  end
  
  # Summary
  puts "\n📊 Security Summary:"
  puts "Total API Keys: #{api_keys['api-keys'].length}"
  puts "Security Issues: #{security_issues.length}"
  
  if security_issues.any?
    puts "\n❌ Issues Found:"
    security_issues.each do |issue|
      puts "  • #{issue}"
    end
    
    puts "\n💡 Recommendations:"
    puts "  • Rotate old API keys (> 6 months)"
    puts "  • Set character limits on all keys"
    puts "  • Use least-privilege permissions"
    puts "  • Disable unused keys"
  else
    puts "\n✅ No security issues found!"
  end
end

# Usage
audit_api_key_security("your_service_account_id")
```

### API Key Usage Monitoring

```ruby
def monitor_api_key_usage(service_account_id)
  puts "📊 API Key Usage Monitoring"
  puts "=" * 35
  
  api_keys = client.service_account_api_keys.list(service_account_id)
  
  if api_keys["api-keys"].empty?
    puts "No API keys to monitor."
    return
  end
  
  total_usage = 0
  keys_near_limit = []
  unlimited_keys = []
  
  puts "Key Usage Overview:"
  puts "-" * 50
  
  api_keys["api-keys"].each do |key|
    usage = key['character_count']
    limit = key['character_limit']
    
    total_usage += usage
    
    if limit
      usage_percent = (usage.to_f / limit * 100).round(1)
      bar_length = 20
      filled = (usage_percent / 5).round
      bar = "█" * filled + "░" * (bar_length - filled)
      
      puts "#{key['name']}"
      puts "  [#{bar}] #{usage_percent}%"
      puts "  #{usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} / #{limit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters"
      
      if usage_percent > 80
        keys_near_limit << { name: key['name'], usage_percent: usage_percent }
      end
    else
      unlimited_keys << key['name']
      puts "#{key['name']}"
      puts "  Unlimited usage"
      puts "  #{usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters used"
    end
    
    puts "  Status: #{key['is_disabled'] ? 'Disabled' : 'Active'}"
    puts
  end
  
  # Summary statistics
  puts "📈 Usage Statistics:"
  puts "Total Characters Used: #{total_usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  puts "Active Keys: #{api_keys['api-keys'].count { |k| !k['is_disabled'] }}"
  puts "Total Keys: #{api_keys['api-keys'].length}"
  
  # Alerts
  if keys_near_limit.any?
    puts "\n⚠️  Keys Near Limit:"
    keys_near_limit.each do |key_info|
      puts "  • #{key_info[:name]}: #{key_info[:usage_percent]}%"
    end
  end
  
  if unlimited_keys.any?
    puts "\n📝 Unlimited Keys:"
    unlimited_keys.each do |name|
      puts "  • #{name}"
    end
  end
  
  # Recommendations
  puts "\n💡 Recommendations:"
  
  if keys_near_limit.any?
    puts "  • Monitor high-usage keys closely"
    puts "  • Consider increasing limits for keys near capacity"
  end
  
  if unlimited_keys.any?
    puts "  • Consider setting character limits on unlimited keys"
  end
  
  disabled_keys = api_keys['api-keys'].count { |k| k['is_disabled'] }
  if disabled_keys > 0
    puts "  • Remove or clean up #{disabled_keys} disabled key(s)"
  end
end

# Usage
monitor_api_key_usage("your_service_account_id")
```

### Bulk API Key Management

```ruby
def bulk_manage_api_keys(service_account_id, operations)
  puts "🔧 Bulk API Key Management"
  puts "=" * 30
  
  results = {
    created: [],
    updated: [],
    deleted: [],
    errors: []
  }
  
  operations.each do |operation|
    begin
      case operation[:action]
      when :create
        new_key = client.service_account_api_keys.create(
          service_account_id,
          name: operation[:name],
          permissions: operation[:permissions],
          **(operation[:options] || {})
        )
        results[:created] << { name: operation[:name], key: new_key['xi-api-key'] }
        puts "✅ Created: #{operation[:name]}"
        
      when :update
        client.service_account_api_keys.update(
          service_account_id,
          operation[:key_id],
          is_enabled: operation[:is_enabled],
          name: operation[:name],
          permissions: operation[:permissions],
          **(operation[:options] || {})
        )
        results[:updated] << operation[:name]
        puts "✅ Updated: #{operation[:name]}"
        
      when :delete
        client.service_account_api_keys.delete(service_account_id, operation[:key_id])
        results[:deleted] << operation[:name]
        puts "✅ Deleted: #{operation[:name]}"
        
      else
        raise "Unknown operation: #{operation[:action]}"
      end
      
    rescue => e
      error_msg = "#{operation[:name]}: #{e.message}"
      results[:errors] << error_msg
      puts "❌ Error: #{error_msg}"
    end
    
    # Rate limiting
    sleep(0.5)
  end
  
  # Summary
  puts "\n📊 Bulk Operation Summary:"
  puts "Created: #{results[:created].length}"
  puts "Updated: #{results[:updated].length}"
  puts "Deleted: #{results[:deleted].length}"
  puts "Errors: #{results[:errors].length}"
  
  if results[:errors].any?
    puts "\n❌ Errors:"
    results[:errors].each { |error| puts "  • #{error}" }
  end
  
  results
end

# Usage example
operations = [
  {
    action: :create,
    name: "Production TTS Key",
    permissions: ["text_to_speech"],
    options: { character_limit: 1000000 }
  },
  {
    action: :create,
    name: "Development Key",
    permissions: ["text_to_speech", "voices"],
    options: { character_limit: 100000 }
  }
]

bulk_manage_api_keys("your_service_account_id", operations)
```

## Error Handling

```ruby
begin
  api_keys = client.service_account_api_keys.list(service_account_id)
rescue ElevenlabsClient::NotFoundError => e
  puts "Service account not found: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::ForbiddenError => e
  puts "Access denied: #{e.message}"
rescue ElevenlabsClient::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Permission Types

Available permissions for API keys:

- `"text_to_speech"` - Text-to-speech conversion
- `"voices"` - Voice management
- `"models"` - Model access
- `"speech_to_text"` - Speech-to-text conversion
- `"audio_native"` - Audio native features
- `"usage"` - Usage statistics
- `"all"` - All permissions (use with caution)

## Best Practices

### Security
1. **Least Privilege**: Grant only necessary permissions
2. **Character Limits**: Set appropriate usage limits
3. **Regular Rotation**: Rotate keys periodically (every 6-12 months)
4. **Monitor Usage**: Track character consumption and usage patterns

### Management
1. **Descriptive Names**: Use clear, descriptive names for API keys
2. **Documentation**: Document the purpose of each API key
3. **Regular Audits**: Periodically review API key configurations
4. **Clean Up**: Remove unused or old API keys

### Monitoring
1. **Usage Tracking**: Monitor character usage against limits
2. **Health Checks**: Verify API keys are working as expected
3. **Alert Thresholds**: Set up alerts for keys approaching limits
4. **Access Logs**: Review API key usage patterns

## API Reference

For detailed API documentation, visit: [ElevenLabs Service Account API Keys API Reference](https://elevenlabs.io/docs/api-reference/service-accounts/api-keys)
