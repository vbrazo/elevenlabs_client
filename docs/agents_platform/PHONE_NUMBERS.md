# Phone Numbers Management

The phone numbers endpoints allow you to manage phone numbers for voice-based conversational AI agents, supporting both Twilio and SIP trunk providers.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
phone_numbers = client.phone_numbers
```

## Available Methods

### Import Phone Number

Import a phone number from Twilio or SIP trunk configuration for use with conversational agents.

```ruby
# Import Twilio phone number
twilio_phone = client.phone_numbers.import(
  phone_number: "+1234567890",
  label: "Customer Service Main Line",
  sid: "your_twilio_account_sid",
  token: "your_twilio_auth_token"
)

puts "Imported Twilio phone number: #{twilio_phone['phone_number_id']}"

# Import SIP trunk phone number
sip_phone = client.phone_numbers.import(
  phone_number: "+1987654321",
  label: "Support Line SIP",
  provider_type: "sip_trunk",
  inbound_trunk_config: {
    sip_uri: "sip:inbound@yourdomain.com",
    username: "inbound_user",
    password: "inbound_pass",
    auth_username: "auth_user"
  },
  outbound_trunk_config: {
    sip_uri: "sip:outbound@yourdomain.com",
    username: "outbound_user",
    password: "outbound_pass",
    auth_username: "auth_user_out",
    caller_id: "+1987654321"
  },
  livekit_stack: "standard"
)

puts "Imported SIP trunk phone number: #{sip_phone['phone_number_id']}"
```

### List Phone Numbers

Retrieve all imported phone numbers with their configurations and assigned agents.

```ruby
phone_numbers = client.phone_numbers.list

puts "📞 Available Phone Numbers:"
phone_numbers.each do |phone|
  puts "• #{phone['phone_number']} (#{phone['label']})"
  puts "  ID: #{phone['phone_number_id']}"
  puts "  Provider: #{phone['provider']}"
  puts "  Supports inbound: #{phone['supports_inbound'] ? 'Yes' : 'No'}"
  puts "  Supports outbound: #{phone['supports_outbound'] ? 'Yes' : 'No'}"
  
  if phone['assigned_agent']
    agent = phone['assigned_agent']
    puts "  Assigned agent: #{agent['agent_name']} (#{agent['agent_id']})"
  else
    puts "  No agent assigned"
  end
  
  puts
end
```

### Get Phone Number Details

Retrieve detailed information about a specific phone number.

```ruby
phone_number = client.phone_numbers.get("phone_number_id_here")

puts "📞 Phone Number Details:"
puts "Number: #{phone_number['phone_number']}"
puts "Label: #{phone_number['label']}"
puts "Provider: #{phone_number['provider']}"
puts "ID: #{phone_number['phone_number_id']}"

if phone_number['assigned_agent']
  agent = phone_number['assigned_agent']
  puts "Assigned Agent: #{agent['agent_name']} (#{agent['agent_id']})"
end

puts "Capabilities:"
puts "  Inbound calls: #{phone_number['supports_inbound'] ? 'Supported' : 'Not supported'}"
puts "  Outbound calls: #{phone_number['supports_outbound'] ? 'Supported' : 'Not supported'}"

# For SIP trunk numbers, additional configuration might be available
if phone_number['provider'] == 'sip_trunk'
  puts "\nSIP Configuration:"
  if phone_number['inbound_trunk_config']
    puts "  Inbound URI: #{phone_number['inbound_trunk_config']['sip_uri']}"
  end
  if phone_number['outbound_trunk_config']
    puts "  Outbound URI: #{phone_number['outbound_trunk_config']['sip_uri']}"
    puts "  Caller ID: #{phone_number['outbound_trunk_config']['caller_id']}"
  end
end
```

### Update Phone Number

Update the agent assignment or configuration for a phone number.

```ruby
# Assign an agent to a phone number
updated_phone = client.phone_numbers.update(
  "phone_number_id_here",
  agent_id: "agent_id_to_assign"
)

puts "Updated phone number assignment"
puts "Agent: #{updated_phone['assigned_agent']['agent_name']}"

# Update SIP trunk configuration
updated_sip_phone = client.phone_numbers.update(
  "sip_phone_number_id_here",
  agent_id: "agent_id_here",
  inbound_trunk_config: {
    sip_uri: "sip:new-inbound@yourdomain.com",
    username: "new_inbound_user",
    password: "new_inbound_pass",
    auth_username: "new_auth_user"
  },
  outbound_trunk_config: {
    sip_uri: "sip:new-outbound@yourdomain.com",
    username: "new_outbound_user",
    password: "new_outbound_pass",
    auth_username: "new_auth_user_out",
    caller_id: "+1987654321"
  },
  livekit_stack: "static"
)

