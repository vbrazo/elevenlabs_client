# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Workspace
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/settings
        # Retrieve Convai settings for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/get-settings
        #
        # @return [Hash] JSON response containing workspace settings
        def get_settings
          @client.get("/v1/convai/settings")
        end

        # PATCH /v1/convai/settings
        # Update Convai settings for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/update-settings
        #
        # @param options [Hash] Settings to update
        # @option options [Hash] :conversation_initiation_client_data_webhook Webhook configuration
        # @option options [Hash] :webhooks Webhook settings
        # @option options [Boolean] :can_use_mcp_servers Whether workspace can use MCP servers
        # @option options [Integer] :rag_retention_period_days RAG retention period (<=30)
        # @option options [String] :default_livekit_stack Default LiveKit stack ("standard" or "static")
        # @return [Hash] JSON response containing updated settings
        def update_settings(**options)
          body = options.compact
          @client.patch("/v1/convai/settings", body)
        end

        # GET /v1/convai/secrets
        # Get all workspace secrets for the user
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/get-secrets
        #
        # @return [Hash] JSON response containing list of secrets
        def get_secrets
          @client.get("/v1/convai/secrets")
        end

        # POST /v1/convai/secrets
        # Create a new secret for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/create-secret
        #
        # @param name [String] Name of the secret
        # @param value [String] Value of the secret
        # @param type [String] Type of secret (defaults to "new")
        # @return [Hash] JSON response containing created secret info
        def create_secret(name:, value:, type: "new")
          raise ArgumentError, "name is required" if name.nil? || name.to_s.strip.empty?
          raise ArgumentError, "value is required" if value.nil? || value.to_s.strip.empty?

          body = {
            type: type,
            name: name,
            value: value
          }

          @client.post("/v1/convai/secrets", body)
        end

        # PATCH /v1/convai/secrets/:secret_id
        # Update an existing secret for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/update-secret
        #
        # @param secret_id [String] ID of the secret to update
        # @param name [String] New name for the secret
        # @param value [String] New value for the secret
        # @param type [String] Type of operation (defaults to "update")
        # @return [Hash] JSON response containing updated secret info
        def update_secret(secret_id, name:, value:, type: "update")
          raise ArgumentError, "secret_id is required" if secret_id.nil? || secret_id.to_s.strip.empty?
          raise ArgumentError, "name is required" if name.nil? || name.to_s.strip.empty?
          raise ArgumentError, "value is required" if value.nil? || value.to_s.strip.empty?

          body = {
            type: type,
            name: name,
            value: value
          }

          @client.patch("/v1/convai/secrets/#{secret_id}", body)
        end

        # DELETE /v1/convai/secrets/:secret_id
        # Delete a workspace secret if it's not in use
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/delete-secret
        #
        # @param secret_id [String] ID of the secret to delete
        # @return [Hash] JSON response with deletion confirmation
        def delete_secret(secret_id)
          raise ArgumentError, "secret_id is required" if secret_id.nil? || secret_id.to_s.strip.empty?

          @client.delete("/v1/convai/secrets/#{secret_id}")
        end

        # GET /v1/convai/settings/dashboard
        # Retrieve Convai dashboard settings for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/get-dashboard-settings
        #
        # @return [Hash] JSON response containing dashboard settings
        def get_dashboard_settings
          @client.get("/v1/convai/settings/dashboard")
        end

        # PATCH /v1/convai/settings/dashboard
        # Update Convai dashboard settings for the workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/conversational-ai/workspace/update-dashboard-settings
        #
        # @param charts [Array] Array of chart configurations
        # @return [Hash] JSON response containing updated dashboard settings
        def update_dashboard_settings(charts: nil)
          body = {}
          body[:charts] = charts if charts

          @client.patch("/v1/convai/settings/dashboard", body)
        end

        # Convenience method aliases
        alias_method :settings, :get_settings
        alias_method :secrets, :get_secrets
        alias_method :dashboard_settings, :get_dashboard_settings
      end
    end
  end
end
