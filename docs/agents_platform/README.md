# Agents Platform

The Agents Platform endpoints allow you to create, manage, and interact with conversational AI agents through the ElevenLabs API.

## Overview

The Agents Platform provides comprehensive functionality for building and managing conversational AI systems with the following capabilities:

- **Agent Management** - Create, configure, and manage conversational AI agents
- **Conversation Management** - Monitor and interact with agent conversations
- **Tools Management** - Create and manage tools that agents can use
- **Knowledge Base Management** - Manage documents for retrieval-augmented generation (RAG)
- **Testing** - Create and run automated tests on agents
- **Test Monitoring** - Monitor test execution and resubmit failed tests
- **Phone Integration** - Import and manage phone numbers for voice-based AI
- **Widget Customization** - Configure agent widgets and upload custom avatars
- **Outbound Calling** - Initiate outbound calls via Twilio or SIP trunk
- **Batch Calling** - Schedule and manage bulk calling campaigns
- **Workspace Management** - Configure workspace settings, secrets, and dashboards
- **LLM Usage Calculation** - Calculate expected costs and token usage for agents
- **MCP Servers** - Manage Model Context Protocol servers for custom tools

## Quick Start

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")

# Access all agents platform endpoints
agents = client.agents                           # Agent management
conversations = client.conversations             # Conversation management  
tools = client.tools                            # Tools management
workspace = client.workspace                     # Workspace management
llm_usage = client.llm_usage                     # LLM usage calculation
mcp_servers = client.mcp_servers                 # MCP servers management
knowledge_base = client.knowledge_base          # Knowledge base management
tests = client.tests                            # Tests management
test_invocations = client.test_invocations      # Test invocations management
phone_numbers = client.phone_numbers            # Phone numbers management
widgets = client.widgets                        # Widget configuration and avatars
outbound_calling = client.outbound_calling      # Outbound calling (Twilio & SIP)
batch_calling = client.batch_calling            # Batch calling jobs
```

## Documentation

### Core Features
- **[Agents](AGENTS.md)** - Create and manage conversational AI agents
- **[Conversations](CONVERSATIONS.md)** - Monitor and interact with agent conversations
- **[Tools](TOOLS.md)** - Create tools that agents can use during conversations
- **[Knowledge Base](KNOWLEDGE_BASE.md)** - Manage documents for RAG capabilities

### Testing & Quality Assurance
- **[Tests](TESTS.md)** - Create and run automated tests on agents
- **[Test Invocations](TEST_INVOCATIONS.md)** - Monitor test execution and resubmit failed tests

### Voice & Phone Integration
- **[Phone Numbers](PHONE_NUMBERS.md)** - Import and manage phone numbers for voice-based AI
- **[Outbound Calling](OUTBOUND_CALLING.md)** - Initiate outbound calls via Twilio or SIP trunk
- **[Batch Calling](BATCH_CALLING.md)** - Schedule and manage bulk calling campaigns

### UI & Customization
- **[Widgets](WIDGETS.md)** - Configure agent widgets and upload custom avatars

### Platform & Infrastructure
- **[LLM Usage](LLM_USAGE.md)** - Calculate expected costs and token usage for agents
- **[MCP Servers](MCP_SERVERS.md)** - Manage Model Context Protocol servers for custom tools
- **[Workspace](WORKSPACE.md)** - Configure workspace settings, secrets, and dashboards

## Complete Workflow Example

Here's a complete example showing how to create a customer service system:

```ruby
# 1. Create an agent
agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a helpful customer service representative.",
        llm: "gpt-4o-mini"
      },
      first_message: "Hello! How can I help you today?",
      language: "en"
    }
  },
  name: "Customer Service Agent"
)

# 2. Create tools for the agent
tool = client.tools.create(
  tool_config: {
    name: "Order Lookup",
    description: "Look up customer orders",
    api_schema: {
      url: "https://api.yourcompany.com/orders",
      method: "GET",
      query_params_schema: {
        properties: {
          order_id: { type: "string", description: "Order ID to lookup" }
        },
        required: ["order_id"]
      }
    }
  }
)

# 3. Add knowledge base documents
document = client.knowledge_base.create_from_url(
  "https://docs.yourcompany.com/faq",
  name: "FAQ"
)

# 4. Create tests for quality assurance
test = client.tests.create(
  name: "Customer Greeting Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "Hello, I need help"
    }
  ],
  success_condition: "Agent responds politely and offers help",
  success_examples: [
    { response: "Hello! How can I help you today?", type: "polite_greeting" }
  ],
  failure_examples: [
    { response: "What do you want?", type: "rude_response" }
  ]
)