puts "Updated SIP trunk configuration"

# Remove agent assignment
unassigned_phone = client.phone_numbers.update(
  "phone_number_id_here",
  agent_id: nil
)

puts "Removed agent assignment from phone number"
```

### Delete Phone Number

Remove a phone number from your account.

```ruby
client.phone_numbers.delete("phone_number_id_here")
puts "Phone number deleted successfully"
```

## Advanced Examples

### Complete Phone Setup Workflow

```ruby
# 1. Create an agent for phone calls
agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a professional customer service representative. Speak clearly and be helpful.",
        llm: "gpt-4o-mini"
      },
      first_message: "Hello! Thank you for calling our customer service line. How may I assist you today?",
      language: "en"
    }
  },
  name: "Phone Customer Service Agent"
)

# 2. Import phone number
phone = client.phone_numbers.import(
  phone_number: "+1555123456",
  label: "Main Customer Service Line",
  sid: "your_twilio_sid",
  token: "your_twilio_token"
)

# 3. Assign agent to phone number
assigned_phone = client.phone_numbers.update(
  phone["phone_number_id"],
  agent_id: agent["agent_id"]
)

# 4. Create tests for phone interactions
phone_test = client.tests.create(
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

# 5. Test the phone agent
test_results = client.tests.run_on_agent(
  agent["agent_id"],
  tests: [{ test_id: phone_test["id"] }]
)

# 6. Monitor test results
test_results['test_runs'].each do |run|
  puts "Phone agent test: #{run['condition_result']['result']}"
end

puts "✅ Phone integration setup complete!"
puts "Phone: #{assigned_phone['phone_number']}"
puts "Agent: #{assigned_phone['assigned_agent']['agent_name']}"
```

### Multi-Channel Agent Setup

```ruby
# Create an agent that works across multiple channels
multi_channel_agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are a versatile customer service agent. Adapt your communication style based on the channel - more formal for phone calls, casual for chat.",
        llm: "gpt-4o-mini"
      },
      first_message: "Hello! How can I help you today?",
      language: "en"
    }
  },
  name: "Multi-Channel Support Agent"
)

# Import multiple phone numbers for different purposes
main_line = client.phone_numbers.import(
  phone_number: "+1555000001",
  label: "Main Support Line",
  sid: "twilio_sid",
  token: "twilio_token"
)

sales_line = client.phone_numbers.import(
  phone_number: "+1555000002", 
  label: "Sales Inquiries",
  sid: "twilio_sid",
  token: "twilio_token"
)

# Assign the same agent to both numbers
[main_line, sales_line].each do |phone|
  client.phone_numbers.update(
    phone["phone_number_id"],
    agent_id: multi_channel_agent["agent_id"]
  )
end

# Create specialized tests for each line
main_support_test = client.tests.create(
  name: "Main Support Line Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "I need help with a technical issue"
    }
  ],
  success_condition: "Agent provides technical support guidance",
  success_examples: [
    {
      response: "I'd be happy to help you resolve this technical issue. Could you describe what's happening?",
      type: "technical_support"
    }
  ],
  failure_examples: [
    {
      response: "I don't handle technical issues",
      type: "unhelpful_response"
    }
  ]
)

sales_test = client.tests.create(
  name: "Sales Line Test",
  chat_history: [
    {
      role: "user",
      time_in_call_secs: 0,
      message: "I'm interested in your products"
    }
  ],
  success_condition: "Agent engages in sales conversation and gathers requirements",
  success_examples: [
    {
      response: "Great! I'd love to help you find the right product. What are you looking for specifically?",
      type: "sales_engagement"
    }
  ],
  failure_examples: [
    {
      response: "Call back later",
      type: "dismissive_response"
    }
  ]
)

# Test both scenarios
test_results = client.tests.run_on_agent(
  multi_channel_agent["agent_id"],
  tests: [
    { test_id: main_support_test["id"] },
    { test_id: sales_test["id"] }
  ]
)

puts "Multi-channel agent testing complete"
test_results['test_runs'].each do |run|
  puts "#{run['test_name']}: #{run['condition_result']['result']}"
end
```

### Enterprise SIP Trunk Setup

```ruby
# Enterprise-grade SIP trunk configuration
enterprise_phone = client.phone_numbers.import(
  phone_number: "+1800ENTERPRISE",
  label: "Enterprise Support Line",
  provider_type: "sip_trunk",
  inbound_trunk_config: {
    sip_uri: "sip:enterprise-inbound@company.com",
    username: "enterprise_in",
    password: "secure_password_123",
    auth_username: "auth_enterprise_in"
  },
  outbound_trunk_config: {
    sip_uri: "sip:enterprise-outbound@company.com",
    username: "enterprise_out", 
    password: "secure_password_456",
    auth_username: "auth_enterprise_out",
    caller_id: "+1800ENTERPRISE"
  },
  livekit_stack: "static"
)

