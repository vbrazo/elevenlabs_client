# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      # MCP Servers endpoint - refactored for better maintainability
      class McpServers
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/mcp-servers
        # Create a new MCP server configuration in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/create
        #
        # @param config [Hash] Configuration details for the MCP Server (required)
        # @option config [String] :url MCP server URL
        # @option config [String] :name MCP server name
        # @option config [String] :approval_policy Approval policy ("auto_approve_all", "require_approval_all", "require_approval_per_tool")
        # @option config [Array] :tool_approval_hashes Tool approval configurations
        # @option config [String] :transport Transport method (default: "SSE")
        # @option config [Hash] :secret_token Secret token configuration
        # @option config [Hash] :request_headers Request headers
        # @option config [String] :description MCP server description
        # @return [Hash] JSON response containing created MCP server details
        def create(config:)
          validate_required!(:config, config)
          raise ArgumentError, "config cannot be empty" if config.empty?

          body = { config: config }

          @client.post("/v1/convai/mcp-servers", body)
        end

        # GET /v1/convai/mcp-servers
        # Retrieve all MCP server configurations available in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/list
        #
        # @return [Hash] JSON response containing list of MCP servers
        def list
          @client.get("/v1/convai/mcp-servers")
        end

        # GET /v1/convai/mcp-servers/:mcp_server_id
        # Retrieve a specific MCP server configuration from the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/get
        #
        # @param mcp_server_id [String] ID of the MCP Server (required)
        # @return [Hash] JSON response containing MCP server details
        def get(mcp_server_id)
          validate_required!(:mcp_server_id, mcp_server_id)

          @client.get("/v1/convai/mcp-servers/#{mcp_server_id}")
        end

        # PATCH /v1/convai/mcp-servers/:mcp_server_id/approval-policy
        # Update the approval policy configuration for an MCP server
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/update-approval-policy
        #
        # @param mcp_server_id [String] ID of the MCP Server (required)
        # @param approval_policy [String] The approval mode to set for the MCP server (required)
        #   - "auto_approve_all": Automatically approve all tools
        #   - "require_approval_all": Require approval for all tools
        #   - "require_approval_per_tool": Require approval per individual tool
        # @return [Hash] JSON response containing updated MCP server details
        def update_approval_policy(mcp_server_id, approval_policy:)
          validate_required!(:mcp_server_id, mcp_server_id)
          validate_required!(:approval_policy, approval_policy)

          valid_policies = %w[auto_approve_all require_approval_all require_approval_per_tool]
          unless valid_policies.include?(approval_policy.to_s)
            raise ArgumentError, "approval_policy must be one of: #{valid_policies.join(', ')}"
          end

          body = { approval_policy: approval_policy }

          @client.patch("/v1/convai/mcp-servers/#{mcp_server_id}/approval-policy", body)
        end

        # POST /v1/convai/mcp-servers/:mcp_server_id/tool-approvals
        # Add approval for a specific MCP tool when using per-tool approval mode
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/create-tool-approval
        #
        # @param mcp_server_id [String] ID of the MCP Server (required)
        # @param tool_name [String] The name of the MCP tool (required)
        # @param tool_description [String] The description of the MCP tool (required)
        # @param options [Hash] Optional parameters
        # @option options [Hash] :input_schema The input schema of the MCP tool
        # @option options [String] :approval_policy Tool-level approval policy ("auto_approved", "requires_approval")
        # @return [Hash] JSON response containing updated MCP server details
        def create_tool_approval(mcp_server_id, tool_name:, tool_description:, **options)
          validate_required!(:mcp_server_id, mcp_server_id)
          validate_required!(:tool_name, tool_name)
          validate_required!(:tool_description, tool_description)

          body = {
            tool_name: tool_name,
            tool_description: tool_description
          }.merge(options.compact)

          @client.post("/v1/convai/mcp-servers/#{mcp_server_id}/tool-approvals", body)
        end

        # DELETE /v1/convai/mcp-servers/:mcp_server_id/tool-approvals/:tool_name
        # Remove approval for a specific MCP tool when using per-tool approval mode
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/mcp-servers/delete-tool-approval
        #
        # @param mcp_server_id [String] ID of the MCP Server (required)
        # @param tool_name [String] Name of the MCP tool to remove approval for (required)
        # @return [Hash] JSON response containing updated MCP server details
        def delete_tool_approval(mcp_server_id, tool_name)
          validate_required!(:mcp_server_id, mcp_server_id)
          validate_required!(:tool_name, tool_name)

          @client.delete("/v1/convai/mcp-servers/#{mcp_server_id}/tool-approvals/#{tool_name}")
        end

        # Convenience method aliases
        alias_method :servers, :list
        alias_method :get_server, :get
        alias_method :update_policy, :update_approval_policy
        alias_method :approve_tool, :create_tool_approval
        alias_method :remove_tool_approval, :delete_tool_approval

        private

        attr_reader :client

        # Parameter validation
        def validate_required!(param_name, value)
          if value.nil? || (value.respond_to?(:empty?) && value.empty?) || 
             (value.is_a?(String) && value.strip.empty?)
            raise ArgumentError, "#{param_name} is required"
          end
        end
      end
    end
  end
end
