# Agents Platform: Workspace Management

Manage workspace settings, secrets, and dashboard configurations for the Conversational AI platform.

## Available Methods

### Settings Management
- `client.workspace.get_settings()` - Retrieve workspace settings
- `client.workspace.update_settings(**options)` - Update workspace settings

### Secrets Management
- `client.workspace.get_secrets()` - Get all workspace secrets
- `client.workspace.create_secret(name:, value:, type: "new")` - Create a new secret
- `client.workspace.update_secret(secret_id, name:, value:, type: "update")` - Update an existing secret
- `client.workspace.delete_secret(secret_id)` - Delete a secret

### Dashboard Management
- `client.workspace.get_dashboard_settings()` - Retrieve dashboard settings
- `client.workspace.update_dashboard_settings(charts: nil)` - Update dashboard settings

### Convenience Aliases
- `client.workspace.settings()` - Alias for get_settings
- `client.workspace.secrets()` - Alias for get_secrets
- `client.workspace.dashboard_settings()` - Alias for get_dashboard_settings

## Usage Examples

### Basic Settings Management

```ruby
client = ElevenlabsClient.new

# Get current workspace settings
settings = client.workspace.get_settings
puts settings["can_use_mcp_servers"]
puts settings["rag_retention_period_days"]

# Update workspace settings
updated_settings = client.workspace.update_settings(
  can_use_mcp_servers: true,
  rag_retention_period_days: 15,
  default_livekit_stack: "standard"
)
```

### Webhook Configuration

```ruby
# Configure conversation initiation webhook
client.workspace.update_settings(
  conversation_initiation_client_data_webhook: {
    url: "https://myapp.com/webhook",
    request_headers: {
      "Authorization" => "Bearer my-token",
      "Content-Type" => "application/json"
    }
  }
)

# Configure post-call webhook
client.workspace.update_settings(
  webhooks: {
    post_call_webhook_id: "webhook_123",
    send_audio: true
  }
)
```

### Secrets Management

```ruby
# Get all workspace secrets
secrets = client.workspace.get_secrets
secrets["secrets"].each do |secret|
  puts "Secret: #{secret['name']} (ID: #{secret['secret_id']})"
  puts "Used by tools: #{secret['used_by']['tools'].length}"
  puts "Used by agents: #{secret['used_by']['agents'].length}"
end

# Create a new secret
new_secret = client.workspace.create_secret(
  name: "my_api_key",
  value: "sk-1234567890abcdef"
)
puts "Created secret with ID: #{new_secret['secret_id']}"

# Update an existing secret
updated_secret = client.workspace.update_secret(
  new_secret["secret_id"],
  name: "updated_api_key",
  value: "sk-newvalue1234567890"
)

# Delete a secret (only if not in use)
client.workspace.delete_secret(new_secret["secret_id"])
```

### Dashboard Configuration

```ruby
# Get current dashboard settings
dashboard = client.workspace.get_dashboard_settings
puts "Current charts: #{dashboard['charts']}"

# Update dashboard with custom charts
client.workspace.update_dashboard_settings(
  charts: [
    {
      name: "Call Success Rate",
      type: "call_success"
    },
    {
      name: "Conversation Duration",
      type: "conversation_duration"
    }
  ]
)
```

### Advanced Settings Configuration

```ruby
# Complete workspace configuration
client.workspace.update_settings(
  # Enable MCP servers
  can_use_mcp_servers: true,
  
  # Set RAG retention to maximum
  rag_retention_period_days: 30,
  
  # Use standard LiveKit stack
  default_livekit_stack: "standard",
  
  # Configure conversation webhook
  conversation_initiation_client_data_webhook: {
    url: "https://api.mycompany.com/convai/init",
    request_headers: {
      "Authorization" => "Bearer #{ENV['WEBHOOK_TOKEN']}",
      "X-Source" => "elevenlabs-convai"
    }
  },
  
  # Configure post-call processing
  webhooks: {
    post_call_webhook_id: "post_call_webhook_123",
    send_audio: true
  }
)
```

