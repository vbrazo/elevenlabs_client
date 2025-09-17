# frozen_string_literal: true

class AgentsPlatform::WorkspaceController < ApplicationController
  # GET /agents_platform/workspace/settings
  # Retrieve current workspace settings
  def show_settings
    client = ElevenlabsClient.new
    
    settings = client.workspace.get_settings
    render json: settings
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # PATCH /agents_platform/workspace/settings
  # Update workspace settings
  def update_settings
    client = ElevenlabsClient.new
    
    settings = client.workspace.update_settings(
      can_use_mcp_servers: params[:can_use_mcp_servers],
      rag_retention_period_days: params[:rag_retention_period_days],
      default_livekit_stack: params[:default_livekit_stack],
      conversation_initiation_client_data_webhook: params[:conversation_initiation_client_data_webhook],
      webhooks: params[:webhooks]
    )
    
    render json: settings
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/workspace/secrets
  # List all workspace secrets
  def secrets
    client = ElevenlabsClient.new
    
    secrets = client.workspace.get_secrets
    render json: secrets
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/workspace/secrets
  # Create a new workspace secret
  def create_secret
    client = ElevenlabsClient.new
    
    secret = client.workspace.create_secret(
      name: params[:name],
      value: params[:value],
      type: params[:type] || "new"
    )
    
    render json: secret, status: :created
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # PATCH /agents_platform/workspace/secrets/:secret_id
  # Update an existing workspace secret
  def update_secret
    client = ElevenlabsClient.new
    
    secret = client.workspace.update_secret(
      params[:secret_id],
      name: params[:name],
      value: params[:value],
      type: params[:type] || "update"
    )
    
    render json: secret
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # DELETE /agents_platform/workspace/secrets/:secret_id
  # Delete a workspace secret
  def delete_secret
    client = ElevenlabsClient.new
    
    client.workspace.delete_secret(params[:secret_id])
    render json: { message: "Secret deleted successfully" }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: "Cannot delete secret: #{e.message}" }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/workspace/dashboard
  # Get dashboard settings
  def dashboard_settings
    client = ElevenlabsClient.new
    
    settings = client.workspace.get_dashboard_settings
    render json: settings
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # PATCH /agents_platform/workspace/dashboard
  # Update dashboard settings
  def update_dashboard
    client = ElevenlabsClient.new
    
    settings = client.workspace.update_dashboard_settings(
      charts: params[:charts]
    )
    
    render json: settings
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/workspace/configure_webhooks
  # Configure conversation and post-call webhooks
  def configure_webhooks
    client = ElevenlabsClient.new
    
    settings = client.workspace.update_settings(
      conversation_initiation_client_data_webhook: {
        url: params[:webhook_url],
        request_headers: params[:webhook_headers] || {}
      },
      webhooks: {
        post_call_webhook_id: params[:post_call_webhook_id],
        send_audio: params[:send_audio] || false
      }
    )
    
    render json: { 
      message: "Webhooks configured successfully",
      settings: settings
    }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/workspace/enable_features
  # Enable advanced workspace features
  def enable_features
    client = ElevenlabsClient.new
    
    settings = client.workspace.update_settings(
      can_use_mcp_servers: true,
      rag_retention_period_days: params[:rag_retention_days] || 30,
      default_livekit_stack: params[:livekit_stack] || "standard"
    )
    
    render json: {
      message: "Features enabled successfully",
      settings: settings
    }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/workspace/secret_usage/:secret_id
  # Analyze secret usage across workspace
  def analyze_secret_usage
    client = ElevenlabsClient.new
    
    secrets = client.workspace.get_secrets
    target_secret = secrets["secrets"].find { |s| s["secret_id"] == params[:secret_id] }
    
    if target_secret.nil?
      render json: { error: "Secret not found" }, status: :not_found
      return
    end
    
    usage = target_secret["used_by"]
    total_usage = usage["tools"].length + usage["agents"].length + 
                  usage["phone_numbers"].length + usage["others"].length
    
    render json: {
      secret_id: target_secret["secret_id"],
      name: target_secret["name"],
      type: target_secret["type"],
      usage_summary: {
        total_usage: total_usage,
        tools: usage["tools"].length,
        agents: usage["agents"].length,
        phone_numbers: usage["phone_numbers"].length,
        others: usage["others"].length,
        can_delete: total_usage == 0
      },
      detailed_usage: usage
    }
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/workspace/dashboard_presets
  # Set up predefined dashboard configurations
  def setup_dashboard_presets
    client = ElevenlabsClient.new
    
    preset_type = params[:preset] || "comprehensive"
    
    charts = case preset_type
    when "basic"
      [
        { name: "Call Success Rate", type: "call_success" },
        { name: "Daily Volume", type: "daily_volume" }
      ]
    when "analytics"
      [
        { name: "Call Success Rate", type: "call_success" },
        { name: "Conversation Duration", type: "conversation_duration" },
        { name: "Cost Analysis", type: "cost_analysis" }
      ]
    when "comprehensive"
      [
        { name: "Call Success Rate", type: "call_success" },
        { name: "Conversation Duration", type: "conversation_duration" },
        { name: "Daily Volume", type: "daily_volume" },
        { name: "Cost Analysis", type: "cost_analysis" }
      ]
    else
      return render json: { error: "Invalid preset type" }, status: :bad_request
    end
    
    settings = client.workspace.update_dashboard_settings(charts: charts)
    
    render json: {
      message: "Dashboard preset '#{preset_type}' applied successfully",
      charts_count: charts.length,
      settings: settings
    }
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def workspace_params
    params.permit(:can_use_mcp_servers, :rag_retention_period_days, :default_livekit_stack,
                  :name, :value, :type, :secret_id, :webhook_url, :post_call_webhook_id, 
                  :send_audio, :preset, :rag_retention_days, :livekit_stack,
                  conversation_initiation_client_data_webhook: [:url, :request_headers],
                  webhooks: [:post_call_webhook_id, :send_audio],
                  webhook_headers: {},
                  charts: [])
  end