# 5. Run tests on the agent
test_results = client.tests.run_on_agent(
  agent["agent_id"],
  tests: [{ test_id: test["id"] }]
)

# 6. Import phone number for voice calls
phone = client.phone_numbers.import(
  phone_number: "+1555123456",
  label: "Customer Service Line",
  sid: "your_twilio_sid",
  token: "your_twilio_token"
)

# 7. Assign agent to phone number
client.phone_numbers.update(
  phone["phone_number_id"],
  agent_id: agent["agent_id"]
)

puts "✅ Customer service system setup complete!"
```

## Cost Estimation & Planning

Use the LLM usage calculation to estimate costs before deploying:

```ruby
# Calculate expected costs for your agent configuration
usage_estimate = client.llm_usage.calculate(
  prompt_length: 800,    # Length of your agent's prompt
  number_of_pages: 25,   # Pages in knowledge base
  rag_enabled: true      # Whether RAG is enabled
)

# Find the most cost-effective model
cheapest = usage_estimate["llm_prices"].min_by { |model| model["price_per_minute"] }
puts "Most cost-effective model: #{cheapest['llm']} at $#{cheapest['price_per_minute']}/minute"

# Calculate monthly costs for different usage scenarios
daily_minutes = 120  # 2 hours per day
monthly_cost = cheapest["price_per_minute"] * daily_minutes * 30
puts "Estimated monthly cost: $#{monthly_cost.round(2)}"
```

## MCP Server Integration

Extend your agents with custom tools using MCP servers:

```ruby
# Create an MCP server for business tools
mcp_server = client.mcp_servers.create(
  config: {
    url: "https://your-business-api.com/mcp",
    name: "Business API Tools",
    approval_policy: "require_approval_per_tool",
    description: "Custom tools for CRM and inventory management"
  }
)

# Approve specific tools
client.mcp_servers.create_tool_approval(
  mcp_server["id"],
  tool_name: "search_customers",
  tool_description: "Search customer database",
  approval_policy: "auto_approved"
)

# Use the MCP server in your agent
agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a business assistant with access to customer tools.",
        native_mcp_server_ids: [mcp_server["id"]]
      }
    }
  },
  name: "Business Assistant"
)
```

## Error Handling

All endpoints support comprehensive error handling:

```ruby
begin
  agent = client.agents.create(conversation_config: {})
rescue ElevenlabsClient::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Rate Limits

The Agents Platform endpoints are subject to the standard ElevenLabs API rate limits. For high-volume usage, consider implementing retry logic with exponential backoff.

## API Reference

For detailed API documentation, visit: [ElevenLabs Agents Platform API Reference](https://elevenlabs.io/docs/api-reference/convai/agents)

## Documentation

Detailed documentation for each category:

- [**Agents Management**](AGENTS.md) - Create, configure, and manage AI agents
- [**Conversations**](CONVERSATIONS.md) - Monitor and interact with agent conversations  
- [**Tools Management**](TOOLS.md) - Create and manage custom tools for agents
- [**Knowledge Base**](KNOWLEDGE_BASE.md) - Manage documents and RAG capabilities
- [**Testing**](TESTS.md) - Create and run automated tests on agents
- [**Test Invocations**](TEST_INVOCATIONS.md) - Monitor test execution and results
- [**Phone Integration**](PHONE_NUMBERS.md) - Manage phone numbers for voice AI
- [**Widget Customization**](WIDGETS.md) - Configure agent widgets and avatars
- [**Outbound Calling**](OUTBOUND_CALLING.md) - Initiate calls via Twilio or SIP
- [**Batch Calling**](BATCH_CALLING.md) - Schedule and manage bulk calling campaigns
- [**Workspace Management**](WORKSPACE.md) - Configure workspace settings and secrets
- [**LLM Usage Calculation**](LLM_USAGE.md) - Calculate costs and token usage
- [**MCP Servers**](MCP_SERVERS.md) - Manage Model Context Protocol servers

## Examples

Complete working examples for each category are available in the `examples/agents_platform/` directory:

- `agents_controller.rb` - Agent management examples
- `conversations_controller.rb` - Conversation management examples
- `tools_controller.rb` - Tools management examples
- `knowledge_base_controller.rb` - Knowledge base management examples
- `tests_controller.rb` - Testing examples
- `test_invocations_controller.rb` - Test monitoring examples
- `phone_numbers_controller.rb` - Phone integration examples
- `workspace_controller.rb` - Workspace management examples
- `llm_usage_controller.rb` - LLM usage calculation examples
- `mcp_servers_controller.rb` - MCP servers management examples
