# MCP Servers Management

Manage Model Context Protocol (MCP) servers for extending conversational AI agents with custom tools and capabilities.

## Overview

MCP (Model Context Protocol) servers provide external tools and capabilities that can be used by conversational AI agents. These servers act as middleware between your agents and external systems, APIs, or databases.

### Integration with Agents

Once configured, MCP servers can be referenced in agent configurations to provide additional capabilities:

```ruby
# Create MCP server
mcp_server = client.mcp_servers.create(config: { ... })

# Use in agent configuration
agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a helpful assistant with access to business tools.",
        native_mcp_server_ids: [mcp_server["id"]]
      }
    }
  }
)
```

See the [Agents Documentation](AGENTS.md) for more details on integrating MCP servers with agents.

## Available Methods

### Server Management
- `client.mcp_servers.create(config:)` - Create a new MCP server configuration
- `client.mcp_servers.list()` - List all MCP servers in the workspace
- `client.mcp_servers.get(mcp_server_id)` - Get specific MCP server details

### Policy Management
- `client.mcp_servers.update_approval_policy(mcp_server_id, approval_policy:)` - Update server approval policy

### Tool Approval Management
- `client.mcp_servers.create_tool_approval(mcp_server_id, tool_name:, tool_description:, **options)` - Approve a specific tool
- `client.mcp_servers.delete_tool_approval(mcp_server_id, tool_name)` - Remove tool approval

### Convenience Aliases
- `client.mcp_servers.servers()` - Alias for list
- `client.mcp_servers.get_server(mcp_server_id)` - Alias for get
- `client.mcp_servers.update_policy(mcp_server_id, approval_policy:)` - Alias for update_approval_policy
- `client.mcp_servers.approve_tool(mcp_server_id, tool_name:, tool_description:, **options)` - Alias for create_tool_approval
- `client.mcp_servers.remove_tool_approval(mcp_server_id, tool_name)` - Alias for delete_tool_approval

## Usage Examples

### Basic MCP Server Setup

```ruby
client = ElevenlabsClient.new

# Create a new MCP server
mcp_server = client.mcp_servers.create(
  config: {
    url: "https://my-mcp-server.com/api",
    name: "Custom Tools Server",
    approval_policy: "auto_approve_all",
    transport: "SSE",
    description: "Provides custom business tools for agents"
  }
)

puts "Created MCP server: #{mcp_server['id']}"
puts "Server name: #{mcp_server['config']['name']}"
puts "Approval policy: #{mcp_server['config']['approval_policy']}"
```

### MCP Server with Authentication

```ruby
# First, create a secret for authentication
secret = client.workspace.create_secret(
  name: "mcp_server_token",
  value: "your-secret-api-token"
)

# Create MCP server with secret authentication
mcp_server = client.mcp_servers.create(
  config: {
    url: "https://secure-mcp-server.com/api",
    name: "Secure Business API",
    approval_policy: "require_approval_per_tool",
    transport: "SSE",
    secret_token: {
      secret_id: secret["secret_id"]
    },
    request_headers: {
      "Content-Type" => "application/json",
      "User-Agent" => "ElevenLabs-Agent"
    },
    description: "Secure API for customer data and business operations"
  }
)

puts "Secure MCP server created: #{mcp_server['id']}"
```

### List and Manage MCP Servers

```ruby
# List all MCP servers in workspace
servers = client.mcp_servers.list

puts "Found #{servers['mcp_servers'].length} MCP servers:"
servers["mcp_servers"].each do |server|
  puts "\n--- #{server['config']['name']} ---"
  puts "ID: #{server['id']}"
  puts "URL: #{server['config']['url']}"
  puts "Policy: #{server['config']['approval_policy']}"
  puts "Transport: #{server['config']['transport']}"
  puts "Creator: #{server['access_info']['creator_name']} (#{server['access_info']['creator_email']})"
  puts "Dependent agents: #{server['dependent_agents'].length}"
end
```

### Get Detailed Server Information

