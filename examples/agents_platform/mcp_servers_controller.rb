# frozen_string_literal: true

class AgentsPlatform::McpServersController < ApplicationController
  # GET /agents_platform/mcp_servers
  # List all MCP servers in the workspace
  def index
    client = ElevenlabsClient.new
    
    servers = client.mcp_servers.list
    render json: servers
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/mcp_servers/:id
  # Get detailed information about a specific MCP server
  def show
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.get(params[:id])
    render json: server
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/mcp_servers
  # Create a new MCP server configuration
  def create
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.create(
      config: mcp_server_config_params
    )
    
    render json: server, status: :created
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # PATCH /agents_platform/mcp_servers/:id/approval_policy
  # Update the approval policy for an MCP server
  def update_approval_policy
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.update_approval_policy(
      params[:id],
      approval_policy: params[:approval_policy]
    )
    
    render json: server
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/mcp_servers/:id/tool_approvals
  # Approve a specific tool for the MCP server
  def create_tool_approval
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.create_tool_approval(
      params[:id],
      tool_name: params[:tool_name],
      tool_description: params[:tool_description],
      input_schema: params[:input_schema],
      approval_policy: params[:tool_approval_policy]
    )
    
    render json: server
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # DELETE /agents_platform/mcp_servers/:id/tool_approvals/:tool_name
  # Remove approval for a specific tool
  def delete_tool_approval
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.delete_tool_approval(params[:id], params[:tool_name])
    render json: server
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/mcp_servers/setup_enterprise
  # Set up a comprehensive enterprise MCP server with multiple tools
  def setup_enterprise
    client = ElevenlabsClient.new
    
    # Create authentication secret if provided
    secret = nil
    if params[:api_key]
      secret = client.workspace.create_secret(
        name: "#{params[:server_name]}_api_key",
        value: params[:api_key]
      )
    end
    
    # Build server configuration
    server_config = {
      url: params[:server_url],
      name: params[:server_name],
      approval_policy: params[:approval_policy] || "require_approval_per_tool",
      transport: "SSE",
      description: params[:description] || "Enterprise MCP server"
    }
    
    # Add authentication if secret was created
    if secret
      server_config[:secret_token] = { secret_id: secret["secret_id"] }
    end
    
    # Add custom headers if provided
    if params[:request_headers]
      server_config[:request_headers] = params[:request_headers]
    end
    
    # Create the server
    server = client.mcp_servers.create(config: server_config)
    
    # Add tool approvals if provided
    approved_tools = []
    if params[:tools]
      params[:tools].each do |tool|
        begin
          client.mcp_servers.create_tool_approval(
            server["id"],
            tool_name: tool[:name],
            tool_description: tool[:description],
            input_schema: tool[:schema],
            approval_policy: tool[:approval_policy] || "requires_approval"
          )
          approved_tools << tool[:name]
        rescue => e
          # Log tool approval failure but continue
          Rails.logger.warn "Failed to approve tool #{tool[:name]}: #{e.message}"
        end
      end
    end
    
    render json: {
      server: server,
      secret_created: !secret.nil?,
      tools_approved: approved_tools,
      setup_summary: {
        server_id: server["id"],
        server_name: server["config"]["name"],
        total_tools_approved: approved_tools.length,
        approval_policy: server["config"]["approval_policy"]
      }
    }, status: :created
  rescue ElevenlabsClient::UnprocessableEntityError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/mcp_servers/analytics
  # Get analytics and summary information about all MCP servers
  def analytics
    client = ElevenlabsClient.new
    
    servers = client.mcp_servers.list
    
    analytics = {
      total_servers: servers["mcp_servers"].length,
      by_approval_policy: Hash.new(0),
      by_transport: Hash.new(0),
      total_approved_tools: 0,
      total_dependent_agents: 0,
      servers_with_authentication: 0,
      servers_with_custom_headers: 0,
      server_details: []
    }
    
    servers["mcp_servers"].each do |server|
      config = server["config"]
      
      # Count by approval policy
      analytics[:by_approval_policy][config["approval_policy"]] += 1
      
      # Count by transport
      analytics[:by_transport][config["transport"]] += 1
      
      # Count approved tools
      if config["tool_approval_hashes"]
        analytics[:total_approved_tools] += config["tool_approval_hashes"].length
      end
      
      # Count dependent agents
      analytics[:total_dependent_agents] += server["dependent_agents"].length
      
      # Check for authentication
      analytics[:servers_with_authentication] += 1 if config["secret_token"]
      
      # Check for custom headers
      analytics[:servers_with_custom_headers] += 1 if config["request_headers"] && !config["request_headers"].empty?
      
      # Detailed server info
      analytics[:server_details] << {
        id: server["id"],
        name: config["name"],
        url: config["url"],
        approval_policy: config["approval_policy"],
        transport: config["transport"],
        approved_tools_count: config["tool_approval_hashes"]&.length || 0,
        dependent_agents_count: server["dependent_agents"].length,
        has_authentication: !config["secret_token"].nil?,
        has_custom_headers: config["request_headers"] && !config["request_headers"].empty?,
        creator: server["access_info"]["creator_name"],
        created_at: server["metadata"]["created_at"]
      }
    end
    
    render json: analytics
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # PATCH /agents_platform/mcp_servers/bulk_update_policy
  # Update approval policy for multiple servers
  def bulk_update_policy
    client = ElevenlabsClient.new
    
    server_ids = params[:server_ids] || []
    new_policy = params[:approval_policy]
    
    if server_ids.empty?
      return render json: { error: "No server IDs provided" }, status: :bad_request
    end
    
    unless %w[auto_approve_all require_approval_all require_approval_per_tool].include?(new_policy)
      return render json: { error: "Invalid approval policy" }, status: :bad_request
    end
    
    results = []
    
    server_ids.each do |server_id|
      begin
        updated_server = client.mcp_servers.update_approval_policy(
          server_id,
          approval_policy: new_policy
        )
        results << {
          server_id: server_id,
          success: true,
          server_name: updated_server["config"]["name"]
        }
      rescue => e
        results << {
          server_id: server_id,
          success: false,
          error: e.message
        }
      end
    end
    
    successful_updates = results.count { |r| r[:success] }
    failed_updates = results.count { |r| !r[:success] }
    
    render json: {
      results: results,
      summary: {
        total_attempted: server_ids.length,
        successful: successful_updates,
        failed: failed_updates,
        new_policy: new_policy
      }
    }
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /agents_platform/mcp_servers/:id/bulk_tool_approval
  # Approve multiple tools at once
  def bulk_tool_approval
    client = ElevenlabsClient.new
    
    tools = params[:tools] || []
    
    if tools.empty?
      return render json: { error: "No tools provided" }, status: :bad_request
    end
    
    results = []
    
    tools.each do |tool|
      begin
        client.mcp_servers.create_tool_approval(
          params[:id],
          tool_name: tool[:name],
          tool_description: tool[:description],
          input_schema: tool[:schema],
          approval_policy: tool[:approval_policy] || "requires_approval"
        )
        results << {
          tool_name: tool[:name],
          success: true
        }
      rescue => e
        results << {
          tool_name: tool[:name],
          success: false,
          error: e.message
        }
      end
    end
    
    # Get updated server info
    updated_server = client.mcp_servers.get(params[:id])
    
    successful_approvals = results.count { |r| r[:success] }
    failed_approvals = results.count { |r| !r[:success] }
    
    render json: {
      server: updated_server,
      results: results,
      summary: {
        total_attempted: tools.length,
        successful: successful_approvals,
        failed: failed_approvals
      }
    }
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # GET /agents_platform/mcp_servers/:id/security_audit
  # Perform a security audit on an MCP server configuration
  def security_audit
    client = ElevenlabsClient.new
    
    server = client.mcp_servers.get(params[:id])
    config = server["config"]
    
    audit_results = {
      server_id: server["id"],
      server_name: config["name"],
      security_score: 0,
      max_score: 100,
      findings: [],
      recommendations: []
    }
    
    # Check authentication (25 points)
    if config["secret_token"]
      audit_results[:security_score] += 25
      audit_results[:findings] << {
        category: "authentication",
        status: "good",
        message: "Server uses secret token authentication"
      }
    else
      audit_results[:findings] << {
        category: "authentication",
        status: "warning",
        message: "Server does not use authentication"
      }
      audit_results[:recommendations] << "Consider adding secret token authentication for secure access"
    end
    
    # Check approval policy (30 points)
    case config["approval_policy"]
    when "require_approval_all"
      audit_results[:security_score] += 30
      audit_results[:findings] << {
        category: "approval_policy",
        status: "excellent",
        message: "Most secure policy: requires approval for all tools"
      }
    when "require_approval_per_tool"
      audit_results[:security_score] += 20
      audit_results[:findings] << {
        category: "approval_policy",
        status: "good",
        message: "Secure policy: requires approval per tool"
      }
    when "auto_approve_all"
      audit_results[:findings] << {
        category: "approval_policy",
        status: "risk",
        message: "Least secure policy: auto-approves all tools"
      }
      audit_results[:recommendations] << "Consider using 'require_approval_per_tool' or 'require_approval_all' for better security"
    end
    
    # Check tool approvals (25 points)
    approved_tools = config["tool_approval_hashes"] || []
    auto_approved_tools = approved_tools.select { |t| t["approval_policy"] == "auto_approved" }
    
    if approved_tools.any?
      if auto_approved_tools.length == 0
        audit_results[:security_score] += 25
        audit_results[:findings] << {
          category: "tool_approvals",
          status: "excellent",
          message: "All approved tools require manual approval"
        }
      elsif auto_approved_tools.length < approved_tools.length / 2
        audit_results[:security_score] += 15
        audit_results[:findings] << {
          category: "tool_approvals",
          status: "good",
          message: "Most tools require manual approval"
        }
      else
        audit_results[:security_score] += 5
        audit_results[:findings] << {
          category: "tool_approvals",
          status: "warning",
          message: "Many tools are auto-approved"
        }
        audit_results[:recommendations] << "Review auto-approved tools and consider requiring manual approval for sensitive operations"
      end
    else
      audit_results[:findings] << {
        category: "tool_approvals",
        status: "info",
        message: "No tools approved yet"
      }
    end
    
    # Check URL security (20 points)
    server_url = config["url"]
    if server_url&.start_with?("https://")
      audit_results[:security_score] += 20
      audit_results[:findings] << {
        category: "url_security",
        status: "good",
        message: "Server uses HTTPS"
      }
    elsif server_url&.start_with?("http://")
      audit_results[:findings] << {
        category: "url_security",
        status: "risk",
        message: "Server uses unencrypted HTTP"
      }
      audit_results[:recommendations] << "Use HTTPS for secure communication"
    end
    
    # Additional security recommendations
    if server["dependent_agents"].length > 0
      audit_results[:recommendations] << "Regularly review agents using this MCP server"
    end
    
    if config["request_headers"] && config["request_headers"].any?
      audit_results[:findings] << {
        category: "custom_headers",
        status: "info",
        message: "Server uses custom request headers"
      }
    end
    
    # Calculate security level
    score_percentage = (audit_results[:security_score].to_f / audit_results[:max_score] * 100).round(1)
    audit_results[:security_level] = case score_percentage
                                     when 80..100 then "excellent"
                                     when 60..79 then "good"
                                     when 40..59 then "moderate"
                                     when 20..39 then "poor"
                                     else "critical"
                                     end
    
    audit_results[:score_percentage] = score_percentage
    
    render json: audit_results
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def mcp_server_config_params
    config = params.require(:config).permit(:url, :name, :approval_policy, :transport, :description, request_headers: {})
    
    # Handle secret_token if provided
    if params[:config][:secret_token]
      config[:secret_token] = params[:config][:secret_token].permit(:secret_id)
    end
    
    config.to_h
  end

  def tool_approval_params
    params.permit(:tool_name, :tool_description, :approval_policy, input_schema: {})
  end
