# Test Invocations Management

The test invocations endpoints allow you to monitor and manage test execution runs for better visibility into test performance.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
test_invocations = client.test_invocations
```

## Available Methods

### Get Test Invocation

Retrieves detailed information about a specific test invocation, including all test runs and their results.

```ruby
test_invocation = client.test_invocations.get("invocation_id_here")

puts "Test Invocation: #{test_invocation['id']}"
puts "Created at: #{Time.at(test_invocation['created_at']).strftime('%Y-%m-%d %H:%M:%S')}"

test_invocation['test_runs'].each do |run|
  puts "\nTest Run: #{run['test_run_id']}"
  puts "  Test ID: #{run['test_id']}"
  puts "  Test Name: #{run['test_name']}"
  puts "  Agent ID: #{run['agent_id']}"
  puts "  Status: #{run['status']}"
  
  if run['condition_result']
    result = run['condition_result']
    puts "  Result: #{result['result']}"
    puts "  Rationale: #{result['rationale']['summary']}" if result['rationale']['summary']
  end
  
  if run['agent_responses']&.any?
    puts "  Agent Responses:"
    run['agent_responses'].each_with_index do |response, index|
      next unless response['role'] == 'assistant'
      puts "    #{index + 1}. #{response['message']}"
    end
  end
  
  if run['metadata']
    metadata = run['metadata']
    puts "  Workspace: #{metadata['workspace_id']}"
    puts "  Ran by: #{metadata['ran_by_user_email']}"
    puts "  Test type: #{metadata['test_type']}"
  end
end
```

### Resubmit Test Invocation

Resubmits specific test runs from a test invocation with optional configuration overrides.

```ruby
# Resubmit specific test runs
resubmit_response = client.test_invocations.resubmit(
  "invocation_id_here",
  test_run_ids: ["run_id_1", "run_id_2"],
  agent_id: "agent_id_here"
)

puts "Resubmitted test runs successfully"
```

### Resubmit with Configuration Override

Resubmit tests with custom agent configuration to test different scenarios.

```ruby
# Resubmit with configuration override
resubmit_response = client.test_invocations.resubmit(
  "invocation_id_here",
  test_run_ids: ["run_id_1"],
  agent_id: "agent_id_here",
  agent_config_override: {
    conversation_config: {
      agent: {
        prompt: {
          prompt: "You are an enhanced customer service agent with additional training on empathy and problem-solving.",
          llm: "gpt-4o-mini"
        },
        first_message: "Hello! I'm here to provide you with exceptional customer service. How may I assist you today?",
        language: "en"
      }
    }
  }
)

puts "Resubmitted tests with enhanced configuration"
```

## Examples

### Monitoring Test Execution

```ruby
# Run tests and monitor the invocation
test_results = client.tests.run_on_agent(
  "agent_id_here",
  tests: [
    { test_id: "test1_id" },
    { test_id: "test2_id" },
    { test_id: "test3_id" }
  ]
)

invocation_id = test_results["id"]
puts "Started test invocation: #{invocation_id}"

# Monitor progress
loop do
  invocation = client.test_invocations.get(invocation_id)
  
  # Count status
  completed = invocation['test_runs'].count { |run| run['status'] == 'completed' }
  pending = invocation['test_runs'].count { |run| run['status'] == 'pending' }
  total = invocation['test_runs'].length
  
  puts "Progress: #{completed}/#{total} completed, #{pending} pending"
  
  break if pending == 0
  
  sleep(5)
end