```ruby
server_id = "mcp_server_123"

# Get detailed information about a specific server
server_details = client.mcp_servers.get(server_id)

puts "=== MCP Server Details ==="
puts "Name: #{server_details['config']['name']}"
puts "URL: #{server_details['config']['url']}"
puts "Description: #{server_details['config']['description']}"
puts "Created: #{Time.at(server_details['metadata']['created_at'])}"

puts "\nApproval Configuration:"
puts "Policy: #{server_details['config']['approval_policy']}"

if server_details['config']['tool_approval_hashes']
  puts "Approved tools:"
  server_details['config']['tool_approval_hashes'].each do |tool|
    puts "  - #{tool['tool_name']} (#{tool['approval_policy']})"
  end
end

puts "\nAccess Information:"
puts "Role: #{server_details['access_info']['role']}"
puts "Is Creator: #{server_details['access_info']['is_creator']}"

puts "\nDependencies:"
puts "Used by #{server_details['dependent_agents'].length} agents"
```

### Approval Policy Management

```ruby
server_id = "mcp_server_123"

# Update to auto-approve all tools
client.mcp_servers.update_approval_policy(
  server_id,
  approval_policy: "auto_approve_all"
)
puts "Updated to auto-approve all tools"

# Update to require approval for each tool individually
client.mcp_servers.update_approval_policy(
  server_id,
  approval_policy: "require_approval_per_tool"
)
puts "Updated to require per-tool approval"

# Update to require approval for all tools
client.mcp_servers.update_approval_policy(
  server_id,
  approval_policy: "require_approval_all"
)
puts "Updated to require approval for all tools"
```

### Tool-Specific Approval Management

```ruby
server_id = "mcp_server_123"

# Approve a specific tool
client.mcp_servers.create_tool_approval(
  server_id,
  tool_name: "get_customer_data",
  tool_description: "Retrieves customer information from CRM system",
  input_schema: {
    type: "object",
    properties: {
      customer_id: { type: "string", description: "Customer ID" },
      fields: { type: "array", items: { type: "string" } }
    },
    required: ["customer_id"]
  },
  approval_policy: "auto_approved"
)
puts "Approved tool: get_customer_data"

# Approve another tool with manual approval required
client.mcp_servers.create_tool_approval(
  server_id,
  tool_name: "update_customer_data",
  tool_description: "Updates customer information in CRM system",
  approval_policy: "requires_approval"
)
puts "Added tool requiring manual approval: update_customer_data"

# Remove tool approval
client.mcp_servers.delete_tool_approval(server_id, "get_customer_data")
puts "Removed approval for: get_customer_data"
```

### Advanced MCP Server Configuration

```ruby
# Create a comprehensive MCP server setup
def setup_enterprise_mcp_server(client)
  # Create authentication secret
  auth_secret = client.workspace.create_secret(
    name: "enterprise_api_key",
    value: ENV["ENTERPRISE_API_KEY"]
  )
  
  # Create MCP server with full configuration
  server = client.mcp_servers.create(
    config: {
      url: "https://enterprise-api.company.com/mcp",
      name: "Enterprise Business API",
      approval_policy: "require_approval_per_tool",
      transport: "SSE",
      secret_token: {
        secret_id: auth_secret["secret_id"]
      },
      request_headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{auth_secret['secret_id']}",
        "X-API-Version" => "v2",
        "User-Agent" => "ElevenLabs-ConvAI/1.0"
      },
      description: "Enterprise API providing access to CRM, inventory, and business intelligence tools"
    }
  )
  
  puts "Created enterprise MCP server: #{server['id']}"
  
  # Pre-approve safe tools
  safe_tools = [
    {
      name: "search_customers",
      description: "Search for customers by various criteria",
      schema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Search query" },
          limit: { type: "integer", description: "Result limit", default: 10 }
        }
      },
      policy: "auto_approved"
    },
    {
      name: "get_product_info",
      description: "Get detailed product information",
      schema: {
        type: "object",
        properties: {
          product_id: { type: "string", description: "Product ID" }
        },
        required: ["product_id"]
      },
      policy: "auto_approved"
    },
    {
      name: "check_inventory",
      description: "Check product inventory levels",
      schema: {
        type: "object",
        properties: {
          product_id: { type: "string" },
          location: { type: "string" }
        }
      },
      policy: "auto_approved"
    }
  ]
  
  # Approve each safe tool
  safe_tools.each do |tool|
    client.mcp_servers.create_tool_approval(
      server["id"],
      tool_name: tool[:name],
      tool_description: tool[:description],
      input_schema: tool[:schema],
      approval_policy: tool[:policy]
    )
    puts "Approved tool: #{tool[:name]}"
  end
  
  # Add tools that require manual approval
  sensitive_tools = [
    {
      name: "update_customer_record",
      description: "Update customer information - requires approval"
    },
    {
      name: "process_refund",
      description: "Process customer refund - requires approval"
    },
    {
      name: "access_financial_data",
      description: "Access sensitive financial information - requires approval"
    }
  ]
  
  sensitive_tools.each do |tool|
    client.mcp_servers.create_tool_approval(
      server["id"],
      tool_name: tool[:name],
      tool_description: tool[:description],
      approval_policy: "requires_approval"
    )
    puts "Added sensitive tool (manual approval required): #{tool[:name]}"
  end
  
  server
end

# Set up the server
enterprise_server = setup_enterprise_mcp_server(client)

# Verify the setup
puts "\n=== Setup Verification ==="
updated_server = client.mcp_servers.get(enterprise_server["id"])
puts "Total approved tools: #{updated_server['config']['tool_approval_hashes'].length}"

auto_approved = updated_server['config']['tool_approval_hashes'].select { |t| t['approval_policy'] == 'auto_approved' }
requires_approval = updated_server['config']['tool_approval_hashes'].select { |t| t['approval_policy'] == 'requires_approval' }

puts "Auto-approved tools: #{auto_approved.length}"
puts "Manual approval tools: #{requires_approval.length}"
```

