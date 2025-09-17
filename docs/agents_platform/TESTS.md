# Tests Management

The tests endpoints allow you to create, manage, and run automated tests on your conversational AI agents to ensure quality and consistency.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
tests = client.tests
```

## Available Methods

### List Tests

Returns a list of all available agent tests with pagination support.

```ruby
# List all tests
tests = client.tests.list

# List with filters and pagination
tests = client.tests.list(
  page_size: 20,
  search: "customer service",
  cursor: "next_page_cursor"
)

tests["tests"].each do |test|
  puts "#{test['id']}: #{test['name']}"
  puts "  Type: #{test['type']}"
  puts "  Created: #{Time.at(test['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
  puts "  Creator: #{test['access_info']['creator_name']}"
  puts
end

if tests["has_more"]
  puts "More tests available. Use cursor: #{tests['next_cursor']}"
end
```

### Get Test Details

Retrieves detailed information about a specific test.

```ruby
test = client.tests.get("test_id_here")

puts "Test: #{test['name']}"
puts "Type: #{test['type']}"
puts "Success condition: #{test['success_condition']}"

puts "\nChat History:"
test['chat_history'].each_with_index do |message, index|
  puts "#{index + 1}. #{message['role']}: #{message['message']}"
  puts "   Time: #{message['time_in_call_secs']}s"
end

puts "\nSuccess Examples:"
test['success_examples'].each_with_index do |example, index|
  puts "#{index + 1}. #{example['response']} (#{example['type']})"
end

puts "\nFailure Examples:"
test['failure_examples'].each_with_index do |example, index|
  puts "#{index + 1}. #{example['response']} (#{example['type']})"
end
```

### Create Test

Creates a new agent response test.

```ruby
# Create a basic LLM response test
test = client.tests.create(
  name: "Customer Service Greeting Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "Hello, I need help with my order"
    }
  ],
  success_condition: "The agent responds politely and asks for order details or order number",
  success_examples: [
    {
      response: "Hello! I'd be happy to help you with your order. Could you please provide your order number?",
      type: "helpful_greeting"
    },
    {
      response: "Hi there! I can assist you with your order. What specific issue are you experiencing?",
      type: "polite_inquiry"
    }
  ],
  failure_examples: [
    {
      response: "What do you want?",
      type: "rude_response"
    },
    {
      response: "I don't know anything about orders.",
      type: "unhelpful_response"
    }
  ],
  type: "llm"
)

puts "Created test: #{test['id']}"
```

### Create Tool Call Test

Creates a test that evaluates tool calling behavior.

```ruby
# Create a tool call test
tool_test = client.tests.create(
  name: "Order Lookup Tool Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "Can you check the status of order #12345?"
    }
  ],
  success_condition: "The agent calls the order lookup tool with the correct order number",
  success_examples: [
    {
      response: "Let me check the status of order #12345 for you.",
      type: "tool_call_acknowledgment"
    }
  ],
  failure_examples: [
    {
      response: "I can't help with order status.",
      type: "no_tool_call"
    }
  ],
  type: "tool",
  tool_call_parameters: {
    referenced_tool: {
      id: "order_lookup_tool_id",
      type: "system"
    },
    parameters: [
      {
        path: "$.order_number",
        eval: {
          type: "exact_match",
          description: "Order number should be 12345"
        }
      }
    ],
    verify_absence: false
  }
)

puts "Created tool test: #{tool_test['id']}"
```

### Update Test

Updates an existing test configuration.

```ruby
updated_test = client.tests.update(
  "test_id_here",
  name: "Enhanced Customer Service Greeting Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "Hello, I need help with my order"
    },
    {
      role: "assistant",
      time_in_call_secs: 2,
      message: "Hello! I'd be happy to help you with your order. Could you please provide your order number?"
    },
    {
      role: "user",
      time_in_call_secs: 10,
      message: "It's order #12345"
    }
  ],
  success_condition: "The agent acknowledges the order number and proceeds to look it up or ask for verification",
  success_examples: [
    {
      response: "Thank you! Let me look up order #12345 for you.",
      type: "order_lookup"
    }
  ],
  failure_examples: [
    {
      response: "I don't see that order.",
      type: "premature_negative"
    }
  ]
)

puts "Updated test: #{updated_test['name']}"
```

### Delete Test

Permanently deletes a test.

```ruby
client.tests.delete("test_id_here")
puts "Test deleted successfully"
```

### Get Test Summaries

Retrieves summaries for multiple tests at once.

```ruby
test_ids = ["test1", "test2", "test3"]
summaries = client.tests.get_summaries(test_ids)

