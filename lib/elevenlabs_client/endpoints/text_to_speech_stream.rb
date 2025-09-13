# frozen_string_literal: true

module ElevenlabsClient
  class TextToSpeechStream
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-speech/{voice_id}/stream
    # Stream text-to-speech audio in real-time chunks
    #
    # @param voice_id [String] The ID of the voice to use
    # @param text [String] Text to synthesize
    # @param options [Hash] Optional TTS parameters
    # @option options [String] :model_id Model to use (defaults to "eleven_multilingual_v2")
    # @option options [String] :output_format Output format (defaults to "mp3_44100_128")
    # @option options [Hash] :voice_settings Voice configuration
    # @param block [Proc] Block to handle each audio chunk
    # @return [Faraday::Response] The response object
    def stream(voice_id, text, **options, &block)
      output_format = options[:output_format] || "mp3_44100_128"
      endpoint = "/v1/text-to-speech/#{voice_id}/stream?output_format=#{output_format}"
      
      request_body = {
        text: text,
        model_id: options[:model_id] || "eleven_multilingual_v2"
      }
      
      # Add voice_settings if provided
      request_body[:voice_settings] = options[:voice_settings] if options[:voice_settings]

      @client.post_streaming(endpoint, request_body, &block)
    end

    # Alias for backward compatibility
    alias_method :text_to_speech_stream, :stream

    private

    attr_reader :client
  end
end