### MCP Server Analytics and Monitoring

```ruby
# Monitor MCP server usage and configuration
def analyze_mcp_servers(client)
  servers = client.mcp_servers.list
  
  analysis = {
    total_servers: servers["mcp_servers"].length,
    by_policy: Hash.new(0),
    by_transport: Hash.new(0),
    total_tools: 0,
    total_dependent_agents: 0,
    servers_with_secrets: 0,
    servers_with_custom_headers: 0
  }
  
  servers["mcp_servers"].each do |server|
    config = server["config"]
    
    # Count by approval policy
    analysis[:by_policy][config["approval_policy"]] += 1
    
    # Count by transport
    analysis[:by_transport][config["transport"]] += 1
    
    # Count tools
    if config["tool_approval_hashes"]
      analysis[:total_tools] += config["tool_approval_hashes"].length
    end
    
    # Count dependent agents
    analysis[:total_dependent_agents] += server["dependent_agents"].length
    
    # Check for secrets
    analysis[:servers_with_secrets] += 1 if config["secret_token"]
    
    # Check for custom headers
    analysis[:servers_with_custom_headers] += 1 if config["request_headers"] && !config["request_headers"].empty?
  end
  
  puts "=== MCP Servers Analysis ==="
  puts "Total servers: #{analysis[:total_servers]}"
  puts "Total approved tools: #{analysis[:total_tools]}"
  puts "Total dependent agents: #{analysis[:total_dependent_agents]}"
  puts
  
  puts "Approval Policies:"
  analysis[:by_policy].each do |policy, count|
    puts "  #{policy}: #{count} servers"
  end
  puts
  
  puts "Transport Methods:"
  analysis[:by_transport].each do |transport, count|
    puts "  #{transport}: #{count} servers"
  end
  puts
  
  puts "Security Configuration:"
  puts "  Servers with authentication: #{analysis[:servers_with_secrets]}"
  puts "  Servers with custom headers: #{analysis[:servers_with_custom_headers]}"
  
  # Detailed server breakdown
  puts "\n=== Detailed Server Information ==="
  servers["mcp_servers"].each do |server|
    config = server["config"]
    puts "\n#{config['name']} (#{server['id']})"
    puts "  URL: #{config['url']}"
    puts "  Policy: #{config['approval_policy']}"
    puts "  Tools: #{config['tool_approval_hashes']&.length || 0}"
    puts "  Agents: #{server['dependent_agents'].length}"
    puts "  Secured: #{config['secret_token'] ? 'Yes' : 'No'}"
    puts "  Creator: #{server['access_info']['creator_name']}"
  end
  
  analysis
end

# Run the analysis
server_analysis = analyze_mcp_servers(client)
```

### Bulk MCP Server Management

