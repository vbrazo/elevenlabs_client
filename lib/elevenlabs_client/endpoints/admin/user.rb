# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class User
      def initialize(client)
        @client = client
      end

      # GET /v1/user
      # Gets information about the user
      # Documentation: https://elevenlabs.io/docs/api-reference/user/get-user
      #
      # @return [Hash] The JSON response containing user information including subscription details
      def get_user
        endpoint = "/v1/user"
        @client.get(endpoint)
      end

      alias_method :user, :get_user
      alias_method :info, :get_user

      # GET /v1/user/subscription
      # Gets extended information about the user's subscription
      # Documentation: https://elevenlabs.io/docs/api-reference/user/get-user-subscription
      #
      # @return [Hash] The JSON response containing subscription info
      def get_subscription
        endpoint = "/v1/user/subscription"
        @client.get(endpoint)
      end

      alias_method :subscription, :get_subscription

      private

      attr_reader :client
    end
  end
end
