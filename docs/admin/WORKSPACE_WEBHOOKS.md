# Workspace Webhooks

The workspace webhooks endpoint allows you to list all webhooks configured for your workspace.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
workspace_webhooks = client.workspace_webhooks
```

## Available Methods

### List Workspace Webhooks

List all webhooks currently configured for the workspace.

```ruby
# Basic listing
webhooks = client.workspace_webhooks.list

webhooks["webhooks"].each do |webhook|
  puts "Webhook: #{webhook['name']}"
  puts "  ID: #{webhook['webhook_id']}"
  puts "  URL: #{webhook['webhook_url']}"
  puts "  Enabled: #{!webhook['is_disabled']}"
  puts "  Auto-disabled: #{webhook['is_auto_disabled']}"
  puts "  Created: #{Time.at(webhook['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
  puts "  Auth Type: #{webhook['auth_type']}"
  
  if webhook['usage']
    puts "  Usage Types:"
    webhook['usage'].each do |usage|
      puts "    - #{usage['usage_type']}"
    end
  end
  
  if webhook['most_recent_failure_error_code']
    puts "  Last Failure: #{webhook['most_recent_failure_error_code']} at #{Time.at(webhook['most_recent_failure_timestamp']).strftime('%Y-%m-%d %H:%M:%S')}"
  end
  puts
end
```

### List Webhooks with Usage Information (Admin Only)

Include active usage information for webhooks (only available for workspace administrators).

```ruby
# Include usage information (admin only)
webhooks_with_usage = client.workspace_webhooks.list(include_usages: true)

webhooks_with_usage["webhooks"].each do |webhook|
  puts "Webhook: #{webhook['name']}"
  puts "  Active Usages: #{webhook['usage']&.length || 0}"
  
  if webhook['usage']
    webhook['usage'].each do |usage|
      puts "    - #{usage['usage_type']}"
    end
  end
end
```

## Examples

### Webhook Health Monitoring

```ruby
def monitor_webhook_health
  puts "🔍 Webhook Health Monitoring"
  puts "=" * 30
  
  webhooks = client.workspace_webhooks.list
  
  if webhooks["webhooks"].empty?
    puts "No webhooks configured."
    return
  end
  
  healthy_webhooks = 0
  unhealthy_webhooks = 0
  disabled_webhooks = 0
  
  webhooks["webhooks"].each do |webhook|
    name = webhook['name']
    
    if webhook['is_disabled']
      puts "🔴 #{name}: DISABLED"
      disabled_webhooks += 1
    elsif webhook['is_auto_disabled']
      puts "🟡 #{name}: AUTO-DISABLED (due to failures)"
      unhealthy_webhooks += 1
    elsif webhook['most_recent_failure_error_code']
      puts "🟠 #{name}: HAS RECENT FAILURES (#{webhook['most_recent_failure_error_code']})"
      unhealthy_webhooks += 1
    else
      puts "🟢 #{name}: HEALTHY"
      healthy_webhooks += 1
    end
    
    puts "   URL: #{webhook['webhook_url']}"
    puts "   Auth: #{webhook['auth_type']}"
    puts "   Created: #{Time.at(webhook['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
    
    if webhook['most_recent_failure_timestamp']
      puts "   Last Failure: #{Time.at(webhook['most_recent_failure_timestamp']).strftime('%Y-%m-%d %H:%M:%S')}"
    end
    puts
  end
  
  puts "📊 Summary:"
  puts "Healthy: #{healthy_webhooks}"
  puts "Unhealthy: #{unhealthy_webhooks}"
  puts "Disabled: #{disabled_webhooks}"
  puts "Total: #{webhooks['webhooks'].length}"
end

monitor_webhook_health
```

### Webhook Configuration Audit

```ruby
def audit_webhook_configuration
  puts "📋 Webhook Configuration Audit"
  puts "=" * 35
  
  begin
    webhooks = client.workspace_webhooks.list(include_usages: true)
  rescue ElevenlabsClient::ForbiddenError
    puts "⚠️ Admin access required for usage information"
    webhooks = client.workspace_webhooks.list
  end
  
  webhooks["webhooks"].each_with_index do |webhook, index|
    puts "#{index + 1}. #{webhook['name']}"
    puts "   Status: #{webhook['is_disabled'] ? 'Disabled' : 'Enabled'}"
    puts "   URL: #{webhook['webhook_url']}"
    puts "   Authentication: #{webhook['auth_type']}"
    
    # Security check
    if webhook['webhook_url'].start_with?('http://')
      puts "   ⚠️ SECURITY WARNING: Using HTTP instead of HTTPS"
    end
    
    # Usage analysis
    if webhook['usage']
      puts "   Active Usages:"
      webhook['usage'].each do |usage|
        puts "     - #{usage['usage_type']}"
      end
    else
      puts "   Usage: Not available (requires admin access)"
    end
    
    # Reliability analysis
    if webhook['is_auto_disabled']
      puts "   ❌ RELIABILITY ISSUE: Auto-disabled due to failures"
    elsif webhook['most_recent_failure_error_code']
      failure_time = Time.at(webhook['most_recent_failure_timestamp'])
      days_since_failure = (Time.now - failure_time) / (60 * 60 * 24)
      puts "   ⚠️ Last failure: #{webhook['most_recent_failure_error_code']} (#{days_since_failure.round(1)} days ago)"
    else
      puts "   ✅ No recent failures"
    end
    
    puts
  end
