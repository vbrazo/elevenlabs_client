# Agents Management

The agents endpoints allow you to create, manage, and interact with conversational AI agents.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
agents = client.agents
```

## Available Methods

### Create Agent

Creates a new agent from a configuration object.

```ruby
response = client.agents.create(
  conversation_config: {
    # Required conversation configuration
    agent: {
      prompt: {
        prompt: "You are a helpful assistant",
        llm: "gpt-4o-mini"
      },
      first_message: "Hello! How can I help you today?"
    }
  },
  name: "My Customer Support Agent",
  tags: ["customer-support", "general"]
)

agent_id = response["agent_id"]
```

### Get Agent

Retrieves the configuration and metadata for a specific agent.

```ruby
agent = client.agents.get("agent_id_here")
puts agent["name"]
puts agent["conversation_config"]
```

### List Agents

Returns a list of your agents with their metadata.

```ruby
# List all agents
agents = client.agents.list

# List with filters and pagination
agents = client.agents.list(
  page_size: 10,
  search: "customer support",
  sort_by: "created_at",
  sort_direction: "desc",
  cursor: "next_page_cursor"
)

agents["agents"].each do |agent|
  puts "#{agent['name']} (#{agent['agent_id']})"
end
```

### Update Agent

Updates an existing agent's configuration.

```ruby
updated_agent = client.agents.update(
  "agent_id_here",
  name: "Updated Agent Name",
  conversation_config: {
    agent: {
      first_message: "Hello! I'm your updated assistant."
    }
  },
  tags: ["updated", "improved"]
)
```

### Delete Agent

Permanently deletes an agent.

```ruby
client.agents.delete("agent_id_here")
```

### Duplicate Agent

Creates a new agent by duplicating an existing one.

```ruby
response = client.agents.duplicate(
  "source_agent_id",
  name: "Duplicated Agent"
)

new_agent_id = response["agent_id"]
```

### Get Agent Link

Retrieves the shareable link for an agent.

```ruby
link_info = client.agents.link("agent_id_here")
puts link_info["token"]
```

### Simulate Conversation

Runs a conversation simulation between the agent and a simulated user.

```ruby
simulation = client.agents.simulate_conversation(
  "agent_id_here",
  simulation_specification: {
    simulated_user_config: {
      persona: "A customer with a billing question"
    }
  },
  extra_evaluation_criteria: [
    {
      name: "Helpfulness",
      description: "How helpful was the agent's response?"
    }
  ],
  new_turns_limit: 10
)

puts simulation["simulated_conversation"]
puts simulation["analysis"]
```

### Stream Simulate Conversation

Runs a conversation simulation with streaming response.

```ruby
client.agents.simulate_conversation_stream(
  "agent_id_here",
  simulation_specification: {
    simulated_user_config: {
      persona: "A customer with a technical question"
    }
  }
) do |chunk|
  puts "Received chunk: #{chunk}"
end
```

### Calculate LLM Usage

Calculates the expected LLM token usage and costs for a specific agent.

```ruby
usage_info = client.agents.calculate_llm_usage(
  "agent_id_here",
  prompt_length: 500,
  number_of_pages: 10,
  rag_enabled: true
)

usage_info["llm_prices"].each do |price|
  puts "#{price['llm']}: $#{price['price_per_minute']} per minute"
end
```

**Note**: For general LLM usage calculation without a specific agent, use `client.llm_usage.calculate()`. See [LLM Usage Documentation](LLM_USAGE.md) for details.

## Configuration Options

### Conversation Config

The `conversation_config` parameter accepts a complex configuration object with the following main sections:

- **agent**: Core agent settings including prompt, language, and behavior
- **asr**: Automatic Speech Recognition settings
- **tts**: Text-to-Speech configuration
- **turn**: Conversation turn management
- **conversation**: General conversation settings
- **language_presets**: Language-specific configurations

### Platform Settings

Platform settings control non-conversation aspects of the agent:

- **widget**: Widget appearance and behavior
- **privacy**: Privacy and data handling settings
- **integrations**: Third-party integrations
- **analytics**: Analytics and tracking configuration

## Examples

### Creating a Simple Customer Support Agent

```ruby
agent = client.agents.create(
  name: "Customer Support Bot",
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a friendly customer support agent for an e-commerce company. Help customers with their orders, returns, and general questions.",
        llm: "gpt-4o-mini",
        temperature: 0.7
      },
      first_message: "Hello! I'm here to help with any questions about your order or our products. How can I assist you today?",
      language: "en"
    },
    tts: {
      voice_id: "cjVigY5qzO86Huf0OWal",
      model_id: "eleven_turbo_v2"
    }
  },
  tags: ["customer-support", "e-commerce"]
)

puts "Created agent: #{agent['agent_id']}"
```

### Running a Conversation Test

```ruby
# Create a test conversation
test_result = client.agents.simulate_conversation(
  agent["agent_id"],
  simulation_specification: {
    simulated_user_config: {
      persona: "A customer who wants to return a product they purchased last week",
      goals: ["Get information about the return process", "Initiate a return"]
    }
  },
  extra_evaluation_criteria: [
    {
      name: "Problem Resolution",
      description: "Did the agent successfully help the customer with their return?"
    },
    {
      name: "Tone",
      description: "Was the agent's tone appropriate and professional?"
    }
  ]
)

puts "Conversation successful: #{test_result['analysis']['call_successful']}"
puts "Summary: #{test_result['analysis']['transcript_summary']}"
```

## Error Handling

```ruby
begin
  agent = client.agents.create(conversation_config: {})
rescue ElevenlabsClient::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## API Reference

For detailed API documentation, visit: [ElevenLabs Agents API Reference](https://elevenlabs.io/docs/api-reference/convai/agents)
