# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Test Invocations endpoints
# This file demonstrates how to use the test invocations endpoints for monitoring and managing test execution

require 'elevenlabs_client'

class TestInvocationsController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # Get detailed information about a test invocation
  def get_test_invocation(test_invocation_id)
    puts "Fetching test invocation: #{test_invocation_id}"
    
    invocation = @client.test_invocations.get(test_invocation_id)
    
    puts "\n🧪 Test Invocation Details:"
    puts "ID: #{invocation['id']}"
    puts "Created at: #{Time.at(invocation['created_at']).strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Total test runs: #{invocation['test_runs'].length}"
    
    # Analyze test run statuses
    statuses = invocation['test_runs'].group_by { |run| run['status'] }
    statuses.each do |status, runs|
      puts "  #{status.capitalize}: #{runs.length}"
    end
    
    puts "\n📊 Detailed Test Run Results:"
    invocation['test_runs'].each_with_index do |run, index|
      puts "\n#{index + 1}. Test Run: #{run['test_run_id']}"
      puts "   Test ID: #{run['test_id']}"
      puts "   Test Name: #{run['test_name'] || 'Unknown Test'}"
      puts "   Agent ID: #{run['agent_id']}"
      puts "   Status: #{run['status']}"
      puts "   Workflow Node: #{run['workflow_node_id']}" if run['workflow_node_id']
      puts "   Last Updated: #{Time.at(run['last_updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}" if run['last_updated_at_unix']
      
      # Show condition result if available
      if run['condition_result']
        result = run['condition_result']
        result_icon = result['result'] == 'success' ? '✅' : '❌'
        puts "   Result: #{result_icon} #{result['result'].upcase}"
        
        if result['rationale']
          rationale = result['rationale']
          puts "   Summary: #{rationale['summary']}" if rationale['summary'] && !rationale['summary'].empty?
          
          if rationale['messages']&.any?
            puts "   Details:"
            rationale['messages'].each { |msg| puts "     - #{msg}" }
          end
        end
      end
      
      # Show agent responses
      if run['agent_responses']&.any?
        assistant_responses = run['agent_responses'].select { |response| response['role'] == 'assistant' }
        if assistant_responses.any?
          puts "   Agent Responses:"
          assistant_responses.each_with_index do |response, resp_index|
            puts "     #{resp_index + 1}. #{response['message']}"
            puts "        Time: #{response['time_in_call_secs']}s"
            
            # Show tool calls if any
            if response['tool_calls']&.any?
              puts "        Tool calls:"
              response['tool_calls'].each do |tool_call|
                puts "          - #{tool_call['tool_name']}: #{tool_call['params_as_json']}"
              end
            end
            
            # Show tool results if any
            if response['tool_results']&.any?
              puts "        Tool results:"
              response['tool_results'].each do |tool_result|
                status_icon = tool_result['is_error'] ? '❌' : '✅'
                puts "          #{status_icon} #{tool_result['tool_name']}: #{tool_result['result_value']}"
                puts "            Latency: #{tool_result['tool_latency_secs']}s" if tool_result['tool_latency_secs']
              end
            end
          end
        end
      end
      
      # Show metadata
      if run['metadata']
        metadata = run['metadata']
        puts "   Metadata:"
        puts "     Workspace: #{metadata['workspace_id']}"
        puts "     Test Type: #{metadata['test_type']}"
        puts "     Run by: #{metadata['ran_by_user_email']}"
        puts "     Original Test Name: #{metadata['test_name']}" if metadata['test_name']
      end
    end
    
    invocation
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Test invocation not found: #{test_invocation_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching test invocation: #{e.message}"
    nil
  end

  # Resubmit specific test runs from a test invocation
  def resubmit_test_runs(test_invocation_id, test_run_ids, agent_id, config_override: nil)
    puts "Resubmitting test runs from invocation: #{test_invocation_id}"
    puts "Test runs to resubmit: #{test_run_ids.join(', ')}"
    puts "Agent: #{agent_id}"
    
    options = {
      test_run_ids: test_run_ids,
      agent_id: agent_id
    }
    
    options[:agent_config_override] = config_override if config_override
    
    response = @client.test_invocations.resubmit(test_invocation_id, **options)
    
    puts "✅ Test runs resubmitted successfully!"
    
    if config_override
      puts "Configuration override applied:"
      puts "  Updated prompts, settings, or other configurations"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Test invocation not found: #{test_invocation_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error resubmitting test runs: #{e.message}"
    nil
  end

  # Analyze test invocation performance
  def analyze_test_performance(test_invocation_id)
    puts "Analyzing performance for test invocation: #{test_invocation_id}"
    
    invocation = get_test_invocation(test_invocation_id)
    return nil unless invocation
    
    test_runs = invocation['test_runs']
    
    puts "\n📈 Performance Analysis:"
    puts "=" * 40
    
    # Overall statistics
    total_tests = test_runs.length
    completed_tests = test_runs.count { |run| run['status'] == 'completed' }
    pending_tests = test_runs.count { |run| run['status'] == 'pending' }
    failed_tests = test_runs.count { |run| run['status'] == 'failed' }
    
    puts "Overall Status:"
    puts "  Total tests: #{total_tests}"
    puts "  Completed: #{completed_tests}"
    puts "  Pending: #{pending_tests}"
    puts "  Failed: #{failed_tests}"
    
    # Success rate analysis
    if completed_tests > 0
      successful_tests = test_runs.count do |run|
        run['status'] == 'completed' && 
        run['condition_result'] && 
        run['condition_result']['result'] == 'success'
      end
      
      success_rate = (successful_tests.to_f / completed_tests * 100).round(1)
      
      puts "\nSuccess Analysis:"
      puts "  Successful tests: #{successful_tests}/#{completed_tests}"
      puts "  Success rate: #{success_rate}%"
      
      # Rate the performance
      case success_rate
      when 90..100
        puts "  Rating: 🌟 EXCELLENT"
      when 75..89
        puts "  Rating: ✅ GOOD"
      when 60..74
        puts "  Rating: ⚠️ FAIR"
      when 40..59
        puts "  Rating: ❌ POOR"
      else
        puts "  Rating: 🚨 CRITICAL"
      end
    end
    
    # Test type analysis
    test_types = test_runs.group_by { |run| run['metadata']['test_type'] rescue 'unknown' }
    if test_types.keys.length > 1
      puts "\nTest Type Breakdown:"
      test_types.each do |type, runs|
        puts "  #{type}: #{runs.length} tests"
      end
    end
    
    # Agent performance if multiple agents
    agents = test_runs.group_by { |run| run['agent_id'] }
    if agents.keys.length > 1
      puts "\nAgent Performance:"
      agents.each do |agent_id, runs|
        completed_runs = runs.select { |run| run['status'] == 'completed' }
        if completed_runs.any?
          successful_runs = completed_runs.count do |run|
            run['condition_result'] && run['condition_result']['result'] == 'success'
          end
          agent_success_rate = (successful_runs.to_f / completed_runs.length * 100).round(1)
          puts "  #{agent_id}: #{successful_runs}/#{completed_runs.length} (#{agent_success_rate}%)"
        end
      end
    end
    
    # Failure analysis
    failed_runs = test_runs.select do |run|
      run['status'] == 'completed' && 
      run['condition_result'] && 
      run['condition_result']['result'] == 'failure'
    end
    
    if failed_runs.any?
      puts "\n❌ Failure Analysis:"
      failure_reasons = failed_runs.map do |run|
        run['condition_result']['rationale']['summary'] rescue 'Unknown reason'
      end.compact
      
      # Group similar failure reasons
      reason_counts = failure_reasons.each_with_object(Hash.new(0)) { |reason, hash| hash[reason] += 1 }
      reason_counts.each do |reason, count|
        puts "  #{reason}: #{count} test#{count > 1 ? 's' : ''}"
      end
    end
    
    {
      total: total_tests,
      completed: completed_tests,
      success_rate: completed_tests > 0 ? (test_runs.count { |run| run['condition_result']&.dig('result') == 'success' }.to_f / completed_tests * 100).round(1) : 0,
      pending: pending_tests,
      failed: failed_tests
    }
  end

  # Monitor test invocation until completion
  def monitor_test_invocation(test_invocation_id, check_interval: 10, max_wait: 300)
    puts "Monitoring test invocation: #{test_invocation_id}"
    puts "Check interval: #{check_interval} seconds"
    puts "Max wait time: #{max_wait} seconds"
    
    start_time = Time.now
    
    loop do
      invocation = @client.test_invocations.get(test_invocation_id)
      test_runs = invocation['test_runs']
      
      # Check completion status
      completed_runs = test_runs.count { |run| run['status'] == 'completed' }
      failed_runs = test_runs.count { |run| run['status'] == 'failed' }
      pending_runs = test_runs.count { |run| run['status'] == 'pending' }
      
      elapsed_time = (Time.now - start_time).round(1)
      
      puts "\n⏱️ Status Update (#{elapsed_time}s elapsed):"
      puts "  Completed: #{completed_runs}/#{test_runs.length}"
      puts "  Failed: #{failed_runs}"
      puts "  Pending: #{pending_runs}"
      
      # Check if all tests are done
      if pending_runs == 0
        puts "\n✅ All tests completed!"
        analyze_test_performance(test_invocation_id)
        break
      end
      
      # Check timeout
      if elapsed_time >= max_wait
        puts "\n⏰ Timeout reached. Some tests may still be running."
        break
      end
      
      # Wait before next check
      puts "   Checking again in #{check_interval} seconds..."
      sleep(check_interval)
    end
    
    invocation
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error monitoring test invocation: #{e.message}"
    nil
  end

  # Resubmit failed tests with improved configuration
  def resubmit_failed_tests(test_invocation_id, agent_id)
    puts "Identifying and resubmitting failed tests..."
    
    invocation = @client.test_invocations.get(test_invocation_id)
    
    # Find failed test runs
    failed_runs = invocation['test_runs'].select do |run|
      run['status'] == 'completed' && 
      run['condition_result'] && 
      run['condition_result']['result'] == 'failure'
    end
    
    if failed_runs.empty?
      puts "✅ No failed tests found to resubmit"
      return nil
    end
    
    puts "Found #{failed_runs.length} failed tests:"
    failed_runs.each do |run|
      puts "  - #{run['test_name']} (#{run['test_run_id']})"
      if run['condition_result']['rationale']['summary']
        puts "    Reason: #{run['condition_result']['rationale']['summary']}"
      end
    end
    
    # Create improved configuration
    improved_config = {
      conversation_config: {
        agent: {
          prompt: {
            prompt: "You are an enhanced customer service agent. Be extra careful to follow instructions precisely, respond professionally, and ensure all requirements are met.",
            llm: "gpt-4o-mini"
          },
          first_message: "Hello! I'm here to provide you with excellent customer service. How may I assist you today?",
          language: "en"
        }
      }
    }
    
    test_run_ids = failed_runs.map { |run| run['test_run_id'] }
    
    puts "\nResubmitting with improved configuration..."
    resubmit_test_runs(test_invocation_id, test_run_ids, agent_id, config_override: improved_config)
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error resubmitting failed tests: #{e.message}"
    nil
  end

  # Compare test invocations to track improvement
  def compare_test_invocations(invocation_ids)
    puts "Comparing test invocations: #{invocation_ids.join(', ')}"
    
    results = {}
    
    invocation_ids.each do |invocation_id|
      analysis = analyze_test_performance(invocation_id)
      results[invocation_id] = analysis if analysis
    end
    
    if results.length < 2
      puts "❌ Need at least 2 valid invocations to compare"
      return
    end
    
    puts "\n📊 Comparison Summary:"
    puts "=" * 50
    
    # Create comparison table
    printf "%-20s | %8s | %8s | %8s | %8s\n", "Invocation", "Total", "Success%", "Pending", "Failed"
    puts "-" * 50
    
    results.each do |invocation_id, data|
      short_id = invocation_id[0..15] + "..."
      printf "%-20s | %8d | %7.1f%% | %8d | %8d\n", 
             short_id, data[:total], data[:success_rate], data[:pending], data[:failed]
    end
    
    # Find best and worst
    best_invocation = results.max_by { |_, data| data[:success_rate] }
    worst_invocation = results.min_by { |_, data| data[:success_rate] }
    
    puts "\n🏆 Best Performance:"
    puts "  Invocation: #{best_invocation[0]}"
    puts "  Success Rate: #{best_invocation[1][:success_rate]}%"
    
    puts "\n📉 Worst Performance:"
    puts "  Invocation: #{worst_invocation[0]}"
    puts "  Success Rate: #{worst_invocation[1][:success_rate]}%"
    
    improvement = best_invocation[1][:success_rate] - worst_invocation[1][:success_rate]
    puts "\n📈 Improvement: #{improvement.round(1)} percentage points"
    
    results
  end

  # Demonstration workflow
  def demo_workflow
    puts "🚀 Starting Test Invocations Demo Workflow"
    puts "=" * 50
    
    # Note: This demo requires actual test invocation IDs from running tests
    puts "\n📝 Demo Overview:"
    puts "This demo shows how to:"
    puts "1. Monitor test invocations"
    puts "2. Analyze test performance"
    puts "3. Resubmit failed tests"
    puts "4. Compare different test runs"
    
    puts "\n💡 To use these methods:"
    puts "1. Run tests on an agent using client.tests.run_on_agent()"
    puts "2. Use the returned test invocation ID with these methods"
    puts "3. Monitor progress and resubmit as needed"
    
    puts "\nExample usage:"
    puts <<~EXAMPLE
      # Run initial tests
      test_results = client.tests.run_on_agent("agent_id", tests: test_list)
      invocation_id = test_results["id"]
      
      # Monitor until completion
      controller.monitor_test_invocation(invocation_id)
      
      # Analyze performance
      controller.analyze_test_performance(invocation_id)
      
      # Resubmit failed tests if needed
      controller.resubmit_failed_tests(invocation_id, "agent_id")
    EXAMPLE
    
    puts "\n✨ Demo workflow overview completed!"
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = TestInvocationsController.new

  # Run the demo workflow
  controller.demo_workflow
end
