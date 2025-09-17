# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Phone Numbers endpoints
# This file demonstrates how to use the phone numbers endpoints for voice-based conversational AI

require 'elevenlabs_client'

class PhoneNumbersController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # Import a Twilio phone number
  def import_twilio_phone(phone_number, label, sid, token)
    puts "Importing Twilio phone number: #{phone_number}"
    puts "Label: #{label}"
    
    response = @client.phone_numbers.import(
      phone_number: phone_number,
      label: label,
      sid: sid,
      token: token
    )
    
    puts "✅ Twilio phone number imported successfully!"
    puts "Phone Number ID: #{response['phone_number_id']}"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Import a SIP trunk phone number
  def import_sip_phone(phone_number, label, inbound_config, outbound_config, livekit_stack: "standard")
    puts "Importing SIP trunk phone number: #{phone_number}"
    puts "Label: #{label}"
    puts "LiveKit Stack: #{livekit_stack}"
    
    response = @client.phone_numbers.import(
      phone_number: phone_number,
      label: label,
      provider_type: "sip_trunk",
      inbound_trunk_config: inbound_config,
      outbound_trunk_config: outbound_config,
      livekit_stack: livekit_stack
    )
    
    puts "✅ SIP trunk phone number imported successfully!"
    puts "Phone Number ID: #{response['phone_number_id']}"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # List all phone numbers with detailed analysis
  def list_phone_numbers_with_analysis
    puts "Fetching all phone numbers..."
    
    phone_numbers = @client.phone_numbers.list
    
    if phone_numbers.empty?
      puts "📞 No phone numbers found"
      return []
    end
    
    puts "\n📞 Phone Numbers Analysis:"
    puts "=" * 60
    
    # Group by provider
    providers = phone_numbers.group_by { |phone| phone['provider'] }
    
    providers.each do |provider, phones|
      puts "\n#{provider.upcase} Numbers (#{phones.length}):"
      
      phones.each_with_index do |phone, index|
        puts "\n#{index + 1}. #{phone['phone_number']} - #{phone['label']}"
        puts "   ID: #{phone['phone_number_id']}"
        puts "   Capabilities:"
        puts "     📞 Inbound: #{phone['supports_inbound'] ? '✅ Supported' : '❌ Not supported'}"
        puts "     📞 Outbound: #{phone['supports_outbound'] ? '✅ Supported' : '❌ Not supported'}"
        
        if phone['assigned_agent']
          agent = phone['assigned_agent']
          puts "   🤖 Assigned Agent: #{agent['agent_name']} (#{agent['agent_id']})"
        else
          puts "   ⚠️ No agent assigned"
        end
      end
    end
    
    # Summary statistics
    puts "\n📊 Summary:"
    puts "Total numbers: #{phone_numbers.length}"
    puts "Providers: #{providers.keys.join(', ')}"
    
    assigned_count = phone_numbers.count { |phone| phone['assigned_agent'] }
    puts "Numbers with agents: #{assigned_count}/#{phone_numbers.length}"
    
    inbound_count = phone_numbers.count { |phone| phone['supports_inbound'] }
    outbound_count = phone_numbers.count { |phone| phone['supports_outbound'] }
    puts "Inbound capable: #{inbound_count}/#{phone_numbers.length}"
    puts "Outbound capable: #{outbound_count}/#{phone_numbers.length}"
    
    phone_numbers
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching phone numbers: #{e.message}"
    []
  end

  # Get detailed information about a specific phone number
  def get_phone_number_details(phone_number_id)
    puts "Fetching details for phone number: #{phone_number_id}"
    
    phone = @client.phone_numbers.get(phone_number_id)
    
    puts "\n📞 Phone Number Details:"
    puts "=" * 40
    puts "Number: #{phone['phone_number']}"
    puts "Label: #{phone['label']}"
    puts "ID: #{phone['phone_number_id']}"
    puts "Provider: #{phone['provider']}"
    
    puts "\nCapabilities:"
    puts "  Inbound: #{phone['supports_inbound'] ? '✅ Supported' : '❌ Not supported'}"
    puts "  Outbound: #{phone['supports_outbound'] ? '✅ Supported' : '❌ Not supported'}"
    
    if phone['assigned_agent']
      agent = phone['assigned_agent']
      puts "\n🤖 Assigned Agent:"
      puts "  Name: #{agent['agent_name']}"
      puts "  ID: #{agent['agent_id']}"
    else
      puts "\n⚠️ No agent assigned"
    end
    
    # Show provider-specific configuration
    case phone['provider']
    when 'twilio'
      puts "\n📋 Twilio Configuration:"
      puts "  Standard Twilio integration"
    when 'sip_trunk'
      puts "\n📋 SIP Trunk Configuration:"
      
      if phone['inbound_trunk_config']
        config = phone['inbound_trunk_config']
        puts "  Inbound:"
        puts "    URI: #{config['sip_uri']}"
        puts "    Username: #{config['username']}"
        puts "    Auth Username: #{config['auth_username']}" if config['auth_username']
      end
      
      if phone['outbound_trunk_config']
        config = phone['outbound_trunk_config']
        puts "  Outbound:"
        puts "    URI: #{config['sip_uri']}"
        puts "    Username: #{config['username']}"
        puts "    Auth Username: #{config['auth_username']}" if config['auth_username']
        puts "    Caller ID: #{config['caller_id']}" if config['caller_id']
      end
      
      puts "  LiveKit Stack: #{phone['livekit_stack']}" if phone['livekit_stack']
    end
    
    phone
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Phone number not found: #{phone_number_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching phone number: #{e.message}"
    nil
  end

  # Assign an agent to a phone number
  def assign_agent_to_phone(phone_number_id, agent_id)
    puts "Assigning agent #{agent_id} to phone number #{phone_number_id}"
    
    updated_phone = @client.phone_numbers.update(
      phone_number_id,
      agent_id: agent_id
    )
    
    puts "✅ Agent assigned successfully!"
    
    if updated_phone['assigned_agent']
      agent = updated_phone['assigned_agent']
      puts "Phone: #{updated_phone['phone_number']}"
      puts "Agent: #{agent['agent_name']} (#{agent['agent_id']})"
    end
    
    updated_phone
  rescue ElevenlabsClient::NotFoundError => e
    puts "❌ Not found: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error assigning agent: #{e.message}"
    nil
  end

  # Remove agent assignment from a phone number
  def unassign_agent_from_phone(phone_number_id)
    puts "Removing agent assignment from phone number #{phone_number_id}"
    
    updated_phone = @client.phone_numbers.update(
      phone_number_id,
      agent_id: nil
    )
    
    puts "✅ Agent assignment removed successfully!"
    puts "Phone: #{updated_phone['phone_number']} is now unassigned"
    
    updated_phone
  rescue ElevenlabsClient::NotFoundError => e
    puts "❌ Phone number not found: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error removing agent assignment: #{e.message}"
    nil
  end

  # Update SIP trunk configuration
  def update_sip_configuration(phone_number_id, inbound_config: nil, outbound_config: nil, livekit_stack: nil)
    puts "Updating SIP configuration for phone number #{phone_number_id}"
    
    update_params = {}
    update_params[:inbound_trunk_config] = inbound_config if inbound_config
    update_params[:outbound_trunk_config] = outbound_config if outbound_config
    update_params[:livekit_stack] = livekit_stack if livekit_stack
    
    if update_params.empty?
      puts "❌ No configuration parameters provided"
      return nil
    end
    
    updated_phone = @client.phone_numbers.update(phone_number_id, **update_params)
    
    puts "✅ SIP configuration updated successfully!"
    puts "Phone: #{updated_phone['phone_number']}"
    
    updated_phone
  rescue ElevenlabsClient::NotFoundError => e
    puts "❌ Phone number not found: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error updating SIP configuration: #{e.message}"
    nil
  end

  # Delete a phone number
  def delete_phone_number(phone_number_id)
    puts "Deleting phone number: #{phone_number_id}"
    
    # Get phone details first for confirmation
    phone = @client.phone_numbers.get(phone_number_id)
    puts "Deleting: #{phone['phone_number']} (#{phone['label']})"
    
    @client.phone_numbers.delete(phone_number_id)
    puts "✅ Phone number deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Phone number not found: #{phone_number_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting phone number: #{e.message}"
  end

  # Complete phone setup workflow
  def setup_phone_system(agent_config, phone_configs)
    puts "🚀 Setting up complete phone system"
    puts "=" * 50
    
    results = {
      agent: nil,
      phones: []
    }
    
    # 1. Create agent for phone calls
    puts "\n1️⃣ Creating phone agent..."
    agent_response = @client.agents.create(**agent_config)
    
    if agent_response
      results[:agent] = agent_response
      puts "✅ Agent created: #{agent_response['agent_id']}"
      puts "   Name: #{agent_config[:name]}"
    else
      puts "❌ Failed to create agent"
      return results
    end
    
    sleep(1)
    
    # 2. Import phone numbers
    puts "\n2️⃣ Importing phone numbers..."
    phone_configs.each_with_index do |config, index|
      puts "\nImporting phone #{index + 1}/#{phone_configs.length}:"
      
      phone_response = case config[:type]
      when 'twilio'
        import_twilio_phone(
          config[:phone_number],
          config[:label],
          config[:sid],
          config[:token]
        )
      when 'sip_trunk'
        import_sip_phone(
          config[:phone_number],
          config[:label],
          config[:inbound_trunk_config],
          config[:outbound_trunk_config],
          livekit_stack: config[:livekit_stack] || "standard"
        )
      end
      
      if phone_response
        results[:phones] << phone_response
        puts "✅ Phone imported: #{config[:phone_number]}"
      else
        puts "❌ Failed to import phone: #{config[:phone_number]}"
      end
      
      sleep(1)
    end
    
    # 3. Assign agent to all phones
    puts "\n3️⃣ Assigning agent to phones..."
    results[:phones].each do |phone|
      assign_agent_to_phone(phone['phone_number_id'], results[:agent]['agent_id'])
      sleep(1)
    end
    
    # 4. Create tests for phone interactions
    puts "\n4️⃣ Creating phone interaction tests..."
    phone_test = @client.tests.create(
      name: "Phone Greeting Test",
      chat_history: [
        {
          role: "user",
          time_in_call_secs: 0,
          message: "Hello, I'm calling about my order"
        }
      ],
      success_condition: "Agent provides a professional phone greeting and offers assistance",
      success_examples: [
        {
          response: "Hello! Thank you for calling. I'd be happy to help you with your order. Could you please provide your order number?",
          type: "professional_phone_greeting"
        }
      ],
      failure_examples: [
        {
          response: "Yeah, what do you want?",
          type: "unprofessional_greeting"
        }
      ]
    )
    
    if phone_test
      puts "✅ Phone test created: #{phone_test['id']}"
      
      # 5. Test the phone agent
      puts "\n5️⃣ Testing phone agent..."
      test_results = @client.tests.run_on_agent(
        results[:agent]['agent_id'],
        tests: [{ test_id: phone_test['id'] }]
      )
      
      if test_results
        puts "✅ Tests initiated: #{test_results['id']}"
        
        # Wait a moment and check results
        sleep(3)
        test_invocation = @client.test_invocations.get(test_results['id'])
        
        test_invocation['test_runs'].each do |run|
          result = run['condition_result']
          if result
            status_icon = result['result'] == 'success' ? '✅' : '❌'
            puts "#{status_icon} Phone agent test: #{result['result'].upcase}"
          end
        end
      end
    end
    
    puts "\n🎉 Phone system setup complete!"
    puts "Agent: #{results[:agent]['agent_id']}"
    puts "Phones: #{results[:phones].map { |p| p['phone_number_id'] }.join(', ')}"
    
    results
  end

  # Monitor phone number usage and performance
  def monitor_phone_performance
    puts "📊 Phone Number Performance Monitoring"
    puts "=" * 50
    
    phone_numbers = list_phone_numbers_with_analysis
    
    phone_numbers.each do |phone|
      next unless phone['assigned_agent']
      
      puts "\n📞 Analyzing: #{phone['phone_number']}"
      agent_id = phone['assigned_agent']['agent_id']
      
      # Get conversations for this agent
      conversations = @client.conversations.list(agent_id: agent_id)
      
      if conversations['conversations'].any?
        total_conversations = conversations['conversations'].length
        successful_conversations = conversations['conversations'].count do |conv|
          conv['call_successful'] == 'success'
        end
        
        success_rate = (successful_conversations.to_f / total_conversations * 100).round(1)
        
        puts "   Total calls: #{total_conversations}"
        puts "   Successful calls: #{successful_conversations}"
        puts "   Success rate: #{success_rate}%"
        
        # Rate performance
        case success_rate
        when 90..100
          puts "   Performance: 🌟 EXCELLENT"
        when 75..89
          puts "   Performance: ✅ GOOD"
        when 60..74
          puts "   Performance: ⚠️ NEEDS IMPROVEMENT"
        else
          puts "   Performance: ❌ POOR"
        end
        
        # Show recent call patterns
        recent_calls = conversations['conversations'].first(5)
        puts "   Recent calls:"
        recent_calls.each do |conv|
          start_time = Time.at(conv['call_start_time_unix_secs']).strftime('%m/%d %H:%M')
          status = conv['call_successful'] || 'unknown'
          status_icon = case status
          when 'success' then '✅'
          when 'failure' then '❌'
          else '❓'
          end
          puts "     #{status_icon} #{start_time}: #{status}"
        end
      else
        puts "   📭 No conversations found"
      end
    end
  end

  # Bulk phone number management
  def bulk_assign_agents(phone_agent_pairs)
    puts "🔄 Bulk Agent Assignment"
    puts "=" * 30
    
    results = []
    
    phone_agent_pairs.each do |pair|
      phone_id = pair[:phone_number_id]
      agent_id = pair[:agent_id]
      
      puts "Assigning #{agent_id} to #{phone_id}..."
      result = assign_agent_to_phone(phone_id, agent_id)
      
      results << {
        phone_number_id: phone_id,
        agent_id: agent_id,
        success: !result.nil?
      }
      
      sleep(0.5) # Rate limiting
    end
    
    successful = results.count { |r| r[:success] }
    puts "\n📊 Bulk Assignment Results:"
    puts "Successful: #{successful}/#{results.length}"
    puts "Failed: #{results.length - successful}"
    
    results
  end

  # Demonstration workflow
  def demo_workflow
    puts "🚀 Starting Phone Numbers Demo Workflow"
    puts "=" * 50
    
    # 1. List existing phone numbers
    puts "\n1️⃣ Listing existing phone numbers..."
    phone_numbers = list_phone_numbers_with_analysis
    
    sleep(1)
    
    # 2. Demo phone setup configuration
    puts "\n2️⃣ Demo phone system setup..."
    
    agent_config = {
      conversation_config: {
        agent: {
          prompt: {
            prompt: "You are a professional customer service representative for phone calls. Speak clearly, be helpful, and maintain a friendly tone.",
            llm: "gpt-4o-mini"
          },
          first_message: "Hello! Thank you for calling our customer service line. How may I assist you today?",
          language: "en"
        }
      },
      name: "Demo Phone Customer Service Agent"
    }
    
    puts "\nAgent Configuration:"
    puts "  Name: #{agent_config[:name]}"
    puts "  LLM: #{agent_config[:conversation_config][:agent][:prompt][:llm]}"
    puts "  First Message: #{agent_config[:conversation_config][:agent][:first_message]}"
    
    # Demo phone configurations
    phone_configs = [
      {
        type: 'twilio',
        phone_number: '+1555DEMO01',
        label: 'Demo Main Line',
        sid: 'demo_twilio_sid',
        token: 'demo_twilio_token'
      },
      {
        type: 'sip_trunk',
        phone_number: '+1555DEMO02',
        label: 'Demo SIP Line',
        inbound_trunk_config: {
          sip_uri: 'sip:demo-inbound@example.com',
          username: 'demo_user',
          password: 'demo_pass',
          auth_username: 'demo_auth'
        },
        outbound_trunk_config: {
          sip_uri: 'sip:demo-outbound@example.com',
          username: 'demo_out_user',
          password: 'demo_out_pass',
          auth_username: 'demo_out_auth',
          caller_id: '+1555DEMO02'
        },
        livekit_stack: 'standard'
      }
    ]
    
    puts "\nPhone Configurations:"
    phone_configs.each_with_index do |config, index|
      puts "  #{index + 1}. #{config[:phone_number]} (#{config[:type]}) - #{config[:label]}"
    end
    
    # 3. Demo monitoring
    puts "\n3️⃣ Demo performance monitoring..."
    if phone_numbers.any?
      monitor_phone_performance
    else
      puts "No phone numbers available for monitoring demo"
    end
    
    puts "\n✨ Demo workflow completed!"
    puts "\n💡 To run a complete phone setup:"
    puts "controller.setup_phone_system(agent_config, phone_configs)"
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = PhoneNumbersController.new

  # Run the demo workflow
  controller.demo_workflow
end
