# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    class Music
      def initialize(client)
        @client = client
      end

      # POST /v1/music
      # Compose music and return binary audio data
      # Documentation: https://elevenlabs.io/docs/api-reference/music/compose
      #
      # @param options [Hash] Music composition parameters
      # @option options [String] :prompt Text description of the music to generate
      # @option options [Hash] :composition_plan Detailed composition structure (optional)
      # @option options [Integer] :music_length_ms Length of music in milliseconds (optional)
      # @option options [String] :model_id Model to use for generation (default: "music_v1")
      # @option options [String] :output_format Audio format (e.g., "mp3_44100_128")
      # @return [String] Binary audio data
      def compose(options = {})
        endpoint = "/v1/music"
        request_body = build_music_request_body(options)
        
        query_params = {}
        query_params[:output_format] = options[:output_format] if options[:output_format]
        
        endpoint_with_query = query_params.empty? ? endpoint : "#{endpoint}?#{URI.encode_www_form(query_params)}"
        
        @client.post_binary(endpoint_with_query, request_body)
      end

      # POST /v1/music/stream
      # Compose music with streaming audio response
      # Documentation: https://elevenlabs.io/docs/api-reference/music/compose-stream
      #
      # @param options [Hash] Music composition parameters
      # @option options [String] :prompt Text description of the music to generate
      # @option options [Hash] :composition_plan Detailed composition structure (optional)
      # @option options [Integer] :music_length_ms Length of music in milliseconds (optional)
      # @option options [String] :model_id Model to use for generation (default: "music_v1")
      # @option options [String] :output_format Audio format (e.g., "mp3_44100_128")
      # @param block [Proc] Block to handle streaming audio chunks
      # @return [nil] Audio is streamed via the block
      def compose_stream(options = {}, &block)
        endpoint = "/v1/music/stream"
        request_body = build_music_request_body(options)
        
        query_params = {}
        query_params[:output_format] = options[:output_format] if options[:output_format]
        
        endpoint_with_query = query_params.empty? ? endpoint : "#{endpoint}?#{URI.encode_www_form(query_params)}"
        
        @client.post_streaming(endpoint_with_query, request_body, &block)
      end

      # POST /v1/music/detailed
      # Compose music and return detailed response with metadata and audio
      # Documentation: https://elevenlabs.io/docs/api-reference/music/compose-detailed
      #
      # @param options [Hash] Music composition parameters
      # @option options [String] :prompt Text description of the music to generate
      # @option options [Hash] :composition_plan Detailed composition structure (optional)
      # @option options [Integer] :music_length_ms Length of music in milliseconds (optional)
      # @option options [String] :model_id Model to use for generation (default: "music_v1")
      # @option options [String] :output_format Audio format (e.g., "mp3_44100_128")
      # @return [String] Multipart response with JSON metadata and binary audio
      def compose_detailed(options = {})
        endpoint = "/v1/music/detailed"
        request_body = build_music_request_body(options)
        
        query_params = {}
        query_params[:output_format] = options[:output_format] if options[:output_format]
        
        endpoint_with_query = query_params.empty? ? endpoint : "#{endpoint}?#{URI.encode_www_form(query_params)}"
        
        # Use post_with_custom_headers to handle multipart response
        @client.post_with_custom_headers(
          endpoint_with_query,
          request_body,
          { "Accept" => "multipart/mixed" }
        )
      end

      # POST /v1/music/plan
      # Create a composition plan for music generation
      # Documentation: https://elevenlabs.io/docs/api-reference/music/create-plan
      #
      # @param options [Hash] Plan creation parameters
      # @option options [String] :prompt Text description of the music style/structure
      # @option options [Integer] :music_length_ms Desired length of music in milliseconds
      # @option options [Hash] :source_composition_plan Base plan to modify (optional)
      # @option options [String] :model_id Model to use for plan generation (default: "music_v1")
      # @return [Hash] JSON response containing the composition plan
      def create_plan(options = {})
        endpoint = "/v1/music/plan"
        request_body = {
          prompt: options[:prompt],
          music_length_ms: options[:music_length_ms],
          source_composition_plan: options[:source_composition_plan],
          model_id: options[:model_id] || "music_v1"
        }.compact
        
        @client.post(endpoint, request_body)
      end

      # Alias methods for convenience
      alias_method :compose_music, :compose
      alias_method :compose_music_stream, :compose_stream
      alias_method :compose_music_detailed, :compose_detailed
      alias_method :create_music_plan, :create_plan

      private

      attr_reader :client

      def build_music_request_body(options)
        {
          prompt: options[:prompt],
          composition_plan: options[:composition_plan],
          music_length_ms: options[:music_length_ms],
          model_id: options[:model_id] || "music_v1"
        }.compact
      end
    end
  end
end