puts "All tests completed!"
```

### Analyzing Test Results

```ruby
def analyze_test_invocation(invocation_id)
  invocation = client.test_invocations.get(invocation_id)
  
  puts "📊 Test Invocation Analysis"
  puts "=" * 40
  puts "Invocation ID: #{invocation['id']}"
  puts "Created: #{Time.at(invocation['created_at']).strftime('%Y-%m-%d %H:%M:%S')}"
  
  test_runs = invocation['test_runs']
  
  # Overall statistics
  total_tests = test_runs.length
  completed_tests = test_runs.count { |run| run['status'] == 'completed' }
  successful_tests = test_runs.count do |run|
    run['status'] == 'completed' && 
    run['condition_result'] && 
    run['condition_result']['result'] == 'success'
  end
  
  puts "\n📈 Statistics:"
  puts "Total tests: #{total_tests}"
  puts "Completed: #{completed_tests}"
  puts "Successful: #{successful_tests}"
  
  if completed_tests > 0
    success_rate = (successful_tests.to_f / completed_tests * 100).round(1)
    puts "Success rate: #{success_rate}%"
  end
  
  # Test breakdown
  puts "\n📋 Test Results:"
  test_runs.each do |run|
    status_icon = case run['condition_result']&.dig('result')
    when 'success' then '✅'
    when 'failure' then '❌'
    else '⏳'
    end
    
    puts "#{status_icon} #{run['test_name']} (#{run['status']})"
    
    if run['condition_result'] && run['condition_result']['result'] == 'failure'
      rationale = run['condition_result']['rationale']['summary']
      puts "    Reason: #{rationale}" if rationale
    end
  end
  
  # Performance insights
  failed_runs = test_runs.select do |run|
    run['condition_result'] && run['condition_result']['result'] == 'failure'
  end
  
  if failed_runs.any?
    puts "\n⚠️ Common Failure Patterns:"
    failure_reasons = failed_runs.map do |run|
      run['condition_result']['rationale']['summary']
    end.compact
    
    reason_counts = failure_reasons.each_with_object(Hash.new(0)) do |reason, hash|
      hash[reason] += 1
    end
    
    reason_counts.each do |reason, count|
      puts "  • #{reason}: #{count} occurrence#{count > 1 ? 's' : ''}"
    end
  end
end

# Usage
analyze_test_invocation("your_invocation_id")
```

### Automated Test Retry Logic

```ruby
def run_tests_with_retry(agent_id, test_suite, max_retries: 2)
  attempt = 1
  
  loop do
    puts "Attempt #{attempt}: Running test suite..."
    
    # Run tests
    test_results = client.tests.run_on_agent(agent_id, tests: test_suite)
    invocation_id = test_results["id"]
    
    # Wait for completion
    sleep(10)
    
    # Get results
    invocation = client.test_invocations.get(invocation_id)
    
    # Find failed tests
    failed_runs = invocation['test_runs'].select do |run|
      run['status'] == 'completed' && 
      run['condition_result'] && 
      run['condition_result']['result'] == 'failure'
    end
    
    if failed_runs.empty?
      puts "✅ All tests passed!"
      return invocation
    elsif attempt >= max_retries
      puts "❌ Max retries reached. Some tests still failing."
      return invocation
    else
      puts "🔄 #{failed_runs.length} tests failed. Retrying with enhanced configuration..."
      
      # Resubmit failed tests with improved configuration
      failed_run_ids = failed_runs.map { |run| run['test_run_id'] }
      
      client.test_invocations.resubmit(
        invocation_id,
        test_run_ids: failed_run_ids,
        agent_id: agent_id,
        agent_config_override: {
          conversation_config: {
            agent: {
              prompt: {
                prompt: "You are an enhanced customer service agent. Be extra careful to follow instructions precisely and respond professionally.",
                llm: "gpt-4o-mini"
              }
            }
          }
        }
      )
      
      attempt += 1
      sleep(10)
    end
  end
end

# Usage
test_suite = [
  { test_id: "greeting_test" },
  { test_id: "order_lookup_test" },
  { test_id: "complaint_handling_test" }
]

final_results = run_tests_with_retry("agent_id", test_suite)
```

### Performance Benchmarking

```ruby
def benchmark_agent_versions(agent_id, test_suite)
  configurations = [
    {
      name: "Baseline",
      config: nil  # Use default configuration
    },
    {
      name: "Enhanced Prompts",
      config: {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are a professional customer service agent with enhanced training.",
              llm: "gpt-4o-mini"
            }
          }
        }
      }
    },
    {
      name: "Advanced LLM",
      config: {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are a professional customer service agent.",
              llm: "gpt-4o"
            }
          }
        }
      }
    }
  ]
  
  results = {}
  
  configurations.each do |config_info|
    puts "Testing configuration: #{config_info[:name]}"
    
    # Run tests
    if config_info[:config]
      test_results = client.tests.run_on_agent(
        agent_id,
        tests: test_suite,
        agent_config_override: config_info[:config]
      )
    else
      test_results = client.tests.run_on_agent(agent_id, tests: test_suite)
    end
    
    # Wait for completion and analyze
    sleep(15)
    invocation = client.test_invocations.get(test_results["id"])
    
    completed = invocation['test_runs'].count { |run| run['status'] == 'completed' }
    successful = invocation['test_runs'].count do |run|
      run['condition_result'] && run['condition_result']['result'] == 'success'
    end
    
    success_rate = completed > 0 ? (successful.to_f / completed * 100).round(1) : 0
    
    results[config_info[:name]] = {
      success_rate: success_rate,
      total_tests: completed,
      successful_tests: successful,
      invocation_id: invocation['id']
    }
    
    puts "  Success rate: #{success_rate}%"
  end
  
  # Summary
  puts "\n📊 Benchmark Results:"
  puts "=" * 40
  
  sorted_results = results.sort_by { |_, data| -data[:success_rate] }
  
  sorted_results.each_with_index do |(config_name, data), index|
    medal = case index
    when 0 then "🥇"
    when 1 then "🥈"
    when 2 then "🥉"
    else "  "
    end
    
    puts "#{medal} #{config_name}: #{data[:success_rate]}% (#{data[:successful_tests]}/#{data[:total_tests]})"
  end
  
  results
