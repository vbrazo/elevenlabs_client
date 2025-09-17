# Tools Management

The tools endpoints allow you to create, manage, and configure tools that agents can use during conversations.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
tools = client.tools
```

## Available Methods

### List Tools

Returns a list of all available tools in the workspace.

```ruby
tools = client.tools.list

tools["tools"].each do |tool|
  puts "#{tool['id']}: #{tool['tool_config']['name']}"
  puts "  Description: #{tool['tool_config']['description']}"
  puts "  Type: #{tool['tool_config']['type']}"
  puts "  Usage: #{tool['usage_stats']['total_calls']} calls"
  puts
end
```

### Get Tool Details

Retrieves detailed information about a specific tool.

```ruby
tool = client.tools.get("tool_id_here")

puts "Name: #{tool['tool_config']['name']}"
puts "Description: #{tool['tool_config']['description']}"
puts "Type: #{tool['tool_config']['type']}"
puts "URL: #{tool['tool_config']['api_schema']['url']}"
puts "Method: #{tool['tool_config']['api_schema']['method']}"

# Usage statistics
stats = tool['usage_stats']
puts "Total Calls: #{stats['total_calls']}"
puts "Average Latency: #{stats['avg_latency_secs']}s"
```

### Create Tool

Creates a new webhook tool that agents can use.

```ruby
tool_config = {
  name: "Weather API",
  description: "Get current weather information for any city",
  api_schema: {
    url: "https://api.weather.com/v1/current",
    method: "GET",
    query_params_schema: {
      properties: {
        city: {
          type: "string",
          description: "The city name"
        },
        units: {
          type: "string",
          enum: ["metric", "imperial"],
          description: "Temperature units"
        }
      },
      required: ["city"]
    },
    request_headers: {
      "Authorization" => "Bearer YOUR_API_KEY"
    }
  },
  response_timeout_secs: 30,
  disable_interruptions: false
}

response = client.tools.create(tool_config: tool_config)
tool_id = response["id"]
puts "Created tool: #{tool_id}"
```

### Update Tool

Updates an existing tool's configuration.

```ruby
updated_config = {
  name: "Enhanced Weather API",
  description: "Get current weather and forecast information for any city",
  api_schema: {
    url: "https://api.weather.com/v2/current-and-forecast",
    method: "GET",
    query_params_schema: {
      properties: {
        city: {
          type: "string",
          description: "The city name"
        },
        days: {
          type: "integer",
          description: "Number of forecast days",
          minimum: 1,
          maximum: 7
        }
      },
      required: ["city"]
    }
  },
  response_timeout_secs: 45
}

updated_tool = client.tools.update("tool_id_here", tool_config: updated_config)
puts "Updated tool: #{updated_tool['tool_config']['name']}"
```

### Delete Tool

Permanently deletes a tool from the workspace.

```ruby
client.tools.delete("tool_id_here")
puts "Tool deleted successfully"
```

### Get Dependent Agents

Lists all agents that are currently using a specific tool.

```ruby
dependent_agents = client.tools.get_dependent_agents("tool_id_here")

puts "Agents using this tool:"
dependent_agents["agents"].each do |agent|
  puts "  • Agent: #{agent['id']}"
  puts "    Name: #{agent['name']}" if agent['name']
end

if dependent_agents["has_more"]
  puts "More agents available. Use cursor: #{dependent_agents['next_cursor']}"
end
```

## Tool Configuration Examples

### REST API Tool

```ruby
rest_api_tool = {
  name: "Customer Database",
  description: "Query customer information from the CRM system",
  api_schema: {
    url: "https://api.yourcrm.com/customers",
    method: "GET",
    query_params_schema: {
      properties: {
        customer_id: {
          type: "string",
          description: "The customer ID to lookup"
        },
        include_orders: {
          type: "boolean",
          description: "Include customer order history"
        }
      },
      required: ["customer_id"]
    },
    request_headers: {
      "Authorization" => "Bearer ${API_KEY}",
      "Content-Type" => "application/json"
    }
  },
  response_timeout_secs: 20,
  assignments: [
    {
      source: "response",
      dynamic_variable: "customer_name",
      value_path: "$.customer.name"
    },
    {
      source: "response",
      dynamic_variable: "customer_tier",
      value_path: "$.customer.tier"
    }
  ]
}

client.tools.create(tool_config: rest_api_tool)
```

### POST Request Tool

```ruby
ticket_creation_tool = {
  name: "Create Support Ticket",
  description: "Create a new support ticket in the ticketing system",
  api_schema: {
    url: "https://api.helpdesk.com/tickets",
    method: "POST",
    request_body_schema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "The ticket title"
        },
        description: {
          type: "string",
          description: "Detailed description of the issue"
        },
        priority: {
          type: "string",
          enum: ["low", "medium", "high", "urgent"],
          description: "Ticket priority level"
        },
        customer_email: {
          type: "string",
          format: "email",
          description: "Customer's email address"
        }
      },
      required: ["title", "description", "customer_email"]
    },
    request_headers: {
      "Authorization" => "Bearer ${HELPDESK_API_KEY}",
      "Content-Type" => "application/json"
    }
  },
  response_timeout_secs: 30,
  assignments: [
    {
      source: "response",
      dynamic_variable: "ticket_id",
      value_path: "$.ticket.id"
    },
    {
      source: "response",
      dynamic_variable: "ticket_url",
      value_path: "$.ticket.url"
    }
  ]
}