puts "Enterprise SIP trunk imported: #{enterprise_phone['phone_number_id']}"

# Create specialized enterprise agent
enterprise_agent = client.agents.create(
  conversation_config: {
    agent: {
      prompt: {
        prompt: "You are an enterprise customer service representative. Handle inquiries professionally and escalate complex issues appropriately.",
        llm: "gpt-4o-mini"
      },
      first_message: "Thank you for calling our enterprise support line. How may I assist you today?",
      language: "en"
    }
  },
  name: "Enterprise Support Agent"
)

# Assign enterprise agent
client.phone_numbers.update(
  enterprise_phone["phone_number_id"],
  agent_id: enterprise_agent["agent_id"]
)
```

### Phone Number Analytics and Monitoring

```ruby
# Get all phone numbers and analyze their usage
phone_numbers = client.phone_numbers.list

puts "📊 Phone Number Analytics:"
phone_numbers.each do |phone|
  puts "\n#{phone['phone_number']} (#{phone['label']})"
  
  if phone['assigned_agent']
    agent_id = phone['assigned_agent']['agent_id']
    
    # Get conversations for this agent (assuming they're primarily from this phone)
    conversations = client.conversations.list(agent_id: agent_id)
    
    total_conversations = conversations['conversations'].length
    successful_conversations = conversations['conversations'].count do |conv|
      conv['call_successful'] == 'success'
    end
    
    success_rate = total_conversations > 0 ? (successful_conversations.to_f / total_conversations * 100).round(1) : 0
    
    puts "  Agent: #{phone['assigned_agent']['agent_name']}"
    puts "  Total conversations: #{total_conversations}"
    puts "  Successful conversations: #{successful_conversations}"
    puts "  Success rate: #{success_rate}%"
    
    # Performance rating
    case success_rate
    when 90..100
      puts "  Performance: 🌟 EXCELLENT"
    when 75..89
      puts "  Performance: ✅ GOOD"
    when 60..74
      puts "  Performance: ⚠️ NEEDS IMPROVEMENT"
    else
      puts "  Performance: ❌ POOR"
    end
    
    # Get recent conversations
    recent_conversations = conversations['conversations'].first(3)
    puts "  Recent conversations:"
    recent_conversations.each do |conv|
      start_time = Time.at(conv['call_start_time_unix_secs']).strftime('%Y-%m-%d %H:%M')
      puts "    - #{start_time}: #{conv['call_successful'] || 'unknown'}"
    end
  else
    puts "  ⚠️ No agent assigned"
  end
end
```

### Global Phone Number Management

```ruby
# Multi-region phone setup for global support
regions = [
  {
    region: "US East",
    phone: "+1555000001",
    agent_prompt: "You are a US customer service representative.",
    timezone: "America/New_York"
  },
  {
    region: "US West", 
    phone: "+1555000002",
    agent_prompt: "You are a US West Coast customer service representative.",
    timezone: "America/Los_Angeles"
  },
  {
    region: "Europe",
    phone: "+44123456789",
    agent_prompt: "You are a European customer service representative. Be mindful of GDPR compliance.",
    timezone: "Europe/London"
  },
  {
    region: "Asia Pacific",
    phone: "+81123456789",
    agent_prompt: "You are an Asia Pacific customer service representative.",
    timezone: "Asia/Tokyo"
  }
]

regional_setup = []

