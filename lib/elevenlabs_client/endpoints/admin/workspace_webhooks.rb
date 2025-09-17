# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class WorkspaceWebhooks
        def initialize(client)
          @client = client
        end

        # GET /v1/workspace/webhooks
        # List all webhooks for a workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/workspace/webhooks/list
        #
        # @param options [Hash] Optional parameters
        # @option options [Boolean] :include_usages Whether to include active usages of the webhook (admin only)
        # @return [Hash] JSON response containing list of webhooks
        def list(**options)
          endpoint = "/v1/workspace/webhooks"
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
