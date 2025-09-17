# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Tools
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/tools
        # Get all available tools in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/list
        #
        # @return [Hash] List of tools with their configurations and metadata
        def list
          endpoint = "/v1/convai/tools"
          @client.get(endpoint)
        end

        # GET /v1/convai/tools/{tool_id}
        # Get tool that is available in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/get
        #
        # @param tool_id [String] ID of the requested tool
        # @return [Hash] Tool configuration and metadata
        def get(tool_id)
          endpoint = "/v1/convai/tools/#{tool_id}"
          @client.get(endpoint)
        end

        # POST /v1/convai/tools
        # Add a new tool to the available tools in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/create
        #
        # @param tool_config [Hash] Configuration for the tool
        # @option tool_config [String] :name Required name of the tool
        # @option tool_config [String] :description Required description of the tool
        # @option tool_config [Hash] :api_schema Required API schema configuration
        # @option tool_config [Integer] :response_timeout_secs Optional response timeout (default: 20)
        # @option tool_config [Boolean] :disable_interruptions Optional disable interruptions (default: false)
        # @option tool_config [Boolean] :force_pre_tool_speech Optional force pre-tool speech (default: false)
        # @option tool_config [Array<Hash>] :assignments Optional variable assignments
        # @option tool_config [Hash] :dynamic_variables Optional dynamic variables
        # @return [Hash] Created tool with ID and configuration
        def create(tool_config:)
          endpoint = "/v1/convai/tools"
          request_body = { tool_config: tool_config }
          @client.post(endpoint, request_body)
        end

        # PATCH /v1/convai/tools/{tool_id}
        # Update tool that is available in the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/update
        #
        # @param tool_id [String] ID of the requested tool
        # @param tool_config [Hash] Updated configuration for the tool
        # @option tool_config [String] :name Optional updated name of the tool
        # @option tool_config [String] :description Optional updated description of the tool
        # @option tool_config [Hash] :api_schema Optional updated API schema configuration
        # @option tool_config [Integer] :response_timeout_secs Optional response timeout
        # @option tool_config [Boolean] :disable_interruptions Optional disable interruptions
        # @option tool_config [Boolean] :force_pre_tool_speech Optional force pre-tool speech
        # @option tool_config [Array<Hash>] :assignments Optional variable assignments
        # @option tool_config [Hash] :dynamic_variables Optional dynamic variables
        # @return [Hash] Updated tool configuration and metadata
        def update(tool_id, tool_config:)
          endpoint = "/v1/convai/tools/#{tool_id}"
          request_body = { tool_config: tool_config }
          @client.patch(endpoint, request_body)
        end

        # DELETE /v1/convai/tools/{tool_id}
        # Delete tool from the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/delete
        #
        # @param tool_id [String] ID of the requested tool
        # @return [Hash] Empty response on success
        def delete(tool_id)
          endpoint = "/v1/convai/tools/#{tool_id}"
          @client.delete(endpoint)
        end

        # GET /v1/convai/tools/{tool_id}/dependent-agents
        # Get a list of agents depending on this tool
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/tools/dependent-agents
        #
        # @param tool_id [String] ID of the requested tool
        # @param options [Hash] Query parameters
        # @option options [String] :cursor Used for fetching next page
        # @option options [Integer] :page_size How many agents to return at maximum (1-100, default: 30)
        # @return [Hash] List of dependent agents with pagination info
        def get_dependent_agents(tool_id, **options)
          endpoint = "/v1/convai/tools/#{tool_id}/dependent-agents"
          query_params = options.compact
          
          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end
          
          @client.get(endpoint)
        end
      end
    end
  end
end