### Secret Usage Analysis

```ruby
# Analyze secret usage across workspace
secrets = client.workspace.get_secrets

secrets["secrets"].each do |secret|
  usage = secret["used_by"]
  
  puts "\n=== Secret: #{secret['name']} ==="
  puts "ID: #{secret['secret_id']}"
  puts "Type: #{secret['type']}"
  
  if usage["tools"].any?
    puts "Used by #{usage['tools'].length} tools"
  end
  
  if usage["agents"].any?
    puts "Used by #{usage['agents'].length} agents"
  end
  
  if usage["phone_numbers"].any?
    puts "Used by phone numbers:"
    usage["phone_numbers"].each do |phone|
      puts "  - #{phone['phone_number']} (#{phone['label']}) via #{phone['provider']}"
    end
  end
  
  if usage["others"].any?
    puts "Used by other services: #{usage['others'].join(', ')}"
  end
  
  # Check if secret is safe to delete
  total_usage = usage["tools"].length + usage["agents"].length + 
                usage["phone_numbers"].length + usage["others"].length
  
  if total_usage == 0
    puts "✅ Safe to delete - not in use"
  else
    puts "⚠️  Cannot delete - in use by #{total_usage} resources"
  end
end
```

### Dashboard Customization

```ruby
# Set up comprehensive dashboard
charts = [
  { name: "Call Success Rate", type: "call_success" },
  { name: "Average Duration", type: "conversation_duration" },
  { name: "Daily Volume", type: "daily_volume" },
  { name: "Cost Analysis", type: "cost_analysis" }
]

updated_dashboard = client.workspace.update_dashboard_settings(charts: charts)

puts "Dashboard updated with #{updated_dashboard['charts'].length} charts"
```

## Settings Configuration Reference

### Conversation Initiation Webhook
```ruby
conversation_initiation_client_data_webhook: {
  url: "https://your-endpoint.com/webhook",     # Required: Webhook URL
  request_headers: {                            # Optional: Custom headers
    "Authorization" => "Bearer token",
    "Custom-Header" => "value"
  }
}
```

### Webhook Settings
```ruby
webhooks: {
  post_call_webhook_id: "webhook_id",          # Optional: Post-call webhook ID
  send_audio: true                             # Optional: Whether to send audio
}
```

### Available Settings
- `can_use_mcp_servers` (Boolean): Enable MCP server usage
- `rag_retention_period_days` (Integer, ≤30): RAG data retention period
- `default_livekit_stack` (String): "standard" or "static"

## Secret Types and Usage

### Secret Types
- `"new"` - Creating a new secret
- `"update"` - Updating an existing secret
- `"stored"` - Response type for stored secrets

### Usage Tracking
Secrets track usage across:
- **Tools**: Tools that reference the secret
- **Agents**: Agents that use the secret
- **Phone Numbers**: Phone integrations using the secret
- **Others**: System services (e.g., "conversation_initiation_webhook")

## Dashboard Chart Types

Available chart types for dashboard configuration:
- `"call_success"` - Call success rate metrics
- `"conversation_duration"` - Duration analytics
- `"daily_volume"` - Daily call volume
- `"cost_analysis"` - Cost breakdown

## Error Handling

```ruby
begin
  # Workspace operation
  client.workspace.update_settings(rag_retention_period_days: 35) # Invalid: >30
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Validation error: #{e.message}"
rescue ElevenlabsClient::ForbiddenError => e
  puts "Permission denied: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end

# Safe secret deletion
begin
  client.workspace.delete_secret("secret_123")
  puts "Secret deleted successfully"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Cannot delete: Secret is still in use"
end
```

## Notes

- **Settings**: Only workspace administrators can modify settings
- **Secrets**: Cannot delete secrets that are currently in use by tools, agents, or other services
- **RAG Retention**: Maximum retention period is 30 days
- **Webhooks**: Webhook URLs must be accessible and return appropriate responses
- **MCP Servers**: Requires appropriate workspace permissions
- **Dashboard**: Chart configurations are workspace-wide settings
