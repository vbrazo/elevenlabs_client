# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class BatchCalling
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/batch-calling/submit
        # Submit a batch call request to schedule calls for multiple recipients
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/batch-calling/submit
        #
        # @param call_name [String] Name for the batch call job
        # @param agent_id [String] The agent ID to use for all calls
        # @param agent_phone_number_id [String] The phone number ID to call from
        # @param scheduled_time_unix [Integer] Unix timestamp for when to schedule the calls
        # @param recipients [Array<Hash>] Array of recipient objects with phone numbers
        # @return [Hash] JSON response containing batch call job details
        def submit(call_name:, agent_id:, agent_phone_number_id:, scheduled_time_unix:, recipients:)
          endpoint = "/v1/convai/batch-calling/submit"
          request_body = {
            call_name: call_name,
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: recipients
          }
          
          @client.post(endpoint, request_body)
        end

        # GET /v1/convai/batch-calling/workspace
        # Get all batch calls for the current workspace
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/batch-calling/list
        #
        # @param options [Hash] Optional parameters
        # @option options [Integer] :limit Maximum number of results to return (default: 100)
        # @option options [String] :last_doc Last document ID for pagination
        # @return [Hash] JSON response containing batch calls list with pagination info
        def list(**options)
          endpoint = "/v1/convai/batch-calling/workspace"
          query_params = options.compact

          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end

          @client.get(endpoint)
        end

        # GET /v1/convai/batch-calling/{batch_id}
        # Get detailed information about a batch call including all recipients
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/batch-calling/get
        #
        # @param batch_id [String] The ID of the batch call job
        # @return [Hash] JSON response containing detailed batch call information including recipients
        def get(batch_id)
          endpoint = "/v1/convai/batch-calling/#{batch_id}"
          @client.get(endpoint)
        end

        # POST /v1/convai/batch-calling/{batch_id}/cancel
        # Cancel a running batch call and set all recipients to cancelled status
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/batch-calling/cancel
        #
        # @param batch_id [String] The ID of the batch call job to cancel
        # @return [Hash] JSON response containing updated batch call information
        def cancel(batch_id)
          endpoint = "/v1/convai/batch-calling/#{batch_id}/cancel"
          @client.post(endpoint, {})
        end

        # POST /v1/convai/batch-calling/{batch_id}/retry
        # Retry a batch call, calling failed and no-response recipients again
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/batch-calling/retry
        #
        # @param batch_id [String] The ID of the batch call job to retry
        # @return [Hash] JSON response containing updated batch call information
        def retry(batch_id)
          endpoint = "/v1/convai/batch-calling/#{batch_id}/retry"
          @client.post(endpoint, {})
        end
      end
    end
  end
end
