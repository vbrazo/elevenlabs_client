# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Secrets
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/secrets
        # List all secrets from ElevenLabs
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/secrets/list
        #
        # @return [Hash] List of secrets with their metadata
        def list
          endpoint = "/v1/convai/secrets"
          @client.get(endpoint)
        end

        # POST /v1/convai/secrets
        # Create a new secret in ElevenLabs
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/secrets/create
        #
        # @param name [String] Name of the secret
        # @param value [String] Value of the secret
        # @param type [String] Type of secret (default: "new")
        # @return [Hash] Created secret with ID and metadata
        def create(name:, value:, type: "new")
          endpoint = "/v1/convai/secrets"
          request_body = {
            type: type,
            name: name,
            value: value
          }
          @client.post(endpoint, request_body)
        end

        # DELETE /v1/convai/secrets/{secret_id}
        # Delete a secret from ElevenLabs
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/secrets/delete
        #
        # @param secret_id [String] ID of the secret to delete
        # @return [Hash] Empty response on success
        def delete(secret_id)
          endpoint = "/v1/convai/secrets/#{secret_id}"
          @client.delete(endpoint)
        end
      end
    end
  end
end
