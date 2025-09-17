# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Tests
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/agent-testing
        # Lists all agent response tests with pagination support and optional search filtering
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/list
        #
        # @param options [Hash] Query parameters
        # @option options [String] :cursor Used for fetching next page
        # @option options [Integer] :page_size How many tests to return at maximum (1-100, default: 30)
        # @option options [String] :search Search query to filter tests by name
        # @return [Hash] List of tests with pagination info
        def list(**options)
          endpoint = "/v1/convai/agent-testing"
          query_params = options.compact
          
          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end
          
          @client.get(endpoint)
        end

        # GET /v1/convai/agent-testing/{test_id}
        # Gets an agent response test by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/get
        #
        # @param test_id [String] The id of a chat response test
        # @return [Hash] Complete test details including chat history and evaluation criteria
        def get(test_id)
          endpoint = "/v1/convai/agent-testing/#{test_id}"
          @client.get(endpoint)
        end

        # POST /v1/convai/agent-testing/create
        # Creates a new agent response test
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/create
        #
        # @param name [String] Name of the test
        # @param chat_history [Array<Hash>] List of chat messages for the test
        # @param success_condition [String] Prompt that evaluates whether the agent's response is successful
        # @param success_examples [Array<Hash>] Non-empty list of example responses that should be considered successful
        # @param failure_examples [Array<Hash>] Non-empty list of example responses that should be considered failures
        # @param options [Hash] Optional parameters
        # @option options [Hash] :tool_call_parameters How to evaluate the agent's tool call (if any)
        # @option options [Hash] :dynamic_variables Dynamic variables to replace in the agent config during testing
        # @option options [String] :type Test type ("llm" or "tool")
        # @return [Hash] Created test with ID
        def create(name:, chat_history:, success_condition:, success_examples:, failure_examples:, **options)
          endpoint = "/v1/convai/agent-testing/create"
          request_body = {
            name: name,
            chat_history: chat_history,
            success_condition: success_condition,
            success_examples: success_examples,
            failure_examples: failure_examples
          }.merge(options)
          
          @client.post(endpoint, request_body)
        end

        # PUT /v1/convai/agent-testing/{test_id}
        # Updates an agent response test by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/update
        #
        # @param test_id [String] The id of a chat response test
        # @param name [String] Name of the test
        # @param chat_history [Array<Hash>] List of chat messages for the test
        # @param success_condition [String] Prompt that evaluates whether the agent's response is successful
        # @param success_examples [Array<Hash>] Non-empty list of example responses that should be considered successful
        # @param failure_examples [Array<Hash>] Non-empty list of example responses that should be considered failures
        # @param options [Hash] Optional parameters
        # @option options [Hash] :tool_call_parameters How to evaluate the agent's tool call (if any)
        # @option options [Hash] :dynamic_variables Dynamic variables to replace in the agent config during testing
        # @option options [String] :type Test type ("llm" or "tool")
        # @return [Hash] Updated test details
        def update(test_id, name:, chat_history:, success_condition:, success_examples:, failure_examples:, **options)
          endpoint = "/v1/convai/agent-testing/#{test_id}"
          request_body = {
            name: name,
            chat_history: chat_history,
            success_condition: success_condition,
            success_examples: success_examples,
            failure_examples: failure_examples
          }.merge(options)
          
          @client.patch(endpoint, request_body)
        end

        # DELETE /v1/convai/agent-testing/{test_id}
        # Deletes an agent response test by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/delete
        #
        # @param test_id [String] The id of a chat response test
        # @return [Hash] Empty response on success
        def delete(test_id)
          endpoint = "/v1/convai/agent-testing/#{test_id}"
          @client.delete(endpoint)
        end

        # POST /v1/convai/agent-testing/summaries
        # Gets multiple agent response tests by their IDs
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/summaries
        #
        # @param test_ids [Array<String>] List of test IDs to fetch (no duplicates allowed)
        # @return [Hash] Dictionary mapping test IDs to their summary information
        def get_summaries(test_ids)
          endpoint = "/v1/convai/agent-testing/summaries"
          request_body = { test_ids: test_ids }
          @client.post(endpoint, request_body)
        end

        # POST /v1/convai/agents/{agent_id}/run-tests
        # Run selected tests on the agent with provided configuration
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agent-testing/run-tests
        #
        # @param agent_id [String] The id of an agent
        # @param tests [Array<Hash>] List of tests to run on the agent
        # @param options [Hash] Optional parameters
        # @option options [Hash] :agent_config_override Configuration overrides to use for testing
        # @return [Hash] Test run results with status and responses
        def run_on_agent(agent_id, tests:, **options)
          endpoint = "/v1/convai/agents/#{agent_id}/run-tests"
          request_body = { tests: tests }.merge(options)
          @client.post(endpoint, request_body)
        end
      end
    end
  end
end
