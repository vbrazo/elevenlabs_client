# frozen_string_literal: true

module ElevenlabsClient
  class TextToSpeechStreamWithTimestamps
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-speech/{voice_id}/stream/with-timestamps
    # Stream text-to-speech audio with character-level timing information
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-speech/stream-with-timestamps
    #
    # @param voice_id [String] Voice ID to be used
    # @param text [String] The text that will get converted into speech
    # @param options [Hash] Optional TTS parameters
    # @option options [String] :model_id Model identifier (defaults to "eleven_multilingual_v2")
    # @option options [String] :language_code ISO 639-1 language code for text normalization
    # @option options [Hash] :voice_settings Voice settings overriding stored settings
    # @option options [Array<Hash>] :pronunciation_dictionary_locators Pronunciation dictionary locators (max 3)
    # @option options [Integer] :seed Deterministic sampling seed (0-4294967295)
    # @option options [String] :previous_text Text that came before current request
    # @option options [String] :next_text Text that comes after current request
    # @option options [Array<String>] :previous_request_ids Request IDs of previous samples (max 3)
    # @option options [Array<String>] :next_request_ids Request IDs of next samples (max 3)
    # @option options [String] :apply_text_normalization Text normalization mode ("auto", "on", "off")
    # @option options [Boolean] :apply_language_text_normalization Language text normalization
    # @option options [Boolean] :use_pvc_as_ivc Use IVC version instead of PVC (deprecated)
    # @option options [Boolean] :enable_logging Enable logging (defaults to true)
    # @option options [Integer] :optimize_streaming_latency Latency optimizations (0-4, deprecated)
    # @option options [String] :output_format Output format (defaults to "mp3_44100_128")
    # @param block [Proc] Block to handle each streaming chunk containing audio and timing data
    # @return [Faraday::Response] The response object
    def stream(voice_id, text, **options, &block)
      # Build query parameters
      query_params = {}
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      query_params[:optimize_streaming_latency] = options[:optimize_streaming_latency] if options[:optimize_streaming_latency]
      query_params[:output_format] = options[:output_format] if options[:output_format]
      
      # Build endpoint with query parameters
      endpoint = "/v1/text-to-speech/#{voice_id}/stream/with-timestamps"
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end
      
      # Build request body
      request_body = { text: text }
      
      # Add optional body parameters
      request_body[:model_id] = options[:model_id] if options[:model_id]
      request_body[:language_code] = options[:language_code] if options[:language_code]
      request_body[:voice_settings] = options[:voice_settings] if options[:voice_settings]
      request_body[:pronunciation_dictionary_locators] = options[:pronunciation_dictionary_locators] if options[:pronunciation_dictionary_locators]
      request_body[:seed] = options[:seed] if options[:seed]
      request_body[:previous_text] = options[:previous_text] if options[:previous_text]
      request_body[:next_text] = options[:next_text] if options[:next_text]
      request_body[:previous_request_ids] = options[:previous_request_ids] if options[:previous_request_ids]
      request_body[:next_request_ids] = options[:next_request_ids] if options[:next_request_ids]
      request_body[:apply_text_normalization] = options[:apply_text_normalization] if options[:apply_text_normalization]
      request_body[:apply_language_text_normalization] = options[:apply_language_text_normalization] unless options[:apply_language_text_normalization].nil?
      request_body[:use_pvc_as_ivc] = options[:use_pvc_as_ivc] unless options[:use_pvc_as_ivc].nil?

      # Use streaming method with JSON parsing for timestamp data
      @client.post_streaming_with_timestamps(endpoint, request_body, &block)
    end

    # Alias for backward compatibility
    alias_method :text_to_speech_stream_with_timestamps, :stream

    private

    attr_reader :client
  end
end