```ruby
# Manage multiple MCP servers efficiently
class MCPServerManager
  def initialize(client)
    @client = client
  end
  
  def create_from_config(servers_config)
    results = []
    
    servers_config.each do |config|
      begin
        server = @client.mcp_servers.create(config: config[:config])
        
        # Apply tool approvals if specified
        if config[:tools]
          config[:tools].each do |tool|
            @client.mcp_servers.create_tool_approval(
              server["id"],
              tool_name: tool[:name],
              tool_description: tool[:description],
              input_schema: tool[:schema],
              approval_policy: tool[:approval_policy] || "requires_approval"
            )
          end
        end
        
        results << { success: true, server: server, config: config }
        puts "✓ Created server: #{config[:config][:name]}"
        
      rescue => e
        results << { success: false, error: e.message, config: config }
        puts "✗ Failed to create server: #{config[:config][:name]} - #{e.message}"
      end
    end
    
    results
  end
  
  def update_all_policies(new_policy)
    servers = @client.mcp_servers.list
    results = []
    
    servers["mcp_servers"].each do |server|
      begin
        updated = @client.mcp_servers.update_approval_policy(
          server["id"],
          approval_policy: new_policy
        )
        results << { success: true, server_id: server["id"], name: server["config"]["name"] }
        puts "✓ Updated policy for: #{server['config']['name']}"
      rescue => e
        results << { success: false, server_id: server["id"], error: e.message }
        puts "✗ Failed to update: #{server['config']['name']} - #{e.message}"
      end
    end
    
    results
  end
end

# Example bulk configuration
servers_config = [
  {
    config: {
      url: "https://api.crm.company.com/mcp",
      name: "CRM Integration",
      approval_policy: "require_approval_per_tool",
      transport: "SSE",
      description: "Customer relationship management tools"
    },
    tools: [
      {
        name: "search_customers",
        description: "Search customer database",
        approval_policy: "auto_approved"
      },
      {
        name: "update_customer",
        description: "Update customer record",
        approval_policy: "requires_approval"
      }
    ]
  },
  {
    config: {
      url: "https://api.inventory.company.com/mcp",
      name: "Inventory System",
      approval_policy: "auto_approve_all",
      transport: "SSE",
      description: "Product inventory and warehouse management"
    }
  }
]

# Create servers from configuration
manager = MCPServerManager.new(client)
results = manager.create_from_config(servers_config)

puts "\nCreation Summary:"
successful = results.count { |r| r[:success] }
failed = results.count { |r| !r[:success] }
puts "✓ Successful: #{successful}"
puts "✗ Failed: #{failed}"
```

## Configuration Options

### MCP Server Config

```ruby
config: {
  url: "string",                    # Required: MCP server URL
  name: "string",                   # Required: Display name
  approval_policy: "string",        # Required: Approval policy
  transport: "SSE",                 # Optional: Transport method
  secret_token: {                   # Optional: Authentication
    secret_id: "string"
  },
  request_headers: {},              # Optional: Custom headers
  description: "string"             # Optional: Description
}
```

### Approval Policies

- **`auto_approve_all`**: Automatically approve all tools from this server
- **`require_approval_all`**: Require manual approval for all tools
- **`require_approval_per_tool`**: Configure approval on a per-tool basis

### Tool Approval Config

```ruby
{
  tool_name: "string",              # Required: Tool name
  tool_description: "string",       # Required: Tool description
  input_schema: {},                 # Optional: JSON schema for tool inputs
  approval_policy: "string"         # Optional: "auto_approved" or "requires_approval"
}
```

## Error Handling

```ruby
begin
  server = client.mcp_servers.create(
    config: {
      url: "https://invalid-url",
      name: "Test Server",
      approval_policy: "auto_approve_all"
    }
  )
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid configuration: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::NotFoundError => e
  puts "Server not found: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Security
1. **Use secrets for authentication**: Store API keys and tokens securely
2. **Configure appropriate approval policies**: Balance convenience with security
3. **Review tool permissions regularly**: Audit approved tools periodically
4. **Use descriptive names**: Clear naming helps with management

### Performance
1. **Monitor server response times**: Ensure MCP servers are responsive
2. **Limit tool scope**: Only approve necessary tools
3. **Use appropriate transport**: Choose the best transport method for your use case

### Management
1. **Document server purposes**: Clear descriptions aid in maintenance
2. **Regular audits**: Review server configurations and dependencies
3. **Monitor usage**: Track which servers and tools are actually used
4. **Plan for scaling**: Consider approval workflows for large deployments

## Notes

- **MCP Protocol**: Servers must implement the Model Context Protocol specification
- **Transport Methods**: Currently supports Server-Sent Events (SSE)
- **Approval Workflows**: Per-tool approval requires manual intervention for sensitive operations
- **Dependencies**: Check dependent agents before removing servers or tool approvals
- **Access Control**: Server creators have administrative privileges
