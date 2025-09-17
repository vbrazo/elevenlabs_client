# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Tests endpoints
# This file demonstrates how to use the tests endpoints in a practical application

require 'elevenlabs_client'

class TestsController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # List all available tests with optional filtering
  def list_tests(search: nil, limit: 20)
    puts "Fetching agent tests..."
    
    options = { page_size: limit }
    options[:search] = search if search
    
    response = @client.tests.list(**options)
    tests = response["tests"]
    
    puts "\n🧪 Found #{tests.length} tests:"
    tests.each do |test|
      access_info = test['access_info']
      
      puts "  • #{test['id']}"
      puts "    Name: #{test['name']}"
      puts "    Type: #{test['type']}"
      puts "    Created: #{Time.at(test['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Updated: #{Time.at(test['last_updated_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Creator: #{access_info['creator_name']} (#{access_info['creator_email']})"
      puts
    end
    
    if response["has_more"]
      puts "💡 More tests available. Use cursor: #{response['next_cursor']}"
    end
    
    tests
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching tests: #{e.message}"
    []
  end

  # Get detailed information about a specific test
  def get_test_details(test_id)
    puts "Fetching details for test: #{test_id}"
    
    test = @client.tests.get(test_id)
    
    puts "\n🧪 Test Details:"
    puts "ID: #{test['id']}"
    puts "Name: #{test['name']}"
    puts "Type: #{test['type']}"
    
    puts "\n📝 Success Condition:"
    puts test['success_condition']
    
    puts "\n💬 Chat History:"
    test['chat_history'].each_with_index do |message, index|
      role_icon = message['role'] == 'user' ? '👤' : '🤖'
      puts "#{index + 1}. #{role_icon} #{message['role'].capitalize}: #{message['message']}"
      puts "   ⏱️ Time: #{message['time_in_call_secs']}s"
      
      if message['tool_calls']&.any?
        puts "   🔧 Tool calls:"
        message['tool_calls'].each do |tool_call|
          puts "     - #{tool_call['tool_name']}: #{tool_call['params_as_json']}"
        end
      end
      
      if message['tool_results']&.any?
        puts "   🔧 Tool results:"
        message['tool_results'].each do |tool_result|
          status = tool_result['is_error'] ? '❌' : '✅'
          puts "     #{status} #{tool_result['tool_name']}: #{tool_result['result_value']}"
        end
      end
      
      puts
    end
    
    puts "✅ Success Examples:"
    test['success_examples'].each_with_index do |example, index|
      puts "#{index + 1}. #{example['response']} (#{example['type']})"
    end
    
    puts "\n❌ Failure Examples:"
    test['failure_examples'].each_with_index do |example, index|
      puts "#{index + 1}. #{example['response']} (#{example['type']})"
    end
    
    if test['tool_call_parameters']
      params = test['tool_call_parameters']
      puts "\n🔧 Tool Call Evaluation:"
      puts "  Referenced tool: #{params['referenced_tool']['id']} (#{params['referenced_tool']['type']})"
      puts "  Verify absence: #{params['verify_absence']}"
      
      if params['parameters']&.any?
        puts "  Parameters to evaluate:"
        params['parameters'].each do |param|
          puts "    - Path: #{param['path']}"
          puts "      Evaluation: #{param['eval']['type']} - #{param['eval']['description']}"
        end
      end
    end
    
    if test['dynamic_variables']&.any?
      puts "\n🔄 Dynamic Variables:"
      test['dynamic_variables'].each do |key, value|
        puts "  #{key}: #{value}"
      end
    end
    
    test
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Test not found: #{test_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching test: #{e.message}"
    nil
  end

  # Create a basic LLM response test
  def create_llm_test(name, user_message, success_condition, success_examples, failure_examples)
    puts "Creating LLM test: #{name}"
    
    chat_history = [
      {
        role: "user",
        time_in_call_secs: 0,
        message: user_message
      }
    ]
    
    response = @client.tests.create(
      name: name,
      chat_history: chat_history,
      success_condition: success_condition,
      success_examples: success_examples,
      failure_examples: failure_examples,
      type: "llm"
    )
    
    puts "✅ LLM test created successfully!"
    puts "Test ID: #{response['id']}"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Create a tool call test
  def create_tool_test(name, user_message, success_condition, tool_id, tool_parameters = [])
    puts "Creating tool test: #{name}"
    
    chat_history = [
      {
        role: "user",
        time_in_call_secs: 0,
        message: user_message
      }
    ]
    
    success_examples = [
      {
        response: "Let me help you with that by using the appropriate tool.",
        type: "tool_acknowledgment"
      }
    ]
    
    failure_examples = [
      {
        response: "I can't help with that.",
        type: "no_tool_usage"
      }
    ]
    
    tool_call_parameters = {
      referenced_tool: {
        id: tool_id,
        type: "system"
      },
      parameters: tool_parameters,
      verify_absence: false
    }
    
    response = @client.tests.create(
      name: name,
      chat_history: chat_history,
      success_condition: success_condition,
      success_examples: success_examples,
      failure_examples: failure_examples,
      type: "tool",
      tool_call_parameters: tool_call_parameters
    )
    
    puts "✅ Tool test created successfully!"
    puts "Test ID: #{response['id']}"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Update an existing test
  def update_test(test_id, updates = {})
    puts "Updating test: #{test_id}"
    
    # Get current test
    current_test = @client.tests.get(test_id)
    
    # Merge updates with current test data
    updated_data = {
      name: updates[:name] || current_test['name'],
      chat_history: updates[:chat_history] || current_test['chat_history'],
      success_condition: updates[:success_condition] || current_test['success_condition'],
      success_examples: updates[:success_examples] || current_test['success_examples'],
      failure_examples: updates[:failure_examples] || current_test['failure_examples']
    }
    
    # Add optional fields if they exist
    updated_data[:type] = updates[:type] || current_test['type'] if current_test['type']
    updated_data[:tool_call_parameters] = updates[:tool_call_parameters] || current_test['tool_call_parameters'] if current_test['tool_call_parameters']
    updated_data[:dynamic_variables] = updates[:dynamic_variables] || current_test['dynamic_variables'] if current_test['dynamic_variables']
    
    response = @client.tests.update(test_id, **updated_data)
    
    puts "✅ Test updated successfully!"
    puts "Name: #{response['name']}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Test not found: #{test_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error updating test: #{e.message}"
    nil
  end

  # Delete a test
  def delete_test(test_id)
    puts "Deleting test: #{test_id}"
    
    @client.tests.delete(test_id)
    puts "✅ Test deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Test not found: #{test_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting test: #{e.message}"
  end

  # Get summaries for multiple tests
  def get_test_summaries(test_ids)
    puts "Fetching summaries for #{test_ids.length} tests..."
    
    response = @client.tests.get_summaries(test_ids)
    summaries = response["tests"]
    
    puts "\n📊 Test Summaries:"
    summaries.each do |test_id, summary|
      puts "• #{test_id}: #{summary['name']}"
      puts "  Type: #{summary['type']}"
      puts "  Created: #{Time.at(summary['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "  Creator: #{summary['access_info']['creator_name']}"
      puts
    end
    
    summaries
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching test summaries: #{e.message}"
    {}
  end

  # Run tests on a specific agent
  def run_tests_on_agent(agent_id, test_ids, config_override: nil)
    puts "Running #{test_ids.length} tests on agent: #{agent_id}"
    
    tests = test_ids.map { |test_id| { test_id: test_id } }
    
    options = { tests: tests }
    options[:agent_config_override] = config_override if config_override
    
    response = @client.tests.run_on_agent(agent_id, **options)
    
    puts "✅ Test run initiated!"
    puts "Run ID: #{response['id']}"
    puts "Started at: #{Time.at(response['created_at']).strftime('%Y-%m-%d %H:%M:%S')}"
    
    # Analyze results
    analyze_test_results(response)
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error running tests: #{e.message}"
    nil
  end

  # Analyze and display test results
  def analyze_test_results(test_run_response)
    test_runs = test_run_response['test_runs']
    
    puts "\n📊 Test Results Analysis:"
    puts "=" * 40
    
    passed_tests = 0
    failed_tests = 0
    pending_tests = 0
    
    test_runs.each do |run|
      test_name = run['test_name'] || 'Unknown Test'
      status = run['status']
      
      case status
      when 'completed'
        if run['condition_result']
          case run['condition_result']['result']
          when 'success'
            passed_tests += 1
            puts "✅ #{test_name}: PASSED"
          when 'failure'
            failed_tests += 1
            puts "❌ #{test_name}: FAILED"
            
            if run['condition_result']['rationale']
              rationale = run['condition_result']['rationale']
              puts "   Reason: #{rationale['summary']}" if rationale['summary']
              
              if rationale['messages']&.any?
                puts "   Details:"
                rationale['messages'].each { |msg| puts "     - #{msg}" }
              end
            end
          end
        else
          pending_tests += 1
          puts "⏳ #{test_name}: PENDING (no result yet)"
        end
      when 'pending'
        pending_tests += 1
        puts "⏳ #{test_name}: PENDING"
      when 'failed'
        failed_tests += 1
        puts "❌ #{test_name}: FAILED (system error)"
      end
      
      # Show agent responses if available
      if run['agent_responses']&.any?
        assistant_responses = run['agent_responses'].select { |r| r['role'] == 'assistant' }
        if assistant_responses.any?
          puts "   Agent response: \"#{assistant_responses.first['message']}\""
        end
      end
      
      puts
    end
    
    total_completed = passed_tests + failed_tests
    
    puts "📈 Summary:"
    puts "Total tests: #{test_runs.length}"
    puts "Passed: #{passed_tests}"
    puts "Failed: #{failed_tests}"
    puts "Pending: #{pending_tests}"
    
    if total_completed > 0
      success_rate = (passed_tests.to_f / total_completed * 100).round(1)
      puts "Success rate: #{success_rate}%"
    end
    
    {
      total: test_runs.length,
      passed: passed_tests,
      failed: failed_tests,
      pending: pending_tests,
      success_rate: total_completed > 0 ? (passed_tests.to_f / total_completed * 100).round(1) : 0
    }
  end

  # Create a comprehensive test suite for customer service
  def create_customer_service_test_suite
    puts "Creating customer service test suite..."
    
    test_ids = []
    
    # 1. Greeting test
    greeting_test = create_llm_test(
      "Customer Service Greeting",
      "Hello, I need help",
      "The agent responds with a friendly greeting and offers assistance",
      [
        { response: "Hello! I'd be happy to help you. What can I do for you today?", type: "friendly_greeting" },
        { response: "Hi there! How can I assist you?", type: "helpful_greeting" }
      ],
      [
        { response: "What do you want?", type: "rude_response" },
        { response: "I'm busy right now.", type: "dismissive_response" }
      ]
    )
    test_ids << greeting_test["id"] if greeting_test
    
    # 2. Order inquiry test
    order_test = create_llm_test(
      "Order Status Inquiry",
      "I want to check the status of my order #12345",
      "The agent acknowledges the order number and attempts to help with the status check",
      [
        { response: "I'll check the status of order #12345 for you right away.", type: "order_acknowledgment" },
        { response: "Let me look up order #12345 and see what's happening with it.", type: "helpful_lookup" }
      ],
      [
        { response: "I can't help with orders.", type: "unhelpful_response" },
        { response: "What order?", type: "ignoring_details" }
      ]
    )
    test_ids << order_test["id"] if order_test
    
    # 3. Complaint handling test
    complaint_test = create_llm_test(
      "Customer Complaint Handling",
      "I'm really upset! My package was delivered damaged and I need this fixed immediately!",
      "The agent responds with empathy and offers immediate assistance to resolve the issue",
      [
        { response: "I'm so sorry to hear about the damaged package! Let me help you resolve this right away.", type: "empathetic_response" },
        { response: "That's definitely not acceptable, and I apologize for this experience. I'll make sure we fix this for you immediately.", type: "taking_responsibility" }
      ],
      [
        { response: "That's not our fault.", type: "defensive_response" },
        { response: "You'll need to contact someone else about that.", type: "passing_buck" }
      ]
    )
    test_ids << complaint_test["id"] if complaint_test
    
    # 4. Product information test
    info_test = create_llm_test(
      "Product Information Request",
      "Can you tell me about the features of the TechPhone Pro?",
      "The agent provides helpful product information or indicates where to find it",
      [
        { response: "The TechPhone Pro features a 48MP camera, 5G connectivity, and 128GB storage. Would you like more details about any specific feature?", type: "detailed_info" },
        { response: "I'd be happy to help you learn about the TechPhone Pro. Let me get you the latest specifications.", type: "helpful_guidance" }
      ],
      [
        { response: "I don't know about products.", type: "unhelpful_response" },
        { response: "Look it up yourself.", type: "dismissive_response" }
      ]
    )
    test_ids << info_test["id"] if info_test
    
    puts "✅ Created #{test_ids.length} tests for customer service suite"
    test_ids.compact
  end

  # Create tool-based tests
  def create_tool_test_suite
    puts "Creating tool-based test suite..."
    
    test_ids = []
    
    # Order lookup tool test
    order_lookup_test = create_tool_test(
      "Order Lookup Tool Usage",
      "Please check the status of order #67890",
      "The agent uses the order lookup tool with the correct order number",
      "order_lookup_tool",
      [
        {
          path: "$.order_number",
          eval: {
            type: "exact_match",
            description: "Order number should be 67890"
          }
        }
      ]
    )
    test_ids << order_lookup_test["id"] if order_lookup_test
    
    # Customer lookup tool test
    customer_lookup_test = create_tool_test(
      "Customer Information Lookup",
      "I'm John Smith and my email is john@example.com. Can you pull up my account?",
      "The agent uses the customer lookup tool with the provided email address",
      "customer_lookup_tool",
      [
        {
          path: "$.email",
          eval: {
            type: "exact_match",
            description: "Email should be john@example.com"
          }
        }
      ]
    )
    test_ids << customer_lookup_test["id"] if customer_lookup_test
    
    puts "✅ Created #{test_ids.length} tool tests"
    test_ids.compact
  end

  # Run comprehensive agent evaluation
  def evaluate_agent(agent_id)
    puts "🔍 Comprehensive Agent Evaluation"
    puts "Agent ID: #{agent_id}"
    puts "=" * 50
    
    # Create test suites
    llm_tests = create_customer_service_test_suite
    tool_tests = create_tool_test_suite
    
    all_tests = llm_tests + tool_tests
    
    # Run tests
    results = run_tests_on_agent(agent_id, all_tests)
    
    if results
      puts "\n🏆 Final Evaluation Summary:"
      
      analysis = analyze_test_results(results)
      
      case analysis[:success_rate]
      when 90..100
        puts "🌟 EXCELLENT: Agent performs exceptionally well!"
      when 75..89
        puts "✅ GOOD: Agent performs well with minor areas for improvement"
      when 60..74
        puts "⚠️ FAIR: Agent needs improvement in several areas"
      when 40..59
        puts "❌ POOR: Agent requires significant improvements"
      else
        puts "🚨 CRITICAL: Agent needs major overhaul"
      end
      
      puts "\nRecommendations:"
      if analysis[:failed] > 0
        puts "- Review failed test cases and adjust agent prompts"
        puts "- Consider additional training data for failing scenarios"
      end
      
      if analysis[:success_rate] < 80
        puts "- Implement more specific success criteria"
        puts "- Add more example conversations to training"
      end
      
      analysis
    end
  end

  # Compare multiple agents
  def compare_agents(agent_ids)
    puts "🔍 Multi-Agent Comparison"
    puts "Agents: #{agent_ids.join(', ')}"
    puts "=" * 50
    
    # Create a standard test suite
    test_suite = create_customer_service_test_suite
    
    agent_results = {}
    
    agent_ids.each do |agent_id|
      puts "\nTesting agent: #{agent_id}"
      results = run_tests_on_agent(agent_id, test_suite)
      
      if results
        analysis = analyze_test_results(results)
        agent_results[agent_id] = analysis
        puts "Agent #{agent_id} success rate: #{analysis[:success_rate]}%"
      end
    end
    
    # Find best and worst performing agents
    if agent_results.any?
      best_agent = agent_results.max_by { |_, stats| stats[:success_rate] }
      worst_agent = agent_results.min_by { |_, stats| stats[:success_rate] }
      
      puts "\n🏆 Comparison Results:"
      puts "Best performing agent: #{best_agent[0]} (#{best_agent[1][:success_rate]}%)"
      puts "Worst performing agent: #{worst_agent[0]} (#{worst_agent[1][:success_rate]}%)"
      
      puts "\n📊 Detailed Results:"
      agent_results.each do |agent_id, stats|
        puts "#{agent_id}:"
        puts "  Success rate: #{stats[:success_rate]}%"
        puts "  Passed: #{stats[:passed]}/#{stats[:total]}"
        puts "  Failed: #{stats[:failed]}"
      end
    end
    
    agent_results
  end

  # Demonstration workflow
  def demo_workflow
    puts "🚀 Starting Agent Testing Demo Workflow"
    puts "=" * 50
    
    # 1. List existing tests
    puts "\n1️⃣ Listing existing tests..."
    tests = list_tests(limit: 5)
    
    sleep(1)
    
    # 2. Create test suite
    puts "\n2️⃣ Creating customer service test suite..."
    test_suite = create_customer_service_test_suite
    
    if test_suite.any?
      sleep(1)
      
      # 3. Get details of first test
      puts "\n3️⃣ Getting test details..."
      get_test_details(test_suite.first)
      
      sleep(1)
      
      # 4. Get test summaries
      puts "\n4️⃣ Getting test summaries..."
      get_test_summaries(test_suite.first(3))
      
      sleep(1)
      
      # 5. Update a test (example)
      puts "\n5️⃣ Updating test example..."
      update_test(test_suite.first, {
        name: "Enhanced Customer Service Greeting Test"
      })
      
      puts "\n✨ Demo workflow completed successfully!"
      puts "Created test suite with #{test_suite.length} tests"
      puts "Test IDs: #{test_suite.join(', ')}"
      
      test_suite
    else
      puts "❌ No tests were created in the demo"
      []
    end
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = TestsController.new

  # Run the demo workflow
  controller.demo_workflow
end
