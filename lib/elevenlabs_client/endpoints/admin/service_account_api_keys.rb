# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class ServiceAccountApiKeys
        def initialize(client)
          @client = client
        end

        # GET /v1/service-accounts/{service_account_user_id}/api-keys
        # Get all API keys for a service account
        # Documentation: https://elevenlabs.io/docs/api-reference/service-accounts/api-keys/list
        #
        # @param service_account_user_id [String] The service account user ID
        # @return [Hash] JSON response containing list of API keys
        def list(service_account_user_id)
          endpoint = "/v1/service-accounts/#{service_account_user_id}/api-keys"
          @client.get(endpoint)
        end

        # POST /v1/service-accounts/{service_account_user_id}/api-keys
        # Create a new API key for a service account
        # Documentation: https://elevenlabs.io/docs/api-reference/service-accounts/api-keys/create
        #
        # @param service_account_user_id [String] The service account user ID
        # @param name [String] The name of the API key
        # @param permissions [Array<String>, String] The permissions for the API key or "all"
        # @param options [Hash] Optional parameters
        # @option options [Integer, nil] :character_limit Monthly character limit for the API key
        # @return [Hash] JSON response containing the new API key
        def create(service_account_user_id, name:, permissions:, **options)
          endpoint = "/v1/service-accounts/#{service_account_user_id}/api-keys"
          request_body = {
            name: name,
            permissions: permissions
          }.merge(options)

          @client.post(endpoint, request_body)
        end

        # PATCH /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}
        # Update an existing API key for a service account
        # Documentation: https://elevenlabs.io/docs/api-reference/service-accounts/api-keys/update
        #
        # @param service_account_user_id [String] The service account user ID
        # @param api_key_id [String] The API key ID
        # @param is_enabled [Boolean] Whether to enable or disable the API key
        # @param name [String] The name of the API key
        # @param permissions [Array<String>, String] The permissions for the API key or "all"
        # @param options [Hash] Optional parameters
        # @option options [Integer, nil] :character_limit Monthly character limit for the API key
        # @return [Hash] JSON response with update confirmation
        def update(service_account_user_id, api_key_id, is_enabled:, name:, permissions:, **options)
          endpoint = "/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}"
          request_body = {
            is_enabled: is_enabled,
            name: name,
            permissions: permissions
          }.merge(options)

          @client.patch(endpoint, request_body)
        end

        # DELETE /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}
        # Delete an existing API key for a service account
        # Documentation: https://elevenlabs.io/docs/api-reference/service-accounts/api-keys/delete
        #
        # @param service_account_user_id [String] The service account user ID
        # @param api_key_id [String] The API key ID
        # @return [Hash] JSON response with deletion confirmation
        def delete(service_account_user_id, api_key_id)
          endpoint = "/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}"
          @client.delete(endpoint)
        end
    end
  end
end
