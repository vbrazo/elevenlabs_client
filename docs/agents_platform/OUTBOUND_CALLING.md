# Outbound Calling

The outbound calling endpoints allow you to initiate phone calls from your conversational AI agents via Twilio or SIP trunk providers.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
outbound_calling = client.outbound_calling
```

## Available Methods

### SIP Trunk Outbound Call

Initiate an outbound call using a SIP trunk provider.

```ruby
sip_call = client.outbound_calling.sip_trunk_call(
  agent_id: "agent_id_here",
  agent_phone_number_id: "phone_number_id_here",
  to_number: "+1234567890"
)

puts "Call Status: #{sip_call['success'] ? 'Success' : 'Failed'}"
puts "Message: #{sip_call['message']}"
puts "Conversation ID: #{sip_call['conversation_id']}"
puts "SIP Call ID: #{sip_call['sip_call_id']}"
```

### Twilio Outbound Call

Initiate an outbound call using Twilio.

```ruby
twilio_call = client.outbound_calling.twilio_call(
  agent_id: "agent_id_here",
  agent_phone_number_id: "phone_number_id_here",
  to_number: "+1987654321"
)

puts "Call Status: #{twilio_call['success'] ? 'Success' : 'Failed'}"
puts "Message: #{twilio_call['message']}"
puts "Conversation ID: #{twilio_call['conversation_id']}"
puts "Call SID: #{twilio_call['callSid']}"
```

### Advanced Outbound Calling with Client Data

Include additional conversation configuration and client data when initiating calls.

```ruby
# SIP trunk call with custom configuration
sip_call = client.outbound_calling.sip_trunk_call(
  agent_id: "agent_id_here",
  agent_phone_number_id: "phone_number_id_here",
  to_number: "+1555123456",
  conversation_initiation_client_data: {
    conversation_config_override: {
      agent: {
        first_message: "Hello! This is an automated call from our customer service team.",
        language: "en"
      },
      tts: {
        voice_id: "custom_voice_id",
        stability: 0.8,
        speed: 1.0
      }
    },
    user_id: "customer_123",
    source_info: {
      source: "outbound_campaign",
      version: "1.0"
    },
    dynamic_variables: {
      customer_name: "John Doe",
      account_balance: "$150.00"
    }
  }
)

puts "Enhanced SIP call initiated: #{sip_call['conversation_id']}"

# Twilio call with custom configuration
twilio_call = client.outbound_calling.twilio_call(
  agent_id: "support_agent_id",
  agent_phone_number_id: "twilio_phone_id",
  to_number: "+1555987654",
  conversation_initiation_client_data: {
    conversation_config_override: {
      agent: {
        first_message: "Hi! We're calling regarding your recent inquiry.",
        prompt: {
          prompt: "You are calling a customer who recently submitted an inquiry. Be helpful and address their concerns.",
          native_mcp_server_ids: ["server1", "server2"]
        }
      }
    },
    dynamic_variables: {
      inquiry_type: "billing_question",
      priority: "high"
    }
  }
)

