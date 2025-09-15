# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class ServiceAccounts
      def initialize(client)
        @client = client
      end

      # GET /v1/service-accounts
      # Get service accounts
      # Documentation: https://elevenlabs.io/docs/api-reference/service-accounts/get-service-accounts
      #
      # @return [Hash] The JSON response containing all service accounts in the workspace.
      def get_service_accounts
        endpoint = "/v1/service-accounts"
        @client.get(endpoint)
      end

      alias_method :list, :get_service_accounts
      alias_method :all, :get_service_accounts
      alias_method :service_accounts, :get_service_accounts

      private

      attr_reader :client
    end
  end
end
