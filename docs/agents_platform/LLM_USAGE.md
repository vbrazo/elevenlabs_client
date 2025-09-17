# LLM Usage Calculation

Calculate expected LLM token usage and costs for conversational AI agents based on prompt characteristics and knowledge base configuration.

## Overview

This endpoint provides **general LLM usage calculation** based on configuration parameters. For **agent-specific** LLM usage calculation, use `client.agents.calculate_llm_usage(agent_id, ...)` instead.

### Difference Between General and Agent-Specific Calculation

- **General calculation** (`client.llm_usage.calculate`): Calculate costs based on prompt length, knowledge base size, and RAG settings
- **Agent-specific calculation** (`client.agents.calculate_llm_usage`): Calculate costs for an existing agent using its current configuration

Use the general calculation for:
- Planning agent configurations before creation
- Comparing different configuration scenarios
- Cost estimation during development

Use agent-specific calculation for:
- Getting usage estimates for existing agents
- Monitoring costs of deployed agents

## Available Methods

- `client.llm_usage.calculate(prompt_length:, number_of_pages:, rag_enabled:)` - Calculate expected LLM usage and costs
- `client.llm_usage.calculate_usage(prompt_length:, number_of_pages:, rag_enabled:)` - Alias for calculate

## Usage Examples

### Basic Usage Calculation

```ruby
client = ElevenlabsClient.new

# Calculate LLM usage for a simple agent
usage_info = client.llm_usage.calculate(
  prompt_length: 500,      # Length of the agent's prompt in characters
  number_of_pages: 0,      # No knowledge base documents
  rag_enabled: false       # RAG not enabled
)

puts "Available LLM models and pricing:"
usage_info["llm_prices"].each do |model|
  puts "#{model['llm']}: $#{model['price_per_minute']} per minute"
end
```

### Knowledge Base-Enabled Agent

```ruby
# Calculate usage for an agent with knowledge base
usage_info = client.llm_usage.calculate(
  prompt_length: 1200,     # Longer prompt with instructions
  number_of_pages: 25,     # 25 pages of PDF/URL content in knowledge base
  rag_enabled: true        # RAG enabled for knowledge retrieval
)

puts "LLM pricing with RAG enabled:"
usage_info["llm_prices"].each do |model|
  puts "Model: #{model['llm']}"
  puts "Cost per minute: $#{model['price_per_minute']}"
  puts "---"
end
```

### Comparing Different Configurations

```ruby
# Compare costs for different agent configurations
configurations = [
  { name: "Simple Agent", prompt_length: 300, pages: 0, rag: false },
  { name: "Knowledge Agent", prompt_length: 800, pages: 15, rag: true },
  { name: "Complex Agent", prompt_length: 1500, pages: 50, rag: true }
]

configurations.each do |config|
  puts "\n=== #{config[:name]} ==="
  
  usage = client.llm_usage.calculate(
    prompt_length: config[:prompt_length],
    number_of_pages: config[:pages],
    rag_enabled: config[:rag]
  )
  
  puts "Configuration:"
  puts "- Prompt length: #{config[:prompt_length]} characters"
  puts "- Knowledge base pages: #{config[:pages]}"
  puts "- RAG enabled: #{config[:rag]}"
  puts
  
  puts "LLM Pricing:"
  usage["llm_prices"].each do |model|
    puts "  #{model['llm']}: $#{model['price_per_minute']}/minute"
  end
end
```

### Cost Optimization Analysis

```ruby
# Analyze cost impact of different knowledge base sizes
prompt_length = 1000
rag_enabled = true

puts "Cost analysis for different knowledge base sizes:"
puts "Prompt length: #{prompt_length} characters"
puts

[0, 5, 10, 25, 50, 100].each do |pages|
  usage = client.llm_usage.calculate(
    prompt_length: prompt_length,
    number_of_pages: pages,
    rag_enabled: rag_enabled
  )
  
  puts "#{pages} pages:"
  usage["llm_prices"].each do |model|
    puts "  #{model['llm']}: $#{model['price_per_minute']}/minute"
  end
  puts
end
```

### Budget Planning

