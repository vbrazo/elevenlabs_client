# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class Widgets
        def initialize(client)
          @client = client
        end

        # GET /v1/convai/agents/{agent_id}/widget
        # Retrieve the widget configuration for an agent
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/get-widget
        #
        # @param agent_id [String] The id of an agent
        # @param options [Hash] Optional parameters
        # @option options [String] :conversation_signature An expiring token that enables a websocket conversation to start
        # @return [Hash] Widget configuration including styling, behavior, and text content
        def get(agent_id, **options)
          endpoint = "/v1/convai/agents/#{agent_id}/widget"
          query_params = options.compact

          if query_params.any?
            query_string = URI.encode_www_form(query_params)
            endpoint = "#{endpoint}?#{query_string}"
          end

          @client.get(endpoint)
        end

        # POST /v1/convai/agents/{agent_id}/avatar
        # Sets the avatar for an agent displayed in the widget
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/agents/create-avatar
        #
        # @param agent_id [String] The id of an agent
        # @param avatar_file_io [IO] The avatar file to upload (e.g., `File.open("avatar.png", "rb")`)
        # @param filename [String] The name of the file, including extension
        # @return [Hash] JSON response containing agent_id and avatar_url
        def create_avatar(agent_id, avatar_file_io:, filename:)
          endpoint = "/v1/convai/agents/#{agent_id}/avatar"
          
          # Prepare multipart form data
          payload = {
            "avatar_file" => @client.file_part(avatar_file_io, filename)
          }

          @client.post_multipart(endpoint, payload)
        end
      end
    end
  end
end
