# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Tools endpoints
# This file demonstrates how to use the tools endpoints in a practical application

require 'elevenlabs_client'

class ToolsController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # List all available tools in the workspace
  def list_tools
    puts "Fetching tools list..."
    
    response = @client.tools.list
    tools = response["tools"]
    
    puts "\n🔧 Found #{tools.length} tools:"
    tools.each do |tool|
      config = tool['tool_config']
      stats = tool['usage_stats']
      access = tool['access_info']
      
      puts "  • #{tool['id']}"
      puts "    Name: #{config['name']}"
      puts "    Description: #{config['description']}"
      puts "    Type: #{config['type']}"
      
      if config['api_schema']
        puts "    URL: #{config['api_schema']['url']}"
        puts "    Method: #{config['api_schema']['method']}"
      end
      
      puts "    Timeout: #{config['response_timeout_secs']}s"
      puts "    Creator: #{access['creator_name']} (#{access['creator_email']})"
      puts "    Usage: #{stats['total_calls']} calls, #{stats['avg_latency_secs']}s avg latency"
      puts
    end
    
    tools
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching tools: #{e.message}"
    []
  end

  # Get detailed information about a specific tool
  def get_tool_details(tool_id)
    puts "Fetching details for tool: #{tool_id}"
    
    tool = @client.tools.get(tool_id)
    config = tool['tool_config']
    
    puts "\n🔧 Tool Details:"
    puts "ID: #{tool['id']}"
    puts "Name: #{config['name']}"
    puts "Description: #{config['description']}"
    puts "Type: #{config['type']}"
    
    # API Schema details
    if config['api_schema']
      schema = config['api_schema']
      puts "\n🌐 API Schema:"
      puts "  URL: #{schema['url']}"
      puts "  Method: #{schema['method']}"
      
      if schema['query_params_schema']
        puts "  Query Parameters:"
        schema['query_params_schema']['properties']&.each do |param, details|
          required = schema['query_params_schema']['required']&.include?(param) ? " (required)" : ""
          puts "    #{param}: #{details['type']}#{required} - #{details['description']}"
        end
      end
      
      if schema['request_body_schema']
        puts "  Request Body:"
        schema['request_body_schema']['properties']&.each do |field, details|
          required = schema['request_body_schema']['required']&.include?(field) ? " (required)" : ""
          puts "    #{field}: #{details['type']}#{required} - #{details['description']}"
        end
      end
      
      if schema['request_headers']
        puts "  Headers:"
        schema['request_headers'].each do |header, value|
          puts "    #{header}: #{value}"
        end
      end
    end
    
    # Configuration details
    puts "\n⚙️ Configuration:"
    puts "  Response Timeout: #{config['response_timeout_secs']}s"
    puts "  Disable Interruptions: #{config['disable_interruptions']}"
    puts "  Force Pre-tool Speech: #{config['force_pre_tool_speech']}"
    
    if config['assignments']&.any?
      puts "  Variable Assignments:"
      config['assignments'].each do |assignment|
        puts "    #{assignment['dynamic_variable']} = #{assignment['value_path']} (from #{assignment['source']})"
      end
    end
    
    # Usage statistics
    stats = tool['usage_stats']
    puts "\n📊 Usage Statistics:"
    puts "  Total Calls: #{stats['total_calls']}"
    puts "  Average Latency: #{stats['avg_latency_secs']}s"
    
    # Access information
    access = tool['access_info']
    puts "\n👤 Access Information:"
    puts "  Creator: #{access['creator_name']} (#{access['creator_email']})"
    puts "  Role: #{access['role']}"
    puts "  Is Creator: #{access['is_creator']}"
    
    tool
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Tool not found: #{tool_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching tool: #{e.message}"
    nil
  end

  # Create a new webhook tool
  def create_weather_tool
    puts "Creating a weather API tool..."
    
    tool_config = {
      name: "Weather API",
      description: "Get current weather information for any city worldwide",
      api_schema: {
        url: "https://api.openweathermap.org/data/2.5/weather",
        method: "GET",
        query_params_schema: {
          properties: {
            q: {
              type: "string",
              description: "City name, state code (only for US) and country code divided by comma"
            },
            units: {
              type: "string",
              enum: ["standard", "metric", "imperial"],
              description: "Units of measurement (default: standard)"
            },
            lang: {
              type: "string",
              description: "Language for weather description"
            }
          },
          required: ["q"]
        },
        request_headers: {
          "Content-Type" => "application/json"
        }
      },
      response_timeout_secs: 30,
      disable_interruptions: false,
      force_pre_tool_speech: false,
      assignments: [
        {
          source: "response",
          dynamic_variable: "current_temperature",
          value_path: "$.main.temp"
        },
        {
          source: "response",
          dynamic_variable: "weather_description",
          value_path: "$.weather[0].description"
        },
        {
          source: "response",
          dynamic_variable: "city_name",
          value_path: "$.name"
        }
      ]
    }

    response = @client.tools.create(tool_config: tool_config)
    tool_id = response["id"]
    
    puts "✅ Weather tool created successfully!"
    puts "Tool ID: #{tool_id}"
    puts "Name: #{response['tool_config']['name']}"
    
    tool_id
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Create a support ticket creation tool
  def create_ticket_tool
    puts "Creating a support ticket creation tool..."
    
    tool_config = {
      name: "Create Support Ticket",
      description: "Create a new support ticket in the helpdesk system",
      api_schema: {
        url: "https://api.helpdesk.com/v1/tickets",
        method: "POST",
        request_body_schema: {
          type: "object",
          properties: {
            title: {
              type: "string",
              description: "The ticket title or subject"
            },
            description: {
              type: "string",
              description: "Detailed description of the issue or request"
            },
            priority: {
              type: "string",
              enum: ["low", "medium", "high", "urgent"],
              description: "Priority level of the ticket"
            },
            category: {
              type: "string",
              enum: ["technical", "billing", "general", "feature_request"],
              description: "Category of the support request"
            },
            customer_email: {
              type: "string",
              format: "email",
              description: "Customer's email address"
            },
            customer_name: {
              type: "string",
              description: "Customer's full name"
            }
          },
          required: ["title", "description", "customer_email"]
        },
        request_headers: {
          "Authorization" => "Bearer ${HELPDESK_API_KEY}",
          "Content-Type" => "application/json"
        }
      },
      response_timeout_secs: 45,
      disable_interruptions: true,
      assignments: [
        {
          source: "response",
          dynamic_variable: "ticket_id",
          value_path: "$.ticket.id"
        },
        {
          source: "response",
          dynamic_variable: "ticket_url",
          value_path: "$.ticket.url"
        },
        {
          source: "response",
          dynamic_variable: "ticket_status",
          value_path: "$.ticket.status"
        }
      ]
    }

    response = @client.tools.create(tool_config: tool_config)
    tool_id = response["id"]
    
    puts "✅ Support ticket tool created successfully!"
    puts "Tool ID: #{tool_id}"
    puts "Name: #{response['tool_config']['name']}"
    
    tool_id
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Update an existing tool
  def update_tool(tool_id, updates = {})
    puts "Updating tool: #{tool_id}"
    
    # Get current tool configuration
    current_tool = @client.tools.get(tool_id)
    current_config = current_tool['tool_config']
    
    # Merge updates with current configuration
    updated_config = current_config.merge(updates)
    
    response = @client.tools.update(tool_id, tool_config: updated_config)
    
    puts "✅ Tool updated successfully!"
    puts "Name: #{response['tool_config']['name']}"
    puts "Description: #{response['tool_config']['description']}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Tool not found: #{tool_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error updating tool: #{e.message}"
    nil
  end

  # Delete a tool
  def delete_tool(tool_id)
    puts "Deleting tool: #{tool_id}"
    
    # Check for dependent agents first
    dependent_agents = get_dependent_agents(tool_id)
    
    if dependent_agents && dependent_agents["agents"].any?
      puts "⚠️ Warning: This tool is used by #{dependent_agents['agents'].length} agent(s):"
      dependent_agents["agents"].each do |agent|
        puts "  • #{agent['id']}: #{agent['name']}"
      end
      
      print "Are you sure you want to delete this tool? (y/N): "
      confirmation = gets.chomp.downcase
      
      return unless confirmation == 'y' || confirmation == 'yes'
    end
    
    @client.tools.delete(tool_id)
    puts "✅ Tool deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Tool not found: #{tool_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting tool: #{e.message}"
  end

  # Get agents that depend on a specific tool
  def get_dependent_agents(tool_id, page_size: 20)
    puts "Fetching dependent agents for tool: #{tool_id}"
    
    response = @client.tools.get_dependent_agents(tool_id, page_size: page_size)
    agents = response["agents"]
    
    if agents.any?
      puts "\n🤖 Found #{agents.length} dependent agents:"
      agents.each do |agent|
        puts "  • #{agent['id']}"
        puts "    Name: #{agent['name']}" if agent['name']
        puts "    Type: #{agent['type']}"
        puts
      end
      
      if response["has_more"]
        puts "💡 More agents available. Use cursor: #{response['next_cursor']}"
      end
    else
      puts "✅ No agents depend on this tool"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Tool not found: #{tool_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching dependent agents: #{e.message}"
    nil
  end

  # Create a comprehensive CRM integration tool
  def create_crm_tool
    puts "Creating a comprehensive CRM integration tool..."
    
    tool_config = {
      name: "CRM Customer Lookup",
      description: "Query customer information and order history from the CRM system",
      api_schema: {
        url: "https://api.yourcrm.com/v2/customers",
        method: "GET",
        query_params_schema: {
          properties: {
            customer_id: {
              type: "string",
              description: "The unique customer identifier"
            },
            email: {
              type: "string",
              format: "email",
              description: "Customer's email address (alternative to customer_id)"
            },
            phone: {
              type: "string",
              description: "Customer's phone number (alternative to customer_id)"
            },
            include_orders: {
              type: "boolean",
              description: "Include customer's order history",
              default: false
            },
            include_preferences: {
              type: "boolean",
              description: "Include customer preferences and settings",
              default: false
            },
            order_limit: {
              type: "integer",
              description: "Maximum number of recent orders to include",
              minimum: 1,
              maximum: 50,
              default: 10
            }
          },
          anyOf: [
            { required: ["customer_id"] },
            { required: ["email"] },
            { required: ["phone"] }
          ]
        },
        request_headers: {
          "Authorization" => "Bearer ${CRM_API_KEY}",
          "Content-Type" => "application/json",
          "X-Client-Version" => "v2.0"
        }
      },
      response_timeout_secs: 25,
      disable_interruptions: false,
      assignments: [
        {
          source: "response",
          dynamic_variable: "customer_name",
          value_path: "$.customer.full_name"
        },
        {
          source: "response",
          dynamic_variable: "customer_tier",
          value_path: "$.customer.tier"
        },
        {
          source: "response",
          dynamic_variable: "customer_since",
          value_path: "$.customer.created_at"
        },
        {
          source: "response",
          dynamic_variable: "total_orders",
          value_path: "$.customer.order_count"
        },
        {
          source: "response",
          dynamic_variable: "lifetime_value",
          value_path: "$.customer.lifetime_value"
        }
      ],
      dynamic_variables: {
        dynamic_variable_placeholders: {
          "customer_name" => "Unknown Customer",
          "customer_tier" => "Standard",
          "total_orders" => "0",
          "lifetime_value" => "$0.00"
        }
      }
    }

    response = @client.tools.create(tool_config: tool_config)
    tool_id = response["id"]
    
    puts "✅ CRM tool created successfully!"
    puts "Tool ID: #{tool_id}"
    puts "Name: #{response['tool_config']['name']}"
    
    tool_id
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Analyze tool usage patterns
  def analyze_tool_usage
    puts "Analyzing tool usage patterns..."
    
    tools = list_tools
    return if tools.empty?
    
    puts "\n📊 Tool Usage Analysis:"
    
    # Sort by total calls
    sorted_by_usage = tools.sort_by { |tool| -tool['usage_stats']['total_calls'] }
    
    puts "\n🔝 Most Used Tools:"
    sorted_by_usage.first(5).each_with_index do |tool, index|
      stats = tool['usage_stats']
      puts "#{index + 1}. #{tool['tool_config']['name']}"
      puts "   Calls: #{stats['total_calls']}, Latency: #{stats['avg_latency_secs']}s"
    end
    
    # Sort by latency
    sorted_by_latency = tools.select { |tool| tool['usage_stats']['total_calls'] > 0 }
                            .sort_by { |tool| tool['usage_stats']['avg_latency_secs'] }
    
    if sorted_by_latency.any?
      puts "\n⚡ Fastest Tools (with usage):"
      sorted_by_latency.first(3).each_with_index do |tool, index|
        stats = tool['usage_stats']
        puts "#{index + 1}. #{tool['tool_config']['name']}"
        puts "   Latency: #{stats['avg_latency_secs']}s, Calls: #{stats['total_calls']}"
      end
      
      puts "\n🐌 Slowest Tools:"
      sorted_by_latency.last(3).reverse.each_with_index do |tool, index|
        stats = tool['usage_stats']
        puts "#{index + 1}. #{tool['tool_config']['name']}"
        puts "   Latency: #{stats['avg_latency_secs']}s, Calls: #{stats['total_calls']}"
      end
    end
    
    # Unused tools
    unused_tools = tools.select { |tool| tool['usage_stats']['total_calls'] == 0 }
    if unused_tools.any?
      puts "\n🚫 Unused Tools (#{unused_tools.length}):"
      unused_tools.each do |tool|
        puts "  • #{tool['tool_config']['name']}"
      end
    end
    
    # Summary statistics
    total_calls = tools.sum { |tool| tool['usage_stats']['total_calls'] }
    avg_latency = tools.select { |tool| tool['usage_stats']['total_calls'] > 0 }
                       .map { |tool| tool['usage_stats']['avg_latency_secs'] }
                       .sum.to_f / tools.count
    
    puts "\n📈 Summary:"
    puts "  Total Tools: #{tools.length}"
    puts "  Total API Calls: #{total_calls}"
    puts "  Average Latency: #{avg_latency.round(2)}s"
    puts "  Active Tools: #{tools.count { |tool| tool['usage_stats']['total_calls'] > 0 }}"
    puts "  Unused Tools: #{unused_tools.length}"
    
    {
      total_tools: tools.length,
      total_calls: total_calls,
      average_latency: avg_latency,
      active_tools: tools.count { |tool| tool['usage_stats']['total_calls'] > 0 },
      unused_tools: unused_tools.length
    }
  end

  # Complete workflow demonstration
  def demo_workflow
    puts "🚀 Starting Tools Management Demo Workflow"
    puts "=" * 50
    
    # 1. List existing tools
    puts "\n1️⃣ Listing existing tools..."
    tools = list_tools
    
    sleep(1)
    
    # 2. Create new tools
    puts "\n2️⃣ Creating example tools..."
    weather_tool_id = create_weather_tool
    sleep(1)
    ticket_tool_id = create_ticket_tool
    sleep(1)
    crm_tool_id = create_crm_tool
    
    sleep(1)
    
    # 3. Get details of created tools
    if weather_tool_id
      puts "\n3️⃣ Getting weather tool details..."
      get_tool_details(weather_tool_id)
      sleep(1)
    end
    
    # 4. Update a tool
    if ticket_tool_id
      puts "\n4️⃣ Updating ticket tool..."
      update_tool(ticket_tool_id, {
        description: "Enhanced support ticket creation with priority routing",
        response_timeout_secs: 60
      })
      sleep(1)
    end
    
    # 5. Check for dependent agents
    if crm_tool_id
      puts "\n5️⃣ Checking dependent agents..."
      get_dependent_agents(crm_tool_id)
      sleep(1)
    end
    
    # 6. Analyze usage
    puts "\n6️⃣ Analyzing tool usage..."
    analyze_tool_usage
    
    puts "\n✨ Demo workflow completed successfully!"
    puts "Created tools:"
    puts "  Weather Tool: #{weather_tool_id}" if weather_tool_id
    puts "  Ticket Tool: #{ticket_tool_id}" if ticket_tool_id
    puts "  CRM Tool: #{crm_tool_id}" if crm_tool_id
    
    {
      weather_tool_id: weather_tool_id,
      ticket_tool_id: ticket_tool_id,
      crm_tool_id: crm_tool_id
    }
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = ToolsController.new

  # Run the demo workflow
  controller.demo_workflow
end