```ruby
# Calculate monthly costs for different usage scenarios
def calculate_monthly_cost(usage_minutes_per_day, model_cost_per_minute)
  daily_cost = usage_minutes_per_day * model_cost_per_minute
  monthly_cost = daily_cost * 30
  monthly_cost.round(2)
end

# Get pricing for your agent configuration
usage_info = client.llm_usage.calculate(
  prompt_length: 800,
  number_of_pages: 20,
  rag_enabled: true
)

puts "Monthly cost projections:"
puts

usage_info["llm_prices"].each do |model|
  cost_per_minute = model["price_per_minute"]
  
  puts "#{model['llm']}:"
  puts "  Cost per minute: $#{cost_per_minute}"
  
  # Different usage scenarios
  [10, 50, 100, 500].each do |daily_minutes|
    monthly_cost = calculate_monthly_cost(daily_minutes, cost_per_minute)
    puts "  #{daily_minutes} minutes/day: $#{monthly_cost}/month"
  end
  puts
end
```

### Integration with Agent Creation

```ruby
# Use cost calculation to inform agent configuration decisions
def create_cost_optimized_agent(agent_config)
  # Calculate expected costs before creating the agent
  usage_info = client.llm_usage.calculate(
    prompt_length: agent_config[:prompt].length,
    number_of_pages: agent_config[:knowledge_base_pages] || 0,
    rag_enabled: agent_config[:rag_enabled] || false
  )
  
  puts "Expected LLM costs for this agent:"
  usage_info["llm_prices"].each do |model|
    puts "#{model['llm']}: $#{model['price_per_minute']}/minute"
  end
  
  # Choose the most cost-effective model
  cheapest_model = usage_info["llm_prices"].min_by { |model| model["price_per_minute"] }
  puts "Recommended model: #{cheapest_model['llm']} (${cheapest_model['price_per_minute']}/minute)"
  
  # Create agent with the recommended model
  agent_config[:conversation_config] ||= {}
  agent_config[:conversation_config][:agent] ||= {}
  agent_config[:conversation_config][:agent][:prompt] ||= {}
  agent_config[:conversation_config][:agent][:prompt][:llm] = cheapest_model["llm"]
  
  # Now create the agent
  agent = client.agents.create(agent_config)
  
  {
    agent: agent,
    expected_cost_per_minute: cheapest_model["price_per_minute"],
    all_pricing_options: usage_info["llm_prices"]
  }
end

# Example usage
agent_config = {
  name: "Customer Support Agent",
  prompt: "You are a helpful customer support agent for an e-commerce company. " \
          "Help customers with their orders, returns, and general questions. " \
          "Be friendly, professional, and always try to resolve their issues.",
  knowledge_base_pages: 15,
  rag_enabled: true,
  conversation_config: {
    agent: {
      first_message: "Hello! How can I help you today?"
    }
  }
}

result = create_cost_optimized_agent(agent_config)
puts "Agent created with ID: #{result[:agent]['agent_id']}"
puts "Expected cost: $#{result[:expected_cost_per_minute]} per minute"
```

### Advanced Usage Analysis

