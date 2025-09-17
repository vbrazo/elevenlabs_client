# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Agents
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/agents/create
        # Create an agent from a config object
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/create
        #
        # @param options [Hash] Agent creation parameters
        # @option options [Hash] :conversation_config Required conversation configuration for an agent
        # @option options [Hash] :platform_settings Optional platform settings for the agent
        # @option options [String] :name Optional name to make the agent easier to find
        # @option options [Array<String>] :tags Optional tags to help classify and filter the agent
        # @return [Hash] JSON response containing agent_id
        def create(**options)
          endpoint = "/v1/convai/agents/create"
          request_body = options
          @client.post(endpoint, request_body)
        end

        # GET /v1/convai/agents/{agent_id}
        # Retrieve config for an agent
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/get
        #
        # @param agent_id [String] The id of an agent
        # @return [Hash] Agent configuration and metadata
        def get(agent_id)
          endpoint = "/v1/convai/agents/#{agent_id}"
          @client.get(endpoint)
        end

        # GET /v1/convai/agents
        # Returns a list of your agents and their metadata
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/list
        #
        # @param options [Hash] Query parameters
        # @option options [Integer] :page_size How many agents to return at maximum (1-100, default: 30)
        # @option options [String] :search Search by agents name
        # @option options [String] :sort_direction The direction to sort the results ("asc" or "desc")
        # @option options [String] :sort_by The field to sort the results by ("name" or "created_at")
        # @option options [String] :cursor Used for fetching next page
        # @return [Hash] List of agents with pagination info
        def list(**options)
          endpoint = "/v1/convai/agents"
          query_params = options.compact
          
          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end
          
          @client.get(endpoint)
        end

        # PATCH /v1/convai/agents/{agent_id}
        # Patches an Agent settings
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/update
        #
        # @param agent_id [String] The id of an agent
        # @param options [Hash] Agent update parameters
        # @option options [Hash] :conversation_config Optional conversation configuration for an agent
        # @option options [Hash] :platform_settings Optional platform settings for the agent
        # @option options [String] :name Optional name to make the agent easier to find
        # @option options [Array<String>] :tags Optional tags to help classify and filter the agent
        # @return [Hash] Updated agent configuration and metadata
        def update(agent_id, **options)
          endpoint = "/v1/convai/agents/#{agent_id}"
          request_body = options.compact
          @client.patch(endpoint, request_body)
        end

        # DELETE /v1/convai/agents/{agent_id}
        # Delete an agent
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/delete
        #
        # @param agent_id [String] The id of an agent
        # @return [Hash] Empty response on success
        def delete(agent_id)
          endpoint = "/v1/convai/agents/#{agent_id}"
          @client.delete(endpoint)
        end

        # POST /v1/convai/agents/{agent_id}/duplicate
        # Create a new agent by duplicating an existing one
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/duplicate
        #
        # @param agent_id [String] The id of an agent to duplicate
        # @param options [Hash] Duplication parameters
        # @option options [String] :name Optional name to make the agent easier to find
        # @return [Hash] JSON response containing new agent_id
        def duplicate(agent_id, **options)
          endpoint = "/v1/convai/agents/#{agent_id}/duplicate"
          request_body = options.compact
          @client.post(endpoint, request_body)
        end

        # GET /v1/convai/agents/{agent_id}/link
        # Get the current link used to share the agent with others
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/link
        #
        # @param agent_id [String] The id of an agent
        # @return [Hash] Agent link information including token data
        def link(agent_id)
          endpoint = "/v1/convai/agents/#{agent_id}/link"
          @client.get(endpoint)
        end

        # POST /v1/convai/agents/{agent_id}/simulate-conversation
        # Run a conversation between the agent and a simulated user
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/simulate-conversation
        #
        # @param agent_id [String] The id of an agent
        # @param options [Hash] Simulation parameters
        # @option options [Hash] :simulation_specification Required specification detailing how the conversation should be simulated
        # @option options [Array<Hash>] :extra_evaluation_criteria Optional list of evaluation criteria to test
        # @option options [Integer] :new_turns_limit Optional maximum number of new turns to generate (default: 10000)
        # @return [Hash] Simulated conversation and analysis
        def simulate_conversation(agent_id, **options)
          endpoint = "/v1/convai/agents/#{agent_id}/simulate-conversation"
          request_body = options
          @client.post(endpoint, request_body)
        end

        # POST /v1/convai/agents/{agent_id}/simulate-conversation/stream
        # Run a conversation between the agent and a simulated user and stream back the response
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/simulate-conversation-stream
        #
        # @param agent_id [String] The id of an agent
        # @param options [Hash] Simulation parameters
        # @option options [Hash] :simulation_specification Required specification detailing how the conversation should be simulated
        # @option options [Array<Hash>] :extra_evaluation_criteria Optional list of evaluation criteria to test
        # @option options [Integer] :new_turns_limit Optional maximum number of new turns to generate (default: 10000)
        # @param block [Proc] Block to handle streaming response chunks
        # @return [Enumerator] Streaming response enumerator if no block given
        def simulate_conversation_stream(agent_id, **options, &block)
          endpoint = "/v1/convai/agents/#{agent_id}/simulate-conversation/stream"
          request_body = options
          @client.post_streaming(endpoint, request_body, &block)
        end

        # POST /v1/convai/agent/{agent_id}/llm-usage/calculate
        # Calculates expected number of LLM tokens needed for the specified agent
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/calculate-llm-usage
        #
        # @param agent_id [String] The id of an agent
        # @param options [Hash] Calculation parameters
        # @option options [Integer] :prompt_length Optional length of the prompt in characters
        # @option options [Integer] :number_of_pages Optional pages of content in pdf documents OR urls in agent's Knowledge Base
        # @option options [Boolean] :rag_enabled Optional whether RAG is enabled
        # @return [Hash] LLM usage pricing information
        def calculate_llm_usage(agent_id, **options)
          endpoint = "/v1/convai/agent/#{agent_id}/llm-usage/calculate"
          request_body = options.compact
          @client.post(endpoint, request_body)
        end
      end
    end
  end
end