puts "Enhanced Twilio call initiated: #{twilio_call['callSid']}"
```

## Examples

### Customer Outreach Campaign

```ruby
def initiate_customer_outreach(customer_list, agent_id, phone_number_id)
  puts "📞 Starting Customer Outreach Campaign"
  puts "=" * 40
  
  results = []
  
  customer_list.each_with_index do |customer, index|
    puts "\n#{index + 1}/#{customer_list.length}: Calling #{customer[:name]} (#{customer[:phone]})"
    
    begin
      # Prepare personalized conversation data
      conversation_data = {
        conversation_config_override: {
          agent: {
            first_message: "Hello #{customer[:name]}! This is a courtesy call from our customer service team.",
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
      
      # Choose provider based on phone number type
      if customer[:provider] == "sip"
        call_result = client.outbound_calling.sip_trunk_call(
          agent_id: agent_id,
          agent_phone_number_id: phone_number_id,
          to_number: customer[:phone],
          conversation_initiation_client_data: conversation_data
        )
      else
        call_result = client.outbound_calling.twilio_call(
          agent_id: agent_id,
          agent_phone_number_id: phone_number_id,
          to_number: customer[:phone],
          conversation_initiation_client_data: conversation_data
        )
      end
      
      if call_result['success']
        puts "✅ Call initiated successfully"
        puts "   Conversation ID: #{call_result['conversation_id']}"
        
        results << {
          customer: customer,
          success: true,
          conversation_id: call_result['conversation_id'],
          call_id: call_result['callSid'] || call_result['sip_call_id']
        }
      else
        puts "❌ Call failed: #{call_result['message']}"
        results << {
          customer: customer,
          success: false,
          error: call_result['message']
        }
      end
      
    rescue => e
      puts "❌ Exception: #{e.message}"
      results << {
        customer: customer,
        success: false,
        error: e.message
      }
    end
    
    # Rate limiting between calls
    sleep(2)
  end
  
  # Campaign summary
  successful_calls = results.count { |r| r[:success] }
  puts "\n📊 Campaign Summary:"
  puts "Total customers: #{customer_list.length}"
  puts "Successful calls: #{successful_calls}"
  puts "Failed calls: #{customer_list.length - successful_calls}"
  puts "Success rate: #{(successful_calls.to_f / customer_list.length * 100).round(1)}%"
  
  results
end

# Usage
customers = [
  {
    customer_id: "cust_001",
    name: "John Smith",
    phone: "+1555123456",
    account_status: "active",
    last_interaction: "2024-01-15",
    provider: "twilio"
  },
  {
    customer_id: "cust_002", 
    name: "Jane Doe",
    phone: "+1555987654",
    account_status: "pending",
    last_interaction: "2024-01-10",
    provider: "sip"
  }
]

campaign_results = initiate_customer_outreach(
  customers,
  "customer_service_agent_id",
  "phone_number_id"
)
```

### Emergency Notification System

```ruby
def send_emergency_notifications(emergency_contacts, agent_id, phone_number_id, emergency_info)
  puts "🚨 Emergency Notification System Activated"
  puts "=" * 45
  puts "Emergency: #{emergency_info[:type]}"
  puts "Location: #{emergency_info[:location]}"
  puts "Time: #{emergency_info[:timestamp]}"
  
  results = []
  
  emergency_contacts.each_with_index do |contact, index|
    puts "\n#{index + 1}/#{emergency_contacts.length}: Notifying #{contact[:name]} (#{contact[:role]})"
    
    # Prepare emergency-specific conversation data
    conversation_data = {
      conversation_config_override: {
        agent: {
          first_message: "This is an emergency notification. #{emergency_info[:type]} has been reported at #{emergency_info[:location]}.",
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
      # Use Twilio for reliability in emergency situations
      call_result = client.outbound_calling.twilio_call(
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        to_number: contact[:phone],
        conversation_initiation_client_data: conversation_data
      )
      
      if call_result['success']
        puts "✅ Emergency notification sent"
        puts "   Call ID: #{call_result['callSid']}"
        
        results << {
          contact: contact,
          success: true,
          call_id: call_result['callSid'],
          conversation_id: call_result['conversation_id']
        }
      else
        puts "❌ Notification failed: #{call_result['message']}"
        results << {
          contact: contact,
          success: false,
          error: call_result['message']
        }
      end
      
    rescue => e
      puts "❌ Critical error: #{e.message}"
      results << {
        contact: contact,
        success: false,
        error: e.message
      }
    end
    
    # Minimal delay for emergency situations
    sleep(0.5)
  end
  
  successful_notifications = results.count { |r| r[:success] }
  puts "\n📊 Emergency Notification Summary:"
  puts "Total contacts: #{emergency_contacts.length}"
  puts "Successful notifications: #{successful_notifications}"
  puts "Failed notifications: #{emergency_contacts.length - successful_notifications}"
  
  if successful_notifications < emergency_contacts.length
    puts "\n⚠️ WARNING: Not all emergency contacts were notified!"
  end
  
  results
end

# Usage
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
  }
]

emergency_info = {
  type: "Fire Alarm",
  location: "Building A, Floor 3",
  timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
}

send_emergency_notifications(
  emergency_contacts,
  "emergency_agent_id",
  "emergency_phone_id",
  emergency_info
)
```

### Multi-Provider Call Distribution

```ruby
def distribute_calls_across_providers(call_queue, agents_and_phones)
  puts "📞 Multi-Provider Call Distribution"
  puts "=" * 35
  
  results = []
  provider_stats = Hash.new(0)
  
  call_queue.each_with_index do |call_request, index|
    puts "\n#{index + 1}/#{call_queue.length}: Processing call to #{call_request[:to_number]}"
    
    # Select provider based on availability, cost, or other criteria
    selected_config = select_optimal_provider(agents_and_phones, call_request)
    
    if selected_config.nil?
      puts "❌ No available providers"
      results << { call_request: call_request, success: false, error: "No providers available" }
      next
    end
    
    puts "Using provider: #{selected_config[:provider]} (#{selected_config[:phone_number_id]})"
    
    begin
      conversation_data = {
        conversation_config_override: call_request[:conversation_config],
        user_id: call_request[:user_id],
        dynamic_variables: call_request[:dynamic_variables] || {}
      }
      
      if selected_config[:provider] == "twilio"
        call_result = client.outbound_calling.twilio_call(
          agent_id: selected_config[:agent_id],
          agent_phone_number_id: selected_config[:phone_number_id],
          to_number: call_request[:to_number],
          conversation_initiation_client_data: conversation_data
        )
      else
        call_result = client.outbound_calling.sip_trunk_call(
          agent_id: selected_config[:agent_id],
          agent_phone_number_id: selected_config[:phone_number_id],
          to_number: call_request[:to_number],
          conversation_initiation_client_data: conversation_data
        )
      end
      
      if call_result['success']
        puts "✅ Call initiated via #{selected_config[:provider]}"
        provider_stats[selected_config[:provider]] += 1
        
        results << {
          call_request: call_request,
          success: true,
          provider: selected_config[:provider],
          call_id: call_result['callSid'] || call_result['sip_call_id'],
          conversation_id: call_result['conversation_id']
        }
      else
        puts "❌ Call failed: #{call_result['message']}"
        results << {
          call_request: call_request,
          success: false,
          provider: selected_config[:provider],
          error: call_result['message']
        }
      end
      
    rescue => e
      puts "❌ Exception: #{e.message}"
      results << {
        call_request: call_request,
        success: false,
        provider: selected_config[:provider],
        error: e.message
      }
    end
    
    sleep(1) # Rate limiting
  end
  
  # Distribution summary
  puts "\n📊 Call Distribution Summary:"
  puts "Total calls: #{call_queue.length}"
  successful_calls = results.count { |r| r[:success] }
  puts "Successful: #{successful_calls}"
  puts "Failed: #{call_queue.length - successful_calls}"
  
  puts "\nProvider Distribution:"
  provider_stats.each do |provider, count|
    puts "  #{provider}: #{count} calls"
  end
  
  results
end

def select_optimal_provider(agents_and_phones, call_request)
  # Example selection logic - can be customized based on:
  # - Cost optimization
  # - Geographic routing
  # - Load balancing
  # - Quality metrics
  
  destination_country = call_request[:to_number][0..2] # Simple country detection
  
  # Prefer local providers for better quality/cost
  if destination_country == "+1" # North America
    twilio_configs = agents_and_phones.select { |config| config[:provider] == "twilio" }
    return twilio_configs.first unless twilio_configs.empty?
  end
  
  # Fall back to SIP for international calls (potentially cheaper)
  sip_configs = agents_and_phones.select { |config| config[:provider] == "sip" }
  return sip_configs.first unless sip_configs.empty?
  
  # Use any available provider
  agents_and_phones.first
end

# Usage
call_queue = [
  {
    to_number: "+1555123456",
    user_id: "user_001",
    conversation_config: {
      agent: { first_message: "Hello! This is a test call." }
    }
  },
  {
    to_number: "+44123456789",
    user_id: "user_002",
    conversation_config: {
      agent: { first_message: "Hello! International test call." }
    }
  }
]

providers_config = [
  {
    provider: "twilio",
    agent_id: "agent_twilio",
    phone_number_id: "phone_twilio_001"
  },
  {
    provider: "sip",
    agent_id: "agent_sip",
    phone_number_id: "phone_sip_001"
  }
]

distribute_calls_across_providers(call_queue, providers_config)
```

### Call Quality Monitoring

```ruby
def monitor_outbound_call_quality(call_sessions)
  puts "📊 Outbound Call Quality Monitoring"
  puts "=" * 40
  
  quality_metrics = {
    total_calls: call_sessions.length,
    successful_initiations: 0,
    failed_initiations: 0,
    provider_performance: Hash.new { |h, k| h[k] = { success: 0, failure: 0 } }
  }
  
  call_sessions.each do |session|
    if session[:success]
      quality_metrics[:successful_initiations] += 1
      quality_metrics[:provider_performance][session[:provider]][:success] += 1
      
      # Monitor conversation if available
      if session[:conversation_id]
        monitor_conversation_quality(session[:conversation_id], session[:provider])
      end
    else
      quality_metrics[:failed_initiations] += 1
      quality_metrics[:provider_performance][session[:provider]][:failure] += 1
    end
  end
  
  # Calculate success rates
  success_rate = (quality_metrics[:successful_initiations].to_f / quality_metrics[:total_calls] * 100).round(1)
  
  puts "\n📈 Overall Performance:"
  puts "Total calls attempted: #{quality_metrics[:total_calls]}"
  puts "Successful initiations: #{quality_metrics[:successful_initiations]}"
  puts "Failed initiations: #{quality_metrics[:failed_initiations]}"
  puts "Success rate: #{success_rate}%"
  
  # Provider breakdown
  puts "\n🏢 Provider Performance:"
  quality_metrics[:provider_performance].each do |provider, stats|
    total_provider_calls = stats[:success] + stats[:failure]
    provider_success_rate = total_provider_calls > 0 ? (stats[:success].to_f / total_provider_calls * 100).round(1) : 0
    
    puts "#{provider.upcase}:"
    puts "  Total calls: #{total_provider_calls}"
    puts "  Successful: #{stats[:success]}"
    puts "  Failed: #{stats[:failure]}"
    puts "  Success rate: #{provider_success_rate}%"
    
    # Rate provider performance
    case provider_success_rate
    when 95..100
      puts "  Rating: 🌟 EXCELLENT"
    when 90..94
      puts "  Rating: ✅ GOOD"
    when 80..89
      puts "  Rating: ⚠️ FAIR"
    else
      puts "  Rating: ❌ POOR"
    end
    puts
  end
  
  quality_metrics
end

def monitor_conversation_quality(conversation_id, provider)
  # This would integrate with conversation monitoring
  # For now, we'll simulate basic monitoring
  puts "  🔍 Monitoring conversation #{conversation_id} via #{provider}"
  
  # In a real implementation, you might:
  # - Check conversation duration
  # - Monitor audio quality metrics
  # - Track user satisfaction
  # - Analyze conversation completion rates
end

# Usage (with previous campaign results)
if defined?(campaign_results)
  quality_report = monitor_outbound_call_quality(campaign_results)
end
```

## Error Handling

```ruby
begin
  call_result = client.outbound_calling.twilio_call(
    agent_id: "agent_id",
    agent_phone_number_id: "phone_id",
    to_number: "+1234567890"
  )
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid call parameters: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "Call initiation failed: #{e.message}"
end
```

## Best Practices

### Call Management

1. **Rate Limiting**: Implement appropriate delays between calls to respect provider limits
2. **Error Handling**: Always handle call failures gracefully with retry logic
3. **Monitoring**: Track call success rates and provider performance
4. **Compliance**: Ensure calls comply with local regulations and Do Not Call lists

### Provider Selection

1. **Cost Optimization**: Choose providers based on destination and cost considerations
2. **Quality Metrics**: Monitor call quality and switch providers if needed
3. **Redundancy**: Have backup providers configured for critical calls
4. **Geographic Routing**: Use local providers for better call quality

### Conversation Configuration

1. **Personalization**: Use dynamic variables to personalize call content
2. **Context Setting**: Provide relevant context in the first message
3. **Voice Selection**: Choose appropriate voices for your use case
4. **Language Localization**: Set proper language settings for international calls

## API Reference

For detailed API documentation, visit: [ElevenLabs Outbound Calling API Reference](https://elevenlabs.io/docs/api-reference/convai/outbound-calling)