```ruby
# Comprehensive cost analysis for business planning
class LLMCostAnalyzer
  def initialize(client)
    @client = client
  end
  
  def analyze_agent_costs(agents_config)
    total_analysis = {
      agents: [],
      summary: {
        total_models: 0,
        cost_range: { min: Float::INFINITY, max: 0 },
        recommended_models: {}
      }
    }
    
    agents_config.each do |agent_config|
      usage = @client.llm_usage.calculate(
        prompt_length: agent_config[:prompt_length],
        number_of_pages: agent_config[:number_of_pages],
        rag_enabled: agent_config[:rag_enabled]
      )
      
      agent_analysis = {
        name: agent_config[:name],
        configuration: agent_config,
        pricing: usage["llm_prices"],
        recommendations: analyze_pricing(usage["llm_prices"])
      }
      
      total_analysis[:agents] << agent_analysis
      
      # Update summary
      usage["llm_prices"].each do |model|
        cost = model["price_per_minute"]
        total_analysis[:summary][:cost_range][:min] = [total_analysis[:summary][:cost_range][:min], cost].min
        total_analysis[:summary][:cost_range][:max] = [total_analysis[:summary][:cost_range][:max], cost].max
        
        total_analysis[:summary][:recommended_models][model["llm"]] ||= { count: 0, avg_cost: 0 }
        total_analysis[:summary][:recommended_models][model["llm"]][:count] += 1
        total_analysis[:summary][:recommended_models][model["llm"]][:avg_cost] += cost
      end
    end
    
    # Calculate averages
    total_analysis[:summary][:recommended_models].each do |model, data|
      data[:avg_cost] = (data[:avg_cost] / data[:count]).round(4)
    end
    
    total_analysis
  end
  
  private
  
  def analyze_pricing(pricing_data)
    cheapest = pricing_data.min_by { |model| model["price_per_minute"] }
    most_expensive = pricing_data.max_by { |model| model["price_per_minute"] }
    
    {
      cheapest: cheapest,
      most_expensive: most_expensive,
      cost_difference: most_expensive["price_per_minute"] - cheapest["price_per_minute"],
      models_count: pricing_data.length
    }
  end
end

# Example usage
analyzer = LLMCostAnalyzer.new(client)

agents_config = [
  {
    name: "Basic FAQ Bot",
    prompt_length: 300,
    number_of_pages: 5,
    rag_enabled: false
  },
  {
    name: "Knowledge Base Assistant",
    prompt_length: 800,
    number_of_pages: 25,
    rag_enabled: true
  },
  {
    name: "Complex Support Agent",
    prompt_length: 1500,
    number_of_pages: 100,
    rag_enabled: true
  }
]

analysis = analyzer.analyze_agent_costs(agents_config)

puts "=== LLM Cost Analysis Report ==="
puts
puts "Cost Range: $#{analysis[:summary][:cost_range][:min]} - $#{analysis[:summary][:cost_range][:max]} per minute"
puts
puts "Model Recommendations:"
analysis[:summary][:recommended_models].each do |model, data|
  puts "#{model}: Average $#{data[:avg_cost]}/minute (appears in #{data[:count]} configurations)"
end
puts

analysis[:agents].each do |agent|
  puts "--- #{agent[:name]} ---"
  puts "Configuration: #{agent[:configuration][:prompt_length]} chars, #{agent[:configuration][:number_of_pages]} pages, RAG: #{agent[:configuration][:rag_enabled]}"
  puts "Cheapest option: #{agent[:recommendations][:cheapest]['llm']} - $#{agent[:recommendations][:cheapest]['price_per_minute']}/minute"
  puts "Most expensive: #{agent[:recommendations][:most_expensive]['llm']} - $#{agent[:recommendations][:most_expensive]['price_per_minute']}/minute"
  puts "Cost difference: $#{agent[:recommendations][:cost_difference]}/minute"
  puts
end
```

## Parameters

### Required Parameters

- **`prompt_length`** (Integer): Length of the agent's prompt in characters
- **`number_of_pages`** (Integer): Number of pages of content in PDF documents or URLs in the agent's knowledge base
- **`rag_enabled`** (Boolean): Whether Retrieval-Augmented Generation (RAG) is enabled for the agent

### Response Format

```ruby
{
  "llm_prices" => [
    {
      "llm" => "gpt-4o-mini",           # LLM model name
      "price_per_minute" => 0.0045      # Cost per minute of conversation
    },
    {
      "llm" => "gpt-4o",
      "price_per_minute" => 0.0180
    }
    # ... more models
  ]
}
```

## Cost Factors

### Prompt Length Impact
- Longer prompts increase token usage and costs
- Character count directly affects LLM processing requirements
- Consider optimizing prompts for clarity and conciseness

### Knowledge Base Size
- More pages in the knowledge base increase RAG processing costs
- PDF documents and URL content are counted by page
- Balance knowledge completeness with cost efficiency

### RAG Configuration
- Enabling RAG adds overhead for knowledge retrieval
- Significantly impacts costs when knowledge base is large
- Consider whether RAG is necessary for your use case

## Best Practices

### Cost Optimization
1. **Optimize prompt length**: Write concise, clear prompts
2. **Curate knowledge base**: Include only necessary documents
3. **Choose appropriate models**: Balance cost with capability requirements
4. **Monitor usage**: Regular cost analysis for budget planning

### Budget Planning
1. **Calculate expected volumes**: Estimate daily/monthly conversation minutes
2. **Factor in growth**: Plan for increased usage over time
3. **Set up monitoring**: Track actual vs. expected costs
4. **Regular reviews**: Analyze and optimize configurations quarterly

## Error Handling

```ruby
begin
  usage_info = client.llm_usage.calculate(
    prompt_length: 1000,
    number_of_pages: 50,
    rag_enabled: true
  )
  
  puts "Calculation successful!"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid parameters: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Notes

- **Pricing Accuracy**: Prices are estimates based on current LLM model costs and may vary
- **Model Availability**: Available models may change; check response for current options
- **Real-time Pricing**: Actual costs may differ from estimates based on real usage patterns
- **Regional Variations**: Pricing may vary by geographic region
- **Volume Discounts**: High-volume usage may qualify for different pricing tiers
