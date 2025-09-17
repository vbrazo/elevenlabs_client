# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class TestInvocations
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/test-invocations/{test_invocation_id}
        # Gets a test invocation by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/test-invocations/get
        #
        # @param test_invocation_id [String] The id of a test invocation
        # @return [Hash] Test invocation details including test runs and status
        def get(test_invocation_id)
          endpoint = "/v1/convai/test-invocations/#{test_invocation_id}"
          @client.get(endpoint)
        end

        # POST /v1/convai/test-invocations/{test_invocation_id}/resubmit
        # Resubmits specific test runs from a test invocation
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/test-invocations/resubmit
        #
        # @param test_invocation_id [String] The id of a test invocation
        # @param test_run_ids [Array<String>] List of test run IDs to resubmit
        # @param agent_id [String] Agent ID to resubmit tests for
        # @param options [Hash] Optional parameters
        # @option options [Hash] :agent_config_override Configuration overrides to use for testing
        # @return [Hash] Resubmission response
        def resubmit(test_invocation_id, test_run_ids:, agent_id:, **options)
          endpoint = "/v1/convai/test-invocations/#{test_invocation_id}/resubmit"
          request_body = {
            test_run_ids: test_run_ids,
            agent_id: agent_id
          }.merge(options)
          
          @client.post(endpoint, request_body)
        end
      end
    end
  end
end
