# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform endpoints
# This file demonstrates how to use the agents endpoints in a practical application

require 'elevenlabs_client'

class AgentsController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # Create a new conversational agent
  def create_agent
    puts "Creating a new customer support agent..."
    
    agent_config = {
      name: "Customer Support Assistant",
      conversation_config: {
        agent: {
          prompt: {
            prompt: "You are a helpful customer support agent for TechCorp. " \
                   "You assist customers with product inquiries, technical issues, and order support. " \
                   "Be friendly, professional, and solution-oriented.",
            llm: "gpt-4o-mini",
            temperature: 0.7,
            max_tokens: 150
          },
          first_message: "Hello! Welcome to TechCorp support. I'm here to help you with any questions about our products or services. How can I assist you today?",
          language: "en"
        },
        tts: {
          voice_id: "cjVigY5qzO86Huf0OWal",
          model_id: "eleven_turbo_v2",
          stability: 0.5,
          similarity_boost: 0.8
        },
        conversation: {
          max_duration_seconds: 600,
          text_only: false
        }
      },
      platform_settings: {
        widget: {
          theme: "light",
          position: "bottom-right"
        }
      },
      tags: ["customer-support", "general", "techcorp"]
    }

    response = @client.agents.create(**agent_config)
    agent_id = response["agent_id"]
    
    puts "✅ Agent created successfully!"
    puts "Agent ID: #{agent_id}"
    
    agent_id
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # List all agents with filtering
  def list_agents(search: nil, limit: 10)
    puts "Fetching agents list..."
    
    options = { page_size: limit }
    options[:search] = search if search
    options[:sort_by] = "created_at"
    options[:sort_direction] = "desc"
    
    response = @client.agents.list(**options)
    agents = response["agents"]
    
    puts "\n📋 Found #{agents.length} agents:"
    agents.each do |agent|
      puts "  • #{agent['name']} (#{agent['agent_id']})"
      puts "    Created: #{Time.at(agent['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Tags: #{agent['tags']&.join(', ') || 'None'}"
      puts
    end
    
    agents
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching agents: #{e.message}"
    []
  end

  # Get detailed information about a specific agent
  def get_agent_details(agent_id)
    puts "Fetching details for agent: #{agent_id}"
    
    agent = @client.agents.get(agent_id)
    
    puts "\n🤖 Agent Details:"
    puts "Name: #{agent['name']}"
    puts "ID: #{agent['agent_id']}"
    puts "Created: #{Time.at(agent['metadata']['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Updated: #{Time.at(agent['metadata']['updated_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    puts "Tags: #{agent['tags']&.join(', ') || 'None'}"
    
    # Show conversation config summary
    config = agent['conversation_config']
    if config
      puts "\n⚙️ Configuration:"
      puts "  LLM: #{config.dig('agent', 'prompt', 'llm')}"
      puts "  Voice: #{config.dig('tts', 'voice_id')}"
      puts "  Language: #{config.dig('agent', 'language')}"
      puts "  First Message: #{config.dig('agent', 'first_message')}"
    end
    
    agent
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching agent: #{e.message}"
    nil
  end

  # Update an existing agent
  def update_agent(agent_id, name: nil, tags: nil, **config_updates)
    puts "Updating agent: #{agent_id}"
    
    update_params = {}
    update_params[:name] = name if name
    update_params[:tags] = tags if tags
    update_params[:conversation_config] = config_updates if config_updates.any?
    
    response = @client.agents.update(agent_id, **update_params)
    
    puts "✅ Agent updated successfully!"
    puts "Name: #{response['name']}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error updating agent: #{e.message}"
    nil
  end

  # Duplicate an existing agent
  def duplicate_agent(source_agent_id, new_name)
    puts "Duplicating agent: #{source_agent_id}"
    
    response = @client.agents.duplicate(source_agent_id, name: new_name)
    new_agent_id = response["agent_id"]
    
    puts "✅ Agent duplicated successfully!"
    puts "New Agent ID: #{new_agent_id}"
    
    new_agent_id
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Source agent not found: #{source_agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error duplicating agent: #{e.message}"
    nil
  end

  # Test an agent with a simulated conversation
  def test_agent_conversation(agent_id, user_persona: "A customer with a general inquiry")
    puts "Testing agent conversation: #{agent_id}"
    
    simulation_config = {
      simulation_specification: {
        simulated_user_config: {
          persona: user_persona,
          goals: ["Get helpful information", "Have a pleasant interaction"]
        }
      },
      extra_evaluation_criteria: [
        {
          name: "Helpfulness",
          description: "How helpful and informative was the agent's response?",
          scale: "1-5"
        },
        {
          name: "Tone",
          description: "Was the agent's tone appropriate and professional?",
          scale: "1-5"
        },
        {
          name: "Problem Resolution",
          description: "Did the agent address the user's needs effectively?",
          scale: "1-5"
        }
      ],
      new_turns_limit: 8
    }
    
    puts "Running conversation simulation..."
    result = @client.agents.simulate_conversation(agent_id, **simulation_config)
    
    puts "\n💬 Conversation Simulation Results:"
    puts "Success: #{result['analysis']['call_successful']}"
    puts "Summary: #{result['analysis']['transcript_summary']}"
    
    # Show conversation turns
    conversation = result['simulated_conversation']
    puts "\n📝 Conversation Transcript:"
    conversation.each_with_index do |turn, index|
      speaker = turn['role'] == 'user' ? '👤 User' : '🤖 Agent'
      puts "#{index + 1}. #{speaker}: #{turn['message']}"
    end
    
    # Show evaluation results
    if result['analysis']['evaluation_criteria_results']
      puts "\n📊 Evaluation Results:"
      result['analysis']['evaluation_criteria_results'].each do |criterion, score|
        puts "  #{criterion}: #{score}"
      end
    end
    
    result
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error running simulation: #{e.message}"
    nil
  end

  # Stream a conversation simulation
  def test_agent_conversation_stream(agent_id, user_persona: "A customer with a technical question")
    puts "Starting streaming conversation test for agent: #{agent_id}"
    
    simulation_config = {
      simulation_specification: {
        simulated_user_config: {
          persona: user_persona,
          goals: ["Get technical help", "Understand the solution"]
        }
      },
      new_turns_limit: 6
    }
    
    puts "🔄 Streaming conversation simulation..."
    
    @client.agents.simulate_conversation_stream(agent_id, **simulation_config) do |chunk|
      # Handle streaming response chunks
      puts "📡 Received chunk: #{chunk.inspect}"
    end
    
    puts "✅ Streaming simulation completed"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error in streaming simulation: #{e.message}"
  end

  # Calculate LLM usage and costs
  def calculate_agent_costs(agent_id, prompt_length: 1000, pages: 5, rag_enabled: false)
    puts "Calculating LLM usage for agent: #{agent_id}"
    
    usage_params = {
      prompt_length: prompt_length,
      number_of_pages: pages,
      rag_enabled: rag_enabled
    }
    
    result = @client.agents.calculate_llm_usage(agent_id, **usage_params)
    
    puts "\n💰 LLM Usage Estimates:"
    result['llm_prices'].each do |price_info|
      puts "  #{price_info['llm']}: $#{price_info['price_per_minute']} per minute"
    end
    
    result
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error calculating usage: #{e.message}"
    nil
  end

  # Get shareable link for an agent
  def get_agent_link(agent_id)
    puts "Getting shareable link for agent: #{agent_id}"
    
    link_info = @client.agents.link(agent_id)
    
    puts "🔗 Agent Link Information:"
    puts "Agent ID: #{link_info['agent_id']}"
    
    if link_info['token']
      puts "Token: #{link_info['token']['token']}"
      puts "Expires: #{Time.at(link_info['token']['expires_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    end
    
    link_info
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error getting link: #{e.message}"
    nil
  end

  # Delete an agent
  def delete_agent(agent_id)
    puts "Deleting agent: #{agent_id}"
    
    print "Are you sure you want to delete this agent? (y/N): "
    confirmation = gets.chomp.downcase
    
    return unless confirmation == 'y' || confirmation == 'yes'
    
    @client.agents.delete(agent_id)
    puts "✅ Agent deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting agent: #{e.message}"
  end

  # Complete workflow example
  def demo_workflow
    puts "🚀 Starting Agents Platform Demo Workflow"
    puts "=" * 50
    
    # 1. Create a new agent
    agent_id = create_agent
    return unless agent_id
    
    sleep(1) # Brief pause for API
    
    # 2. List agents to confirm creation
    list_agents(limit: 5)
    
    sleep(1)
    
    # 3. Get agent details
    get_agent_details(agent_id)
    
    sleep(1)
    
    # 4. Update the agent
    update_agent(
      agent_id,
      name: "Enhanced Customer Support Assistant",
      tags: ["customer-support", "enhanced", "demo"]
    )
    
    sleep(1)
    
    # 5. Test the agent with a conversation
    test_agent_conversation(
      agent_id,
      user_persona: "A customer who bought a laptop and is having trouble setting it up"
    )
    
    sleep(1)
    
    # 6. Calculate usage costs
    calculate_agent_costs(agent_id, prompt_length: 1500, pages: 10, rag_enabled: true)
    
    sleep(1)
    
    # 7. Get shareable link
    get_agent_link(agent_id)
    
    puts "\n✨ Demo workflow completed successfully!"
    puts "Agent ID for further testing: #{agent_id}"
    
    agent_id
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = AgentsController.new

  # Run the demo workflow
  controller.demo_workflow
end