end

# Usage Examples:
#
# 1. List all MCP servers:
# GET /agents_platform/mcp_servers
#
# 2. Get server details:
# GET /agents_platform/mcp_servers/server_123
#
# 3. Create basic MCP server:
# POST /agents_platform/mcp_servers
# {
#   "config": {
#     "url": "https://my-mcp-server.com/api",
#     "name": "Custom Tools Server",
#     "approval_policy": "auto_approve_all",
#     "description": "Provides custom business tools"
#   }
# }
#
# 4. Create secure MCP server:
# POST /agents_platform/mcp_servers
# {
#   "config": {
#     "url": "https://secure-api.com/mcp",
#     "name": "Secure API",
#     "approval_policy": "require_approval_per_tool",
#     "secret_token": {
#       "secret_id": "secret_123"
#     },
#     "request_headers": {
#       "Authorization": "Bearer token",
#       "Content-Type": "application/json"
#     }
#   }
# }
#
# 5. Update approval policy:
# PATCH /agents_platform/mcp_servers/server_123/approval_policy
# {
#   "approval_policy": "require_approval_all"
# }
#
# 6. Approve a tool:
# POST /agents_platform/mcp_servers/server_123/tool_approvals
# {
#   "tool_name": "get_customer_data",
#   "tool_description": "Retrieves customer information",
#   "input_schema": {
#     "type": "object",
#     "properties": {
#       "customer_id": {"type": "string"}
#     }
#   },
#   "tool_approval_policy": "auto_approved"
# }
#
# 7. Enterprise setup:
# POST /agents_platform/mcp_servers/setup_enterprise
# {
#   "server_url": "https://enterprise-api.com/mcp",
#   "server_name": "Enterprise API",
#   "api_key": "secret-api-key",
#   "description": "Enterprise business tools",
#   "approval_policy": "require_approval_per_tool",
#   "tools": [
#     {
#       "name": "search_customers",
#       "description": "Search customer database",
#       "approval_policy": "auto_approved"
#     }
#   ]
# }
#
# 8. Get analytics:
# GET /agents_platform/mcp_servers/analytics
#
# 9. Bulk update policies:
# PATCH /agents_platform/mcp_servers/bulk_update_policy
# {
#   "server_ids": ["server_123", "server_456"],
#   "approval_policy": "require_approval_all"
# }
#
# 10. Security audit:
# GET /agents_platform/mcp_servers/server_123/security_audit
#
# Error Responses:
# - 422 Unprocessable Entity: Invalid configuration or parameters
# - 404 Not Found: Server or tool not found
# - 400 Bad Request: Other API errors
#
# Security Features:
# - Authentication via secret tokens
# - Granular approval policies
# - Tool-level permission control
# - Security auditing capabilities
# - Bulk management operations