end

# Usage
test_suite = [
  { test_id: "greeting_test" },
  { test_id: "problem_solving_test" },
  { test_id: "escalation_test" }
]

benchmark_results = benchmark_agent_versions("agent_id", test_suite)
```

### Test Result Comparison

```ruby
def compare_test_invocations(invocation_ids)
  puts "📊 Test Invocation Comparison"
  puts "=" * 50
  
  results = {}
  
  invocation_ids.each do |invocation_id|
    invocation = client.test_invocations.get(invocation_id)
    
    # Calculate metrics
    test_runs = invocation['test_runs']
    completed = test_runs.count { |run| run['status'] == 'completed' }
    successful = test_runs.count do |run|
      run['condition_result'] && run['condition_result']['result'] == 'success'
    end
    
    success_rate = completed > 0 ? (successful.to_f / completed * 100).round(1) : 0
    
    results[invocation_id] = {
      created_at: invocation['created_at'],
      total_tests: test_runs.length,
      completed: completed,
      successful: successful,
      success_rate: success_rate,
      test_runs: test_runs
    }
  end
  
  # Create comparison table
  printf "%-20s | %8s | %8s | %8s | %8s\n", "Invocation", "Total", "Success%", "Passed", "Failed"
  puts "-" * 65
  
  results.each do |invocation_id, data|
    short_id = invocation_id[0..15] + "..."
    failed = data[:completed] - data[:successful]
    
    printf "%-20s | %8d | %7.1f%% | %8d | %8d\n",
           short_id, data[:total_tests], data[:success_rate], 
           data[:successful], failed
  end
  
  # Find trends
  if results.length >= 2
    sorted_by_time = results.sort_by { |_, data| data[:created_at] }
    first = sorted_by_time.first[1]
    last = sorted_by_time.last[1]
    
    improvement = last[:success_rate] - first[:success_rate]
    
    puts "\n📈 Trend Analysis:"
    if improvement > 0
      puts "✅ Improvement: +#{improvement.round(1)} percentage points"
    elsif improvement < 0
      puts "❌ Decline: #{improvement.round(1)} percentage points"
    else
      puts "➡️ No change in success rate"
    end
  end
  
  results
end

# Usage
comparison_results = compare_test_invocations([
  "invocation_1_id",
  "invocation_2_id", 
  "invocation_3_id"
])
```

## Error Handling

```ruby
begin
  invocation = client.test_invocations.get("invocation_id")
rescue ElevenlabsClient::NotFoundError
  puts "Test invocation not found"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Test Monitoring

1. **Regular Checks**: Monitor test invocations for completion and results
2. **Automated Alerts**: Set up notifications for failed test runs
3. **Performance Tracking**: Track test execution times and success rates
4. **Historical Analysis**: Compare results over time to identify trends

### Test Resubmission

1. **Strategic Retries**: Only resubmit tests that failed due to configuration issues
2. **Configuration Tuning**: Use resubmission to test different agent settings
3. **Batch Processing**: Resubmit multiple failed tests together for efficiency
4. **Documentation**: Track what configuration changes led to improvements

### Quality Assurance

1. **Continuous Monitoring**: Regularly check test invocation results
2. **Failure Analysis**: Investigate patterns in test failures
3. **Performance Benchmarking**: Compare different agent configurations
4. **Improvement Tracking**: Monitor success rate improvements over time

## API Reference

For detailed API documentation, visit: [ElevenLabs Test Invocations API Reference](https://elevenlabs.io/docs/api-reference/convai/test-invocations)
