# frozen_string_literal: true

class AgentsPlatform::LlmUsageController < ApplicationController
  # POST /agents_platform/llm_usage/calculate
  # Calculate expected LLM usage and costs
  def calculate
    client = ElevenlabsClient.new
    
    usage_info = client.llm_usage.calculate(
      prompt_length: params[:prompt_length],
      number_of_pages: params[:number_of_pages],
      rag_enabled: params[:rag_enabled]
    )
    
    render json: usage_info
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/llm_usage/estimate_agent_cost
  # Estimate costs for an agent configuration
  def estimate_agent_cost
    client = ElevenlabsClient.new
    
    # Calculate prompt length from agent configuration
    prompt_text = params[:agent_prompt] || ""
    knowledge_base_pages = params[:knowledge_base_pages] || 0
    rag_enabled = params[:rag_enabled] || false
    
    usage_info = client.llm_usage.calculate(
      prompt_length: prompt_text.length,
      number_of_pages: knowledge_base_pages.to_i,
      rag_enabled: rag_enabled
    )
    
    # Add cost analysis
    cheapest_model = usage_info["llm_prices"].min_by { |model| model["price_per_minute"] }
    most_expensive = usage_info["llm_prices"].max_by { |model| model["price_per_minute"] }
    
    analysis = {
      configuration: {
        prompt_length: prompt_text.length,
        knowledge_base_pages: knowledge_base_pages,
        rag_enabled: rag_enabled
      },
      pricing: usage_info["llm_prices"],
      recommendations: {
        cheapest: cheapest_model,
        most_expensive: most_expensive,
        cost_difference: most_expensive["price_per_minute"] - cheapest_model["price_per_minute"]
      }
    }
    
    render json: analysis
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/llm_usage/compare_configurations
  # Compare costs for different agent configurations
  def compare_configurations
    client = ElevenlabsClient.new
    
    configurations = params[:configurations] || []
    
    if configurations.empty?
      return render json: { error: "No configurations provided" }, status: :bad_request
    end
    
    comparisons = []
    
    configurations.each_with_index do |config, index|
      begin
        usage_info = client.llm_usage.calculate(
          prompt_length: config[:prompt_length].to_i,
          number_of_pages: config[:number_of_pages].to_i,
          rag_enabled: config[:rag_enabled] || false
        )
        
        cheapest = usage_info["llm_prices"].min_by { |model| model["price_per_minute"] }
        
        comparisons << {
          configuration_index: index,
          name: config[:name] || "Configuration #{index + 1}",
          configuration: {
            prompt_length: config[:prompt_length],
            number_of_pages: config[:number_of_pages],
            rag_enabled: config[:rag_enabled]
          },
          pricing: usage_info["llm_prices"],
          cheapest_option: cheapest
        }
      rescue => e
        comparisons << {
          configuration_index: index,
          name: config[:name] || "Configuration #{index + 1}",
          error: e.message
        }
      end
    end
    
    # Overall analysis
    successful_comparisons = comparisons.select { |c| !c[:error] }
    
    if successful_comparisons.any?
      all_cheapest = successful_comparisons.map { |c| c[:cheapest_option]["price_per_minute"] }
      overall_analysis = {
        most_cost_effective: successful_comparisons.min_by { |c| c[:cheapest_option]["price_per_minute"] },
        least_cost_effective: successful_comparisons.max_by { |c| c[:cheapest_option]["price_per_minute"] },
        cost_range: {
          min: all_cheapest.min,
          max: all_cheapest.max
        }
      }
    else
      overall_analysis = { error: "No successful configurations to analyze" }
    end
    
    render json: {
      comparisons: comparisons,
      analysis: overall_analysis
    }
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/llm_usage/monthly_projection
  # Calculate monthly cost projections for different usage scenarios
  def monthly_projection
    client = ElevenlabsClient.new
    
    usage_info = client.llm_usage.calculate(
      prompt_length: params[:prompt_length].to_i,
      number_of_pages: params[:number_of_pages].to_i,
      rag_enabled: params[:rag_enabled] || false
    )
    
    # Usage scenarios (minutes per day)
    usage_scenarios = params[:usage_scenarios] || [10, 30, 60, 120, 300]
    
    projections = []
    
    usage_info["llm_prices"].each do |model|
      cost_per_minute = model["price_per_minute"]
      
      model_projections = {
        model: model["llm"],
        cost_per_minute: cost_per_minute,
        monthly_costs: {}
      }
      
      usage_scenarios.each do |daily_minutes|
        daily_cost = daily_minutes * cost_per_minute
        monthly_cost = daily_cost * 30
        
        model_projections[:monthly_costs][daily_minutes] = {
          daily_minutes: daily_minutes,
          daily_cost: daily_cost.round(4),
          monthly_cost: monthly_cost.round(2)
        }
      end
      
      projections << model_projections
    end
    
    render json: {
      configuration: {
        prompt_length: params[:prompt_length],
        number_of_pages: params[:number_of_pages],
        rag_enabled: params[:rag_enabled]
      },
      projections: projections,
      usage_scenarios: usage_scenarios
    }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/llm_usage/optimization_suggestions
  # Get suggestions for optimizing LLM costs
  def optimization_suggestions
    client = ElevenlabsClient.new
    
    current_config = {
      prompt_length: params[:prompt_length].to_i,
      number_of_pages: params[:number_of_pages].to_i,
      rag_enabled: params[:rag_enabled] || false
    }
    
    # Get current costs
    current_usage = client.llm_usage.calculate(**current_config)
    current_cheapest = current_usage["llm_prices"].min_by { |m| m["price_per_minute"] }
    
    suggestions = []
    optimized_costs = []
    
    # Suggestion 1: Optimize prompt length
    if current_config[:prompt_length] > 500
      optimized_prompt_length = [current_config[:prompt_length] * 0.7, 300].max.to_i
      
      optimized_usage = client.llm_usage.calculate(
        prompt_length: optimized_prompt_length,
        number_of_pages: current_config[:number_of_pages],
        rag_enabled: current_config[:rag_enabled]
      )
      
      optimized_cheapest = optimized_usage["llm_prices"].min_by { |m| m["price_per_minute"] }
      savings = current_cheapest["price_per_minute"] - optimized_cheapest["price_per_minute"]
      
      if savings > 0
        suggestions << {
          type: "prompt_optimization",
          description: "Reduce prompt length by 30%",
          current_length: current_config[:prompt_length],
          suggested_length: optimized_prompt_length,
          potential_savings_per_minute: savings.round(6),
          percentage_savings: ((savings / current_cheapest["price_per_minute"]) * 100).round(2)
        }
        
        optimized_costs << optimized_usage
      end
    end
    
    # Suggestion 2: Optimize knowledge base size
    if current_config[:number_of_pages] > 20
      optimized_pages = [current_config[:number_of_pages] * 0.6, 10].max.to_i
      
      optimized_usage = client.llm_usage.calculate(
        prompt_length: current_config[:prompt_length],
        number_of_pages: optimized_pages,
        rag_enabled: current_config[:rag_enabled]
      )
      
      optimized_cheapest = optimized_usage["llm_prices"].min_by { |m| m["price_per_minute"] }
      savings = current_cheapest["price_per_minute"] - optimized_cheapest["price_per_minute"]
      
      if savings > 0
        suggestions << {
          type: "knowledge_base_optimization",
          description: "Reduce knowledge base size by 40%",
          current_pages: current_config[:number_of_pages],
          suggested_pages: optimized_pages,
          potential_savings_per_minute: savings.round(6),
          percentage_savings: ((savings / current_cheapest["price_per_minute"]) * 100).round(2)
        }
        
        optimized_costs << optimized_usage
      end
    end
    
    # Suggestion 3: Consider disabling RAG if knowledge base is small
    if current_config[:rag_enabled] && current_config[:number_of_pages] < 5
      optimized_usage = client.llm_usage.calculate(
        prompt_length: current_config[:prompt_length],
        number_of_pages: current_config[:number_of_pages],
        rag_enabled: false
      )
      
      optimized_cheapest = optimized_usage["llm_prices"].min_by { |m| m["price_per_minute"] }
      savings = current_cheapest["price_per_minute"] - optimized_cheapest["price_per_minute"]
      
      if savings > 0
        suggestions << {
          type: "rag_optimization",
          description: "Disable RAG for small knowledge base",
          current_rag: current_config[:rag_enabled],
          suggested_rag: false,
          reason: "Knowledge base is small (#{current_config[:number_of_pages]} pages), RAG overhead may not be justified",
          potential_savings_per_minute: savings.round(6),
          percentage_savings: ((savings / current_cheapest["price_per_minute"]) * 100).round(2)
        }
        
        optimized_costs << optimized_usage
      end
    end
    
    render json: {
      current_configuration: current_config,
      current_cost_per_minute: current_cheapest["price_per_minute"],
      suggestions: suggestions,
      total_potential_savings: suggestions.sum { |s| s[:potential_savings_per_minute] }.round(6)
    }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def llm_usage_params
    params.permit(:prompt_length, :number_of_pages, :rag_enabled, :agent_prompt, :knowledge_base_pages,
                  usage_scenarios: [], configurations: [:name, :prompt_length, :number_of_pages, :rag_enabled])
  end
