# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class Webhooks
      def initialize(client)
        @client = client
      end

      # GET /v1/workspace/webhooks
      # List workspace webhooks
      # Documentation: https://elevenlabs.io/docs/api-reference/workspace/list-workspace-webhooks
      #
      # @param include_usages [Boolean] Whether to include active usages of the webhook, only usable by admins. Defaults to false.
      # @return [Hash] The JSON response containing all webhooks for the workspace.
      def list_webhooks(include_usages: nil)
        endpoint = "/v1/workspace/webhooks"
        params = {
          include_usages: include_usages
        }.compact
        @client.get(endpoint, params)
      end

      alias_method :get_webhooks, :list_webhooks
      alias_method :all, :list_webhooks
      alias_method :webhooks, :list_webhooks

      private

      attr_reader :client
    end
  end
end
