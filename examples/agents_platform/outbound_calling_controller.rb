# frozen_string_literal: true

require_relative "../../lib/elevenlabs_client"

class OutboundCallingController
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV["ELEVENLABS_API_KEY"])
  end

  def run_examples
    puts "📞 Outbound Calling Examples"
    puts "=" * 35

    # Get required IDs from environment
    agent_id = ENV["AGENT_ID"] || "your_agent_id_here"
    phone_number_id = ENV["PHONE_NUMBER_ID"] || "your_phone_number_id_here"

    example_twilio_outbound_call(agent_id, phone_number_id)
    example_sip_trunk_outbound_call(agent_id, phone_number_id)
    example_enhanced_outbound_calling(agent_id, phone_number_id)
    example_customer_outreach_campaign(agent_id, phone_number_id)
    example_emergency_notification_system(agent_id, phone_number_id)
    example_multi_provider_call_distribution(agent_id)
    example_call_quality_monitoring
  end

  private

  def example_twilio_outbound_call(agent_id, phone_number_id)
    puts "\n1️⃣ Twilio Outbound Call"
    puts "-" * 25

    begin
      # Basic Twilio outbound call
      twilio_call = @client.outbound_calling.twilio_call(
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        to_number: "+1555123456" # Test number
      )
      
      if twilio_call['success']
        puts "✅ Twilio call initiated successfully!"
        puts "Message: #{twilio_call['message']}"
        puts "Conversation ID: #{twilio_call['conversation_id']}" if twilio_call['conversation_id']
        puts "Call SID: #{twilio_call['callSid']}" if twilio_call['callSid']
      else
        puts "❌ Call failed: #{twilio_call['message']}"
      end
      
    rescue ElevenlabsClient::ValidationError => e
      puts "❌ Invalid parameters: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_sip_trunk_outbound_call(agent_id, phone_number_id)
    puts "\n2️⃣ SIP Trunk Outbound Call"
    puts "-" * 28

    begin
      # Basic SIP trunk outbound call
      sip_call = @client.outbound_calling.sip_trunk_call(
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        to_number: "+1555987654" # Test number
      )
      
      if sip_call['success']
        puts "✅ SIP trunk call initiated successfully!"
        puts "Message: #{sip_call['message']}"
        puts "Conversation ID: #{sip_call['conversation_id']}" if sip_call['conversation_id']
        puts "SIP Call ID: #{sip_call['sip_call_id']}" if sip_call['sip_call_id']
      else
        puts "❌ Call failed: #{sip_call['message']}"
      end
      
    rescue ElevenlabsClient::ValidationError => e
      puts "❌ Invalid parameters: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_enhanced_outbound_calling(agent_id, phone_number_id)
    puts "\n3️⃣ Enhanced Outbound Calling with Custom Configuration"
    puts "-" * 55

    begin
      # Enhanced call with custom conversation configuration
      conversation_data = {
        conversation_config_override: {
          agent: {
            first_message: "Hello! This is an automated call from our customer service team regarding your recent inquiry.",
            language: "en",
            prompt: {
              prompt: "You are a helpful customer service representative calling about a customer inquiry. Be professional and address their concerns."
            }
          },
          tts: {
            voice_id: "custom_voice_id",
            stability: 0.8,
            speed: 1.0,
            similarity_boost: 0.7
          }
        },
        user_id: "customer_12345",
        source_info: {
          source: "outbound_campaign",
          version: "1.0"
        },
        dynamic_variables: {
          customer_name: "John Doe",
          account_balance: "$150.00",
          inquiry_type: "billing_question",
          last_interaction: "2024-01-15"
        }
      }
      
      enhanced_call = @client.outbound_calling.twilio_call(
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        to_number: "+1555111222",
        conversation_initiation_client_data: conversation_data
      )
      
      if enhanced_call['success']
        puts "✅ Enhanced call initiated successfully!"
        puts "Conversation ID: #{enhanced_call['conversation_id']}"
        puts "Call includes:"
        puts "  • Custom greeting message"
        puts "  • Personalized dynamic variables"
        puts "  • Custom voice settings"
        puts "  • User tracking information"
      else
        puts "❌ Enhanced call failed: #{enhanced_call['message']}"
      end
      
    rescue ElevenlabsClient::APIError => e
      puts "❌ Enhanced call error: #{e.message}"
    end
  end

  def example_customer_outreach_campaign(agent_id, phone_number_id)
    puts "\n4️⃣ Customer Outreach Campaign"
    puts "-" * 35

    # Sample customer list
    customer_list = [
      {
        customer_id: "cust_001",
        name: "Alice Johnson",
        phone: "+1555001001",
        account_status: "active",
        last_interaction: "2024-01-10",
        provider: "twilio"
      },
      {
        customer_id: "cust_002",
        name: "Bob Smith",
        phone: "+1555001002",
        account_status: "pending_review",
        last_interaction: "2024-01-08",
        provider: "twilio"
      },
      {
        customer_id: "cust_003",
        name: "Carol Davis",
        phone: "+1555001003",
        account_status: "active",
        last_interaction: "2024-01-12",
        provider: "sip"
      }
    ]

    puts "📞 Starting customer outreach simulation..."
    puts "Customers to contact: #{customer_list.length}"
    
    results = []
    
    customer_list.each_with_index do |customer, index|
      puts "\n#{index + 1}/#{customer_list.length}: Simulating call to #{customer[:name]} (#{customer[:phone]})"
      
      # Prepare personalized conversation data
      conversation_data = {
        conversation_config_override: {
          agent: {
            first_message: "Hello #{customer[:name]}! This is a courtesy call from our customer service team to check on your account.",
            language: "en"
          }
        },
        user_id: customer[:customer_id],
        source_info: {
          source: "outreach_campaign",
          version: "1.0"
        },
        dynamic_variables: {
          customer_name: customer[:name],
          account_status: customer[:account_status],
          last_interaction: customer[:last_interaction]
        }
      }
      
      begin
        # Simulate call based on provider preference
        if customer[:provider] == "sip"
          puts "  📞 Using SIP trunk for #{customer[:name]}"
          # In actual implementation:
          # call_result = @client.outbound_calling.sip_trunk_call(...)
          
          # Simulated result
          call_result = {
            'success' => true,
            'conversation_id' => "conv_#{customer[:customer_id]}_#{Time.now.to_i}",
            'sip_call_id' => "sip_#{rand(1000..9999)}"
          }
        else
          puts "  📞 Using Twilio for #{customer[:name]}"
          # In actual implementation:
          # call_result = @client.outbound_calling.twilio_call(...)
          
          # Simulated result
          call_result = {
            'success' => true,
            'conversation_id' => "conv_#{customer[:customer_id]}_#{Time.now.to_i}",
            'callSid' => "CA#{SecureRandom.hex(16)}"
          }
        end
        
        if call_result['success']
          puts "  ✅ Call initiated successfully"
          puts "     Conversation ID: #{call_result['conversation_id']}"
          
          results << {
            customer: customer,
            success: true,
            conversation_id: call_result['conversation_id'],
            call_id: call_result['callSid'] || call_result['sip_call_id']
          }
        else
          puts "  ❌ Call failed: #{call_result['message']}"
          results << {
            customer: customer,
            success: false,
            error: call_result['message']
          }
        end
        
      rescue => e
        puts "  ❌ Exception: #{e.message}"
        results << {
          customer: customer,
          success: false,
          error: e.message
        }
      end
      
      # Rate limiting between calls
      sleep(1)
    end
    
    # Campaign summary
    successful_calls = results.count { |r| r[:success] }
    puts "\n📊 Campaign Summary:"
    puts "Total customers: #{customer_list.length}"
    puts "Successful calls: #{successful_calls}"
    puts "Failed calls: #{customer_list.length - successful_calls}"
    puts "Success rate: #{(successful_calls.to_f / customer_list.length * 100).round(1)}%"
    
    # Show successful conversations
    puts "\n✅ Successful Conversations:"
    results.select { |r| r[:success] }.each do |result|
      puts "  #{result[:customer][:name]}: #{result[:conversation_id]}"
    end
  end

  def example_emergency_notification_system(agent_id, phone_number_id)
    puts "\n5️⃣ Emergency Notification System"
    puts "-" * 35

    # Emergency contact list
    emergency_contacts = [
      {
        contact_id: "emer_001",
        name: "Emergency Coordinator",
        phone: "+1555911001",
        role: "coordinator",
        priority_level: "critical"
      },
      {
        contact_id: "emer_002",
        name: "Security Chief",
        phone: "+1555911002",
        role: "security",
        priority_level: "high"
      },
      {
        contact_id: "emer_003",
        name: "Facility Manager",
        phone: "+1555911003",
        role: "facilities",
        priority_level: "medium"
      }
    ]

    emergency_info = {
      type: "Fire Alarm",
      location: "Building A, Floor 3",
      timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      severity: "high"
    }

    puts "🚨 Emergency Notification Simulation"
    puts "Emergency: #{emergency_info[:type]}"
    puts "Location: #{emergency_info[:location]}"
    puts "Time: #{emergency_info[:timestamp]}"
    puts "Severity: #{emergency_info[:severity]}"
    
    results = []
    
    # Sort contacts by priority level
    sorted_contacts = emergency_contacts.sort_by do |contact|
      case contact[:priority_level]
      when "critical" then 1
      when "high" then 2
      when "medium" then 3
      else 4
      end
    end
    
    sorted_contacts.each_with_index do |contact, index|
      puts "\n#{index + 1}/#{sorted_contacts.length}: Notifying #{contact[:name]} (#{contact[:role]} - #{contact[:priority_level]} priority)"
      
      # Prepare emergency-specific conversation data
      conversation_data = {
        conversation_config_override: {
          agent: {
            first_message: "EMERGENCY NOTIFICATION: #{emergency_info[:type]} has been reported at #{emergency_info[:location]} at #{emergency_info[:timestamp]}. Please respond immediately.",
            language: "en",
            prompt: {
              prompt: "You are an emergency notification system. Provide clear, urgent information about the emergency situation. Be concise and direct."
            }
          },
          tts: {
            speed: 1.1,  # Slightly faster for urgency
            stability: 0.9
          }
        },
        user_id: contact[:contact_id],
        source_info: {
          source: "emergency_system",
          version: "1.0"
        },
        dynamic_variables: {
          contact_name: contact[:name],
          contact_role: contact[:role],
          emergency_type: emergency_info[:type],
          emergency_location: emergency_info[:location],
          emergency_time: emergency_info[:timestamp],
          priority_level: contact[:priority_level]
        }
      }
      
      begin
        # Simulate emergency call (using Twilio for reliability)
        puts "  📞 Initiating emergency call via Twilio..."
        
        # In actual implementation:
        # call_result = @client.outbound_calling.twilio_call(...)
        
        # Simulated result
        call_result = {
          'success' => true,
          'conversation_id' => "emergency_#{contact[:contact_id]}_#{Time.now.to_i}",
          'callSid' => "EMR#{SecureRandom.hex(8)}"
        }
        
        if call_result['success']
          puts "  ✅ Emergency notification sent"
          puts "     Call ID: #{call_result['callSid']}"
          
          results << {
            contact: contact,
            success: true,
            call_id: call_result['callSid'],
            conversation_id: call_result['conversation_id']
          }
        else
          puts "  ❌ Notification failed: #{call_result['message']}"
          results << {
            contact: contact,
            success: false,
            error: call_result['message']
          }
        end
        
      rescue => e
        puts "  ❌ Critical error: #{e.message}"
        results << {
          contact: contact,
          success: false,
          error: e.message
        }
      end
      
      # Minimal delay for emergency situations
      sleep(0.3)
    end
    
    # Emergency notification summary
    successful_notifications = results.count { |r| r[:success] }
    puts "\n📊 Emergency Notification Summary:"
    puts "Total contacts: #{emergency_contacts.length}"
    puts "Successful notifications: #{successful_notifications}"
    puts "Failed notifications: #{emergency_contacts.length - successful_notifications}"
    
    if successful_notifications < emergency_contacts.length
      puts "\n⚠️ WARNING: Not all emergency contacts were notified!"
      failed_contacts = results.select { |r| !r[:success] }
      puts "Failed contacts:"
      failed_contacts.each do |result|
        puts "  • #{result[:contact][:name]} (#{result[:contact][:role]}): #{result[:error]}"
      end
    else
      puts "\n✅ All emergency contacts notified successfully"
    end
  end

  def example_multi_provider_call_distribution(agent_id)
    puts "\n6️⃣ Multi-Provider Call Distribution"
    puts "-" * 40

    # Sample call queue
    call_queue = [
      {
        to_number: "+1555123456",
        user_id: "user_001",
        destination_country: "+1",
        conversation_config: {
          agent: { first_message: "Hello! This is a test call from our US office." }
        }
      },
      {
        to_number: "+44123456789",
        user_id: "user_002", 
        destination_country: "+44",
        conversation_config: {
          agent: { first_message: "Hello! This is a test call from our international department." }
        }
      },
      {
        to_number: "+1555987654",
        user_id: "user_003",
        destination_country: "+1",
        conversation_config: {
          agent: { first_message: "Hello! This is a follow-up call." }
        }
      }
    ]

    # Provider configurations
    providers_config = [
      {
        provider: "twilio",
        agent_id: agent_id,
        phone_number_id: "twilio_phone_001",
        best_for: ["North America"],
        cost_per_minute: 0.02
      },
      {
        provider: "sip",
        agent_id: agent_id,
        phone_number_id: "sip_phone_001",
        best_for: ["International", "Europe"],
        cost_per_minute: 0.01
      }
    ]

    puts "📞 Multi-Provider Call Distribution Simulation"
    puts "Calls to process: #{call_queue.length}"
    puts "Available providers: #{providers_config.length}"
    
    results = []
    provider_stats = Hash.new(0)
    
    call_queue.each_with_index do |call_request, index|
      puts "\n#{index + 1}/#{call_queue.length}: Processing call to #{call_request[:to_number]}"
      
      # Select optimal provider based on destination
      selected_config = select_optimal_provider(providers_config, call_request)
      
      if selected_config.nil?
        puts "  ❌ No available providers"
        results << { call_request: call_request, success: false, error: "No providers available" }
        next
      end
      
      puts "  📊 Selected provider: #{selected_config[:provider]} (Cost: $#{selected_config[:cost_per_minute]}/min)"
      
      begin
        conversation_data = {
          conversation_config_override: call_request[:conversation_config],
          user_id: call_request[:user_id],
          dynamic_variables: call_request[:dynamic_variables] || {}
        }
        
        # Simulate call based on selected provider
        if selected_config[:provider] == "twilio"
          puts "  📞 Initiating Twilio call..."
          # call_result = @client.outbound_calling.twilio_call(...)
          call_result = simulate_call_result("twilio")
        else
          puts "  📞 Initiating SIP trunk call..."
          # call_result = @client.outbound_calling.sip_trunk_call(...)
          call_result = simulate_call_result("sip")
        end
        
        if call_result['success']
          puts "  ✅ Call initiated via #{selected_config[:provider]}"
          provider_stats[selected_config[:provider]] += 1
          
          results << {
            call_request: call_request,
            success: true,
            provider: selected_config[:provider],
            call_id: call_result['call_id'],
            conversation_id: call_result['conversation_id'],
            estimated_cost: selected_config[:cost_per_minute]
          }
        else
          puts "  ❌ Call failed: #{call_result['message']}"
          results << {
            call_request: call_request,
            success: false,
            provider: selected_config[:provider],
            error: call_result['message']
          }
        end
        
      rescue => e
        puts "  ❌ Exception: #{e.message}"
        results << {
          call_request: call_request,
          success: false,
          provider: selected_config[:provider],
          error: e.message
        }
      end
      
      sleep(0.5) # Rate limiting
    end
    
    # Distribution summary
    successful_calls = results.count { |r| r[:success] }
    total_estimated_cost = results.select { |r| r[:success] }.sum { |r| r[:estimated_cost] || 0 }
    
    puts "\n📊 Call Distribution Summary:"
    puts "Total calls: #{call_queue.length}"
    puts "Successful: #{successful_calls}"
    puts "Failed: #{call_queue.length - successful_calls}"
    puts "Estimated total cost: $#{total_estimated_cost.round(4)}"
    
    puts "\nProvider Distribution:"
    provider_stats.each do |provider, count|
      percentage = (count.to_f / successful_calls * 100).round(1) if successful_calls > 0
      puts "  #{provider}: #{count} calls#{percentage ? " (#{percentage}%)" : ""}"
    end
  end

  def example_call_quality_monitoring
    puts "\n7️⃣ Call Quality Monitoring"
    puts "-" * 30

    # Sample call session data (would come from previous calls)
    call_sessions = [
      {
        success: true,
        provider: "twilio",
        conversation_id: "conv_001",
        duration: 120,
        quality_score: 8.5
      },
      {
        success: true,
        provider: "sip",
        conversation_id: "conv_002",
        duration: 95,
        quality_score: 7.2
      },
      {
        success: false,
        provider: "twilio",
        error: "Number unreachable"
      },
      {
        success: true,
        provider: "sip",
        conversation_id: "conv_003",
        duration: 200,
        quality_score: 9.1
      },
      {
        success: false,
        provider: "sip",
        error: "Connection timeout"
      }
    ]

    puts "📊 Call Quality Analysis"
    puts "Sessions analyzed: #{call_sessions.length}"
    
    # Calculate quality metrics
    quality_metrics = {
      total_calls: call_sessions.length,
      successful_calls: call_sessions.count { |s| s[:success] },
      failed_calls: call_sessions.count { |s| !s[:success] },
      provider_performance: Hash.new { |h, k| h[k] = { success: 0, failure: 0, total_duration: 0, quality_scores: [] } }
    }
    
    call_sessions.each do |session|
      provider = session[:provider]
      
      if session[:success]
        quality_metrics[:provider_performance][provider][:success] += 1
        quality_metrics[:provider_performance][provider][:total_duration] += session[:duration] || 0
        quality_metrics[:provider_performance][provider][:quality_scores] << session[:quality_score] if session[:quality_score]
      else
        quality_metrics[:provider_performance][provider][:failure] += 1
      end
    end
    
    # Overall performance
    success_rate = (quality_metrics[:successful_calls].to_f / quality_metrics[:total_calls] * 100).round(1)
    
    puts "\n📈 Overall Performance:"
    puts "Total calls: #{quality_metrics[:total_calls]}"
    puts "Successful: #{quality_metrics[:successful_calls]}"
    puts "Failed: #{quality_metrics[:failed_calls]}"
    puts "Success rate: #{success_rate}%"
    
    # Provider breakdown
    puts "\n🏢 Provider Performance:"
    quality_metrics[:provider_performance].each do |provider, stats|
      total_provider_calls = stats[:success] + stats[:failure]
      provider_success_rate = total_provider_calls > 0 ? (stats[:success].to_f / total_provider_calls * 100).round(1) : 0
      avg_duration = stats[:success] > 0 ? (stats[:total_duration].to_f / stats[:success]).round(1) : 0
      avg_quality = stats[:quality_scores].any? ? (stats[:quality_scores].sum / stats[:quality_scores].length).round(1) : "N/A"
      
      puts "\n#{provider.upcase}:"
      puts "  Total calls: #{total_provider_calls}"
      puts "  Success rate: #{provider_success_rate}%"
      puts "  Average duration: #{avg_duration}s"
      puts "  Average quality score: #{avg_quality}"
      
      # Rate provider performance
      case provider_success_rate
      when 95..100
        puts "  Rating: 🌟 EXCELLENT"
      when 90..94
        puts "  Rating: ✅ GOOD"
      when 80..89
        puts "  Rating: ⚠️ FAIR"
      else
        puts "  Rating: ❌ POOR - Needs investigation"
      end
    end
    
    # Quality insights
    puts "\n💡 Quality Insights:"
    if success_rate >= 95
      puts "✅ Excellent call success rate"
    elsif success_rate >= 85
      puts "✅ Good call success rate"
    else
      puts "⚠️ Call success rate needs improvement"
    end
    
    # Provider comparison
    best_provider = quality_metrics[:provider_performance].max_by do |_, stats|
      total_calls = stats[:success] + stats[:failure]
      total_calls > 0 ? stats[:success].to_f / total_calls : 0
    end
    
    if best_provider
      puts "🏆 Best performing provider: #{best_provider[0]}"
    end
  end

  # Helper methods

  def select_optimal_provider(providers_config, call_request)
    destination_country = call_request[:to_number][0..2]
    
    # Prefer providers optimized for the destination
    if destination_country == "+1" # North America
      twilio_configs = providers_config.select { |config| config[:provider] == "twilio" }
      return twilio_configs.first unless twilio_configs.empty?
    end
    
    # Use SIP for international calls (potentially cheaper)
    sip_configs = providers_config.select { |config| config[:provider] == "sip" }
    return sip_configs.first unless sip_configs.empty?
    
    # Fall back to any available provider
    providers_config.first
  end

  def simulate_call_result(provider)
    # Simulate call results for demonstration
    success_rate = provider == "twilio" ? 0.95 : 0.90
    
    if rand < success_rate
      {
        'success' => true,
        'conversation_id' => "conv_#{provider}_#{Time.now.to_i}_#{rand(1000..9999)}",
        'call_id' => "#{provider.upcase}_#{SecureRandom.hex(8)}"
      }
    else
      {
        'success' => false,
        'message' => ["Number busy", "No answer", "Invalid number"].sample
      }
    end
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  controller = OutboundCallingController.new
  controller.run_examples
end