end

# Usage Examples:
#
# 1. Basic cost calculation:
# POST /agents_platform/llm_usage/calculate
# {
#   "prompt_length": 800,
#   "number_of_pages": 25,
#   "rag_enabled": true
# }
#
# 2. Estimate agent cost:
# POST /agents_platform/llm_usage/estimate_agent_cost
# {
#   "agent_prompt": "You are a helpful customer service agent...",
#   "knowledge_base_pages": 30,
#   "rag_enabled": true
# }
#
# 3. Compare configurations:
# POST /agents_platform/llm_usage/compare_configurations
# {
#   "configurations": [
#     {
#       "name": "Simple Agent",
#       "prompt_length": 300,
#       "number_of_pages": 0,
#       "rag_enabled": false
#     },
#     {
#       "name": "Knowledge Agent",
#       "prompt_length": 800,
#       "number_of_pages": 25,
#       "rag_enabled": true
#     }
#   ]
# }
#
# 4. Monthly projections:
# POST /agents_platform/llm_usage/monthly_projection
# {
#   "prompt_length": 1000,
#   "number_of_pages": 50,
#   "rag_enabled": true,
#   "usage_scenarios": [30, 60, 120, 300]
# }
#
# 5. Optimization suggestions:
# GET /agents_platform/llm_usage/optimization_suggestions
# {
#   "prompt_length": 1500,
#   "number_of_pages": 100,
#   "rag_enabled": true
# }
#
# Response formats:
# - Calculate: Returns LLM pricing list
# - Estimate: Returns configuration analysis with recommendations
# - Compare: Returns detailed comparison with overall analysis
# - Monthly: Returns cost projections for different usage levels
# - Optimization: Returns specific suggestions for cost reduction
#
# Error Responses:
# - 422 Unprocessable Entity: Invalid parameters
# - 400 Bad Request: Other API errors
