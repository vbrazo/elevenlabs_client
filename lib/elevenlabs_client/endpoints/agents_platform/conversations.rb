# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Conversations
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/conversations
        # Get all conversations of agents that user owns
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/list
        #
        # @param options [Hash] Query parameters
        # @option options [String] :cursor Used for fetching next page
        # @option options [String] :agent_id The id of the agent to filter by
        # @option options [String] :call_successful The result of the success evaluation ("success", "failure", "unknown")
        # @option options [Integer] :call_start_before_unix Unix timestamp to filter conversations up to this start date
        # @option options [Integer] :call_start_after_unix Unix timestamp to filter conversations after this start date
        # @option options [String] :user_id Filter conversations by the user ID who initiated them
        # @option options [Integer] :page_size How many conversations to return at maximum (1-100, default: 30)
        # @option options [String] :summary_mode Whether to include transcript summaries ("exclude", "include", default: "exclude")
        # @return [Hash] List of conversations with pagination info
        def list(**options)
          endpoint = "/v1/convai/conversations"
          query_params = options.compact
          
          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end
          
          @client.get(endpoint)
        end

        # GET /v1/convai/conversations/{conversation_id}
        # Get the details of a particular conversation
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/get
        #
        # @param conversation_id [String] The id of the conversation
        # @return [Hash] Conversation details including transcript and metadata
        def get(conversation_id)
          endpoint = "/v1/convai/conversations/#{conversation_id}"
          @client.get(endpoint)
        end

        # DELETE /v1/convai/conversations/{conversation_id}
        # Delete a particular conversation
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/delete
        #
        # @param conversation_id [String] The id of the conversation
        # @return [Hash] Empty response on success
        def delete(conversation_id)
          endpoint = "/v1/convai/conversations/#{conversation_id}"
          @client.delete(endpoint)
        end

        # GET /v1/convai/conversations/{conversation_id}/audio
        # Get the audio recording of a particular conversation
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/audio
        #
        # @param conversation_id [String] The id of the conversation
        # @return [String] Binary audio data
        def get_audio(conversation_id)
          endpoint = "/v1/convai/conversations/#{conversation_id}/audio"
          @client.get_binary(endpoint)
        end

        # GET /v1/convai/conversation/get-signed-url
        # Get a signed url to start a conversation with an agent that requires authorization
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/get-signed-url
        #
        # @param agent_id [String] The id of the agent
        # @param options [Hash] Optional parameters
        # @option options [Boolean] :include_conversation_id Whether to include a conversation_id with the response (default: false)
        # @return [Hash] Response containing signed_url
        def get_signed_url(agent_id, **options)
          endpoint = "/v1/convai/conversation/get-signed-url"
          query_params = { agent_id: agent_id }.merge(options.compact)
          
          query_string = URI.encode_www_form(query_params)
          endpoint_with_query = "#{endpoint}?#{query_string}"
          
          @client.get(endpoint_with_query)
        end

        # GET /v1/convai/conversation/token
        # Get a WebRTC session token for real-time communication
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/token
        #
        # @param agent_id [String] The id of the agent
        # @param options [Hash] Optional parameters
        # @option options [String] :participant_name Optional custom participant name
        # @return [Hash] Response containing WebRTC token
        def get_token(agent_id, **options)
          endpoint = "/v1/convai/conversation/token"
          query_params = { agent_id: agent_id }.merge(options.compact)
          
          query_string = URI.encode_www_form(query_params)
          endpoint_with_query = "#{endpoint}?#{query_string}"
          
          @client.get(endpoint_with_query)
        end

        # POST /v1/convai/conversations/{conversation_id}/feedback
        # Send the feedback for the given conversation
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/conversations/feedback
        #
        # @param conversation_id [String] The id of the conversation
        # @param feedback [String] Either 'like' or 'dislike' to indicate the feedback
        # @return [Hash] Empty response on success
        def send_feedback(conversation_id, feedback)
          endpoint = "/v1/convai/conversations/#{conversation_id}/feedback"
          request_body = { feedback: feedback }
          @client.post(endpoint, request_body)
        end
      end
    end
  end
end