summaries["tests"].each do |test_id, summary|
  puts "#{test_id}: #{summary['name']}"
  puts "  Type: #{summary['type']}"
  puts "  Created: #{Time.at(summary['created_at_unix_secs']).strftime('%Y-%m-%d')}"
  puts
end
```

### Run Tests on Agent

Executes tests against a specific agent configuration.

```ruby
# Run tests with default agent configuration
test_run = client.tests.run_on_agent(
  "agent_id_here",
  tests: [
    { test_id: "test1_id" },
    { test_id: "test2_id" },
    { test_id: "test3_id" }
  ]
)

puts "Test run ID: #{test_run['id']}"
puts "Started at: #{Time.at(test_run['created_at']).strftime('%Y-%m-%d %H:%M:%S')}"

# Check individual test results
test_run['test_runs'].each do |run|
  puts "\nTest: #{run['test_name']}"
  puts "Status: #{run['status']}"
  
  if run['condition_result']
    result = run['condition_result']
    puts "Result: #{result['result']}"
    puts "Rationale: #{result['rationale']['summary']}" if result['rationale']['summary']
  end
  
  if run['agent_responses']&.any?
    puts "Agent responses:"
    run['agent_responses'].each_with_index do |response, index|
      next unless response['role'] == 'assistant'
      puts "  #{index + 1}. #{response['message']}"
    end
  end
end
```

### Run Tests with Configuration Override

Run tests with custom agent configuration.

```ruby
# Run tests with configuration overrides
test_run = client.tests.run_on_agent(
  "agent_id_here",
  tests: [
    { test_id: "greeting_test_id" },
    { test_id: "tool_test_id" }
  ],
  agent_config_override: {
    conversation_config: {
      agent: {
        prompt: {
          prompt: "You are a helpful customer service agent. Always be polite and ask for order numbers when discussing orders.",
          llm: "gpt-4o-mini"
        },
        first_message: "Hello! How can I help you today?",
        language: "en"
      }
    }
  }
)

puts "Test run with override completed: #{test_run['id']}"
```

## Testing Examples

### Complete Testing Workflow

```ruby
# 1. Create a comprehensive test suite
greeting_test = client.tests.create(
  name: "Customer Greeting Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "Hi there"
    }
  ],
  success_condition: "Agent responds with a friendly greeting and offers help",
  success_examples: [
    { response: "Hello! How can I help you today?", type: "friendly" },
    { response: "Hi! What can I do for you?", type: "helpful" }
  ],
  failure_examples: [
    { response: "What?", type: "rude" },
    { response: "I'm busy", type: "dismissive" }
  ]
)

order_test = client.tests.create(
  name: "Order Status Check",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "What's the status of my order #12345?"
    }
  ],
  success_condition: "Agent uses order lookup tool with correct order number",
  success_examples: [
    { response: "Let me check order #12345 for you", type: "lookup" }
  ],
  failure_examples: [
    { response: "I can't check orders", type: "no_action" }
  ],
  type: "tool",
  tool_call_parameters: {
    referenced_tool: { id: "order_lookup_tool", type: "system" },
    parameters: [
      {
        path: "$.order_number",
        eval: { type: "exact_match", description: "12345" }
      }
    ]
  }
)

# 2. Run tests on agent
test_results = client.tests.run_on_agent(
  "customer_service_agent_id",
  tests: [
    { test_id: greeting_test["id"] },
    { test_id: order_test["id"] }
  ]
)

# 3. Analyze results
passed_tests = 0
failed_tests = 0

test_results['test_runs'].each do |run|
  case run['condition_result']['result']
  when 'success'
    passed_tests += 1
    puts "✅ #{run['test_name']}: PASSED"
  when 'failure'
    failed_tests += 1
    puts "❌ #{run['test_name']}: FAILED"
    puts "   Reason: #{run['condition_result']['rationale']['summary']}"
  end
end

puts "\nTest Summary:"
puts "Passed: #{passed_tests}"
puts "Failed: #{failed_tests}"
puts "Success Rate: #{(passed_tests.to_f / (passed_tests + failed_tests) * 100).round(1)}%"
```

### Batch Testing Multiple Agents

```ruby
# Test multiple agents with the same test suite
agents = ["agent_1", "agent_2", "agent_3"]
test_suite = [
  { test_id: "greeting_test" },
  { test_id: "order_lookup_test" },
  { test_id: "complaint_handling_test" }
]