end

# Usage Examples:
#
# 1. Get workspace settings:
# GET /agents_platform/workspace/settings
#
# 2. Update workspace settings:
# PATCH /agents_platform/workspace/settings
# {
#   "can_use_mcp_servers": true,
#   "rag_retention_period_days": 15,
#   "default_livekit_stack": "standard"
# }
#
# 3. List workspace secrets:
# GET /agents_platform/workspace/secrets
#
# 4. Create a secret:
# POST /agents_platform/workspace/secrets
# {
#   "name": "api_key",
#   "value": "sk-1234567890",
#   "type": "new"
# }
#
# 5. Update a secret:
# PATCH /agents_platform/workspace/secrets/secret_123
# {
#   "name": "updated_api_key",
#   "value": "sk-newvalue123",
#   "type": "update"
# }
#
# 6. Delete a secret:
# DELETE /agents_platform/workspace/secrets/secret_123
#
# 7. Get dashboard settings:
# GET /agents_platform/workspace/dashboard
#
# 8. Update dashboard:
# PATCH /agents_platform/workspace/dashboard
# {
#   "charts": [
#     {"name": "Success Rate", "type": "call_success"},
#     {"name": "Duration", "type": "conversation_duration"}
#   ]
# }
#
# 9. Configure webhooks:
# POST /agents_platform/workspace/configure_webhooks
# {
#   "webhook_url": "https://myapp.com/webhook",
#   "webhook_headers": {"Authorization": "Bearer token"},
#   "post_call_webhook_id": "webhook_123",
#   "send_audio": true
# }
#
# 10. Enable features:
# POST /agents_platform/workspace/enable_features
# {
#   "rag_retention_days": 30,
#   "livekit_stack": "standard"
# }
#
# 11. Analyze secret usage:
# GET /agents_platform/workspace/secret_usage/secret_123
#
# 12. Setup dashboard presets:
# POST /agents_platform/workspace/dashboard_presets
# {
#   "preset": "comprehensive"
# }
#
# Available preset types: "basic", "analytics", "comprehensive"
#
# Error Responses:
# - 422 Unprocessable Entity: Invalid parameters or validation errors
# - 404 Not Found: Secret or resource not found
# - 403 Forbidden: Insufficient permissions
# - 400 Bad Request: Other API errors
#
# Notes:
# - Only workspace administrators can modify settings and secrets
# - Secrets cannot be deleted if they're in use by tools, agents, or integrations
# - RAG retention period must be ≤ 30 days
# - Webhook URLs must be accessible and return appropriate responses