end

audit_webhook_configuration
```

### Webhook Performance Analysis

```ruby
def analyze_webhook_performance
  puts "📈 Webhook Performance Analysis"
  puts "=" * 35
  
  webhooks = client.workspace_webhooks.list
  
  if webhooks["webhooks"].empty?
    puts "No webhooks to analyze."
    return
  end
  
  # Group webhooks by status
  by_status = {
    active: [],
    disabled: [],
    auto_disabled: [],
    with_failures: []
  }
  
  webhooks["webhooks"].each do |webhook|
    if webhook['is_disabled']
      by_status[:disabled] << webhook
    elsif webhook['is_auto_disabled']
      by_status[:auto_disabled] << webhook
    elsif webhook['most_recent_failure_error_code']
      by_status[:with_failures] << webhook
    else
      by_status[:active] << webhook
    end
  end
  
  total = webhooks["webhooks"].length
  
  puts "📊 Status Distribution:"
  puts "Active & Healthy: #{by_status[:active].length} (#{(by_status[:active].length.to_f / total * 100).round(1)}%)"
  puts "With Recent Failures: #{by_status[:with_failures].length} (#{(by_status[:with_failures].length.to_f / total * 100).round(1)}%)"
  puts "Auto-disabled: #{by_status[:auto_disabled].length} (#{(by_status[:auto_disabled].length.to_f / total * 100).round(1)}%)"
  puts "Manually Disabled: #{by_status[:disabled].length} (#{(by_status[:disabled].length.to_f / total * 100).round(1)}%)"
  
  # Auth type analysis
  auth_types = webhooks["webhooks"].group_by { |w| w['auth_type'] }
  puts "\n🔐 Authentication Methods:"
  auth_types.each do |auth_type, hooks|
    puts "#{auth_type}: #{hooks.length}"
  end
  
  # Age analysis
  puts "\n📅 Age Analysis:"
  now = Time.now
  age_groups = { 
    "< 1 month" => 0,
    "1-6 months" => 0, 
    "6-12 months" => 0,
    "> 1 year" => 0
  }
  
  webhooks["webhooks"].each do |webhook|
    created_time = Time.at(webhook['created_at_unix'])
    days_old = (now - created_time) / (60 * 60 * 24)
    
    if days_old < 30
      age_groups["< 1 month"] += 1
    elsif days_old < 180
      age_groups["1-6 months"] += 1
    elsif days_old < 365
      age_groups["6-12 months"] += 1
    else
      age_groups["> 1 year"] += 1
    end
  end
  
  age_groups.each do |range, count|
    puts "#{range}: #{count}"
  end
  
  # Recommendations
  puts "\n💡 Recommendations:"
  
  if by_status[:auto_disabled].any?
    puts "• #{by_status[:auto_disabled].length} webhook(s) auto-disabled - investigate and fix underlying issues"
  end
  
  if by_status[:with_failures].any?
    puts "• #{by_status[:with_failures].length} webhook(s) have recent failures - monitor and address issues"
  end
  
  insecure_webhooks = webhooks["webhooks"].count { |w| w['webhook_url'].start_with?('http://') }
  if insecure_webhooks > 0
    puts "• #{insecure_webhooks} webhook(s) using HTTP - migrate to HTTPS for security"
  end
  
  if by_status[:active].length.to_f / total < 0.8
    puts "• Overall webhook health is below 80% - review configuration and reliability"
  end
end

analyze_webhook_performance
```

## Error Handling

```ruby
begin
  webhooks = client.workspace_webhooks.list
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::ForbiddenError => e
  puts "Access denied: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Response Format

The webhook list response includes:

- **name**: Human-readable webhook name
- **webhook_id**: Unique webhook identifier
- **webhook_url**: Target URL for webhook calls
- **is_disabled**: Whether the webhook is manually disabled
- **is_auto_disabled**: Whether the webhook was automatically disabled due to failures
- **created_at_unix**: Unix timestamp of webhook creation
- **auth_type**: Authentication method (e.g., "hmac")
- **usage**: Array of usage types (admin only with `include_usages: true`)
- **most_recent_failure_error_code**: HTTP error code of last failure
- **most_recent_failure_timestamp**: Unix timestamp of last failure

## Best Practices

### Security
1. **Use HTTPS**: Always use HTTPS URLs for webhook endpoints
2. **Verify Authentication**: Ensure proper HMAC verification on your webhook endpoints
3. **Monitor Access**: Regularly audit webhook configurations

### Reliability
1. **Monitor Health**: Regularly check webhook status and failure rates
2. **Handle Failures**: Implement proper error handling and retry logic in your webhook endpoints
3. **Test Endpoints**: Validate webhook endpoints are responsive before configuring

### Management
1. **Regular Audits**: Periodically review webhook configurations
2. **Remove Unused**: Clean up webhooks that are no longer needed
3. **Document Purpose**: Maintain clear documentation of what each webhook is used for

## API Reference

For detailed API documentation, visit: [ElevenLabs Workspace Webhooks API Reference](https://elevenlabs.io/docs/api-reference/workspace/webhooks)