regions.each do |region_info|
  puts "Setting up #{region_info[:region]}..."
  
  # Create region-specific agent
  agent = client.agents.create(
    conversation_config: {
      agent: {
        prompt: {
          prompt: region_info[:agent_prompt],
          llm: "gpt-4o-mini"
        },
        first_message: "Hello! Thank you for calling our support line. How may I assist you today?",
        language: "en"
      }
    },
    name: "#{region_info[:region]} Support Agent"
  )
  
  # Import phone number (using SIP trunk for international)
  if region_info[:phone].start_with?("+1")
    # US number via Twilio
    phone = client.phone_numbers.import(
      phone_number: region_info[:phone],
      label: "#{region_info[:region]} Support",
      sid: "twilio_sid",
      token: "twilio_token"
    )
  else
    # International via SIP trunk
    phone = client.phone_numbers.import(
      phone_number: region_info[:phone],
      label: "#{region_info[:region]} Support",
      provider_type: "sip_trunk",
      inbound_trunk_config: {
        sip_uri: "sip:#{region_info[:region].downcase.gsub(' ', '-')}-inbound@company.com",
        username: "#{region_info[:region].downcase.gsub(' ', '_')}_user",
        password: "secure_pass_#{region_info[:region].downcase.gsub(' ', '_')}",
        auth_username: "auth_#{region_info[:region].downcase.gsub(' ', '_')}"
      },
      outbound_trunk_config: {
        sip_uri: "sip:#{region_info[:region].downcase.gsub(' ', '-')}-outbound@company.com",
        username: "#{region_info[:region].downcase.gsub(' ', '_')}_out",
        password: "secure_pass_out_#{region_info[:region].downcase.gsub(' ', '_')}",
        auth_username: "auth_out_#{region_info[:region].downcase.gsub(' ', '_')}",
        caller_id: region_info[:phone]
      }
    )
  end
  
  # Assign agent to phone
  client.phone_numbers.update(
    phone["phone_number_id"],
    agent_id: agent["agent_id"]
  )
  
  regional_setup << {
    region: region_info[:region],
    phone_id: phone["phone_number_id"],
    phone_number: region_info[:phone],
    agent_id: agent["agent_id"],
    timezone: region_info[:timezone]
  }
  
  puts "✅ #{region_info[:region]} setup complete"
end

puts "\n🌍 Global Phone Support Network:"
regional_setup.each do |setup|
  puts "#{setup[:region]}: #{setup[:phone_number]}"
  puts "  Agent: #{setup[:agent_id]}"
  puts "  Timezone: #{setup[:timezone]}"
end
```

### Bulk Phone Management Operations

```ruby
def bulk_assign_agents(phone_agent_pairs)
  puts "🔄 Bulk Agent Assignment"
  puts "=" * 30
  
  results = []
  
  phone_agent_pairs.each do |pair|
    phone_id = pair[:phone_number_id]
    agent_id = pair[:agent_id]
    
    begin
      puts "Assigning #{agent_id} to #{phone_id}..."
      result = client.phone_numbers.update(phone_id, agent_id: agent_id)
      
      results << {
        phone_number_id: phone_id,
        agent_id: agent_id,
        success: true,
        phone_number: result['phone_number']
      }
      
      puts "✅ Success: #{result['phone_number']}"
    rescue => e
      puts "❌ Failed: #{e.message}"
      results << {
        phone_number_id: phone_id,
        agent_id: agent_id,
        success: false,
        error: e.message
      }
    end
    
    sleep(0.5) # Rate limiting
  end
  
  successful = results.count { |r| r[:success] }
  puts "\n📊 Bulk Assignment Results:"
  puts "Successful: #{successful}/#{results.length}"
  puts "Failed: #{results.length - successful}"
  
  results
end

# Usage
assignments = [
  { phone_number_id: "phone1", agent_id: "agent1" },
  { phone_number_id: "phone2", agent_id: "agent2" },
  { phone_number_id: "phone3", agent_id: "agent1" }
]

bulk_assign_agents(assignments)
```

## Error Handling

```ruby
begin
  phone = client.phone_numbers.import(
    phone_number: "+1234567890",
    label: "Test Line",
    sid: "invalid_sid",
    token: "invalid_token"
  )
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid phone configuration: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Twilio authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Phone Number Management

1. **Descriptive Labels**: Use clear, descriptive labels for easy identification
2. **Consistent Naming**: Follow naming conventions across all phone numbers
3. **Documentation**: Keep records of phone number purposes and configurations
4. **Access Control**: Limit access to phone number management to authorized users

### Agent Assignment

1. **Purpose Matching**: Assign agents that match the phone line's purpose
2. **Load Balancing**: Distribute calls across multiple agents when possible
3. **Backup Agents**: Have backup agents ready for high-traffic lines
4. **Performance Monitoring**: Regularly review agent performance on each line

### SIP Trunk Configuration

1. **Security**: Use strong passwords and secure authentication
2. **Redundancy**: Configure backup SIP trunks for critical lines
3. **Quality Monitoring**: Monitor call quality and latency
4. **Compliance**: Ensure configurations meet regulatory requirements

### Performance Optimization

1. **Regular Testing**: Test phone integrations regularly
2. **Performance Metrics**: Track call success rates and quality
3. **Configuration Tuning**: Optimize settings based on usage patterns
4. **Capacity Planning**: Monitor usage and plan for scaling

## API Reference

For detailed API documentation, visit: [ElevenLabs Phone Numbers API Reference](https://elevenlabs.io/docs/api-reference/convai/phone-numbers)