client.tools.create(tool_config: ticket_creation_tool)
```

### Complex Tool with Authentication

```ruby
complex_tool = {
  name: "Order Management System",
  description: "Comprehensive order management with multiple operations",
  api_schema: {
    url: "https://api.ecommerce.com/orders",
    method: "POST",
    request_body_schema: {
      type: "object",
      properties: {
        action: {
          type: "string",
          enum: ["create", "update", "cancel", "refund"],
          description: "The action to perform"
        },
        order_data: {
          type: "object",
          properties: {
            customer_id: { type: "string" },
            items: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  product_id: { type: "string" },
                  quantity: { type: "integer", minimum: 1 },
                  price: { type: "number", minimum: 0 }
                },
                required: ["product_id", "quantity", "price"]
              }
            },
            shipping_address: {
              type: "object",
              properties: {
                street: { type: "string" },
                city: { type: "string" },
                state: { type: "string" },
                zip: { type: "string" },
                country: { type: "string" }
              },
              required: ["street", "city", "state", "zip", "country"]
            }
          },
          required: ["customer_id"]
        }
      },
      required: ["action", "order_data"]
    },
    request_headers: {
      "Authorization" => "Bearer ${ECOMMERCE_API_KEY}",
      "Content-Type" => "application/json",
      "X-API-Version" => "2024-01"
    }
  },
  response_timeout_secs: 60,
  disable_interruptions: true,
  assignments: [
    {
      source: "response",
      dynamic_variable: "order_id",
      value_path: "$.order.id"
    },
    {
      source: "response",
      dynamic_variable: "order_status",
      value_path: "$.order.status"
    },
    {
      source: "response",
      dynamic_variable: "total_amount",
      value_path: "$.order.total"
    }
  ]
}

client.tools.create(tool_config: complex_tool)
```

## Tool Usage Analytics

```ruby
# Analyze tool usage across all tools
tools_list = client.tools.list
tools = tools_list["tools"]

puts "🔧 Tool Usage Analytics:"
puts "=" * 40

# Sort by usage
tools_by_usage = tools.sort_by { |tool| -(tool['usage_stats']['total_calls'] || 0) }

puts "\n📊 Most Used Tools:"
tools_by_usage.first(5).each_with_index do |tool, index|
  stats = tool['usage_stats']
  puts "#{index + 1}. #{tool['tool_config']['name']}"
  puts "   Calls: #{stats['total_calls'] || 0}"
  puts "   Avg Latency: #{stats['avg_latency_secs'] || 0}s"
  puts "   Success Rate: #{stats['success_rate'] || 'N/A'}%"
end

# Performance analysis
puts "\n⚡ Performance Analysis:"
high_latency_tools = tools.select do |tool|
  (tool['usage_stats']['avg_latency_secs'] || 0) > 5
end

if high_latency_tools.any?
  puts "High latency tools (>5s):"
  high_latency_tools.each do |tool|
    puts "  • #{tool['tool_config']['name']}: #{tool['usage_stats']['avg_latency_secs']}s"
  end
else
  puts "All tools performing well (latency <5s)"
end

# Check for unused tools
unused_tools = tools.select { |tool| (tool['usage_stats']['total_calls'] || 0) == 0 }
if unused_tools.any?
  puts "\n⚠️ Unused Tools:"
  unused_tools.each do |tool|
    puts "  • #{tool['tool_config']['name']}"
  end
end
```

## Error Handling

```ruby
begin
  tool = client.tools.create(tool_config: invalid_config)
rescue ElevenlabsClient::ValidationError => e
  puts "Tool configuration invalid: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Tool Design

1. **Clear Descriptions**: Provide detailed descriptions for both the tool and its parameters
2. **Appropriate Timeouts**: Set reasonable timeout values based on expected API response times
3. **Error Handling**: Design your external APIs to return clear error messages
4. **Authentication**: Use secure authentication methods and consider token rotation

### Performance Optimization

1. **Response Size**: Keep API responses concise to reduce latency
2. **Caching**: Implement caching in your external APIs where appropriate
3. **Monitoring**: Track tool usage and performance metrics
4. **Fallbacks**: Design tools with graceful degradation for failures

## API Reference

For detailed API documentation, visit: [ElevenLabs Tools API Reference](https://elevenlabs.io/docs/api-reference/convai/tools)
