# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      # LLM Usage endpoint - refactored for better maintainability
      class LlmUsage
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/llm-usage/calculate
        # Returns a list of LLM models and the expected cost for using them based on the provided values
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/llm-usage/calculate
        #
        # @param prompt_length [Integer] Length of the prompt in characters (required)
        # @param number_of_pages [Integer] Pages of content in PDF documents or URLs in the agent's knowledge base (required)
        # @param rag_enabled [Boolean] Whether RAG is enabled (required)
        # @return [Hash] JSON response containing list of LLM models with pricing information
        def calculate(prompt_length:, number_of_pages:, rag_enabled:)
          validate_required!(:prompt_length, prompt_length)
          validate_required!(:number_of_pages, number_of_pages) 
          validate_required!(:rag_enabled, rag_enabled)

          body = {
            prompt_length: prompt_length,
            number_of_pages: number_of_pages,
            rag_enabled: rag_enabled
          }

          @client.post("/v1/convai/llm-usage/calculate", body)
        end

        # Convenience alias
        alias_method :calculate_usage, :calculate

        private

        attr_reader :client

        # Parameter validation that handles boolean values properly
        def validate_required!(param_name, value)
          if value.nil?
            raise ArgumentError, "#{param_name} is required"
          end
        end
      end
    end
  end
end