agent_results = {}

agents.each do |agent_id|
  puts "Testing agent: #{agent_id}"
  
  results = client.tests.run_on_agent(agent_id, tests: test_suite)
  
  # Calculate success rate
  total_tests = results['test_runs'].length
  passed = results['test_runs'].count { |run| run['condition_result']['result'] == 'success' }
  success_rate = (passed.to_f / total_tests * 100).round(1)
  
  agent_results[agent_id] = {
    total: total_tests,
    passed: passed,
    success_rate: success_rate,
    results: results
  }
  
  puts "  Success rate: #{success_rate}%"
end

# Find best performing agent
best_agent = agent_results.max_by { |_, stats| stats[:success_rate] }
puts "\nBest performing agent: #{best_agent[0]} (#{best_agent[1][:success_rate]}%)"
```

### Dynamic Variable Testing

```ruby
# Test with different dynamic variables
base_test = client.tests.create(
  name: "Product Recommendation Test",
  chat_history: [
    {
      role: "user", 
      time_in_call_secs: 0,
      message: "Can you recommend something for my budget?"
    }
  ],
  success_condition: "Agent asks about budget range and product preferences",
  success_examples: [
    { response: "What's your budget range and what type of product are you looking for?", type: "inquiry" }
  ],
  failure_examples: [
    { response: "Buy our most expensive item", type: "pushy" }
  ],
  dynamic_variables: {
    "max_budget" => 1000,
    "preferred_category" => "electronics"
  }
)

# Test with different budget scenarios
budget_scenarios = [100, 500, 1000, 5000]

budget_scenarios.each do |budget|
  puts "Testing with budget: $#{budget}"
  
  results = client.tests.run_on_agent(
    "sales_agent_id",
    tests: [{ test_id: base_test["id"] }],
    agent_config_override: {
      dynamic_variables: {
        "max_budget" => budget,
        "preferred_category" => "electronics"
      }
    }
  )
  
  success = results['test_runs'].first['condition_result']['result'] == 'success'
  puts "  Result: #{success ? 'PASSED' : 'FAILED'}"
end
```

### A/B Testing Agents

```ruby
# Create test suite
test_suite = [
  { test_id: "greeting_test_id" },
  { test_id: "problem_solving_test_id" },
  { test_id: "escalation_test_id" }
]

# Test agent A with original configuration
results_a = client.tests.run_on_agent("agent_id", tests: test_suite)

# Test agent A with enhanced configuration
results_b = client.tests.run_on_agent(
  "agent_id",
  tests: test_suite,
  agent_config_override: {
    conversation_config: {
      agent: {
        prompt: {
          prompt: "You are an enhanced customer service agent with advanced empathy training.",
          llm: "gpt-4o-mini"
        }
      }
    }
  }
)

# Compare results
def calculate_success_rate(results)
  total = results['test_runs'].length
  passed = results['test_runs'].count { |run| run['condition_result']['result'] == 'success' }
  (passed.to_f / total * 100).round(1)
end

rate_a = calculate_success_rate(results_a)
rate_b = calculate_success_rate(results_b)

puts "Original configuration: #{rate_a}%"
puts "Enhanced configuration: #{rate_b}%"
puts "Improvement: #{(rate_b - rate_a).round(1)} percentage points"
```

## Error Handling

```ruby
begin
  test = client.tests.create(invalid_test_data)
rescue ElevenlabsClient::ValidationError => e
  puts "Test configuration invalid: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Test Design

1. **Clear Success Criteria**: Define specific, measurable success conditions
2. **Comprehensive Examples**: Provide diverse success and failure examples
3. **Realistic Scenarios**: Use real-world conversation patterns
4. **Edge Cases**: Test boundary conditions and error scenarios

### Test Management

1. **Organized Naming**: Use descriptive, consistent test names
2. **Version Control**: Track test changes and improvements
3. **Regular Review**: Update tests as agent capabilities evolve
4. **Performance Monitoring**: Track test execution times and results

### Quality Assurance

1. **Automated Testing**: Integrate tests into CI/CD pipelines
2. **Regression Testing**: Run tests after agent modifications
3. **Performance Benchmarks**: Establish baseline performance metrics
4. **Continuous Improvement**: Use test results to refine agents

## API Reference

For detailed API documentation, visit: [ElevenLabs Tests API Reference](https://elevenlabs.io/docs/api-reference/convai/agent-testing)
