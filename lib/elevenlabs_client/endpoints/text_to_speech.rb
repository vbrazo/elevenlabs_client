# frozen_string_literal: true

module ElevenlabsClient
  class TextToSpeech
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-speech/{voice_id}
    # Convert text to speech and retrieve audio (binary data)
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-speech/convert
    #
    # @param voice_id [String] The ID of the voice to use
    # @param text [String] Text to synthesize
    # @param options [Hash] Optional TTS parameters
    # @option options [String] :model_id Model to use (e.g. "eleven_monolingual_v1" or "eleven_multilingual_v1")
    # @option options [Hash] :voice_settings Voice configuration (stability, similarity_boost, style, use_speaker_boost, etc.)
    # @option options [Boolean] :optimize_streaming Whether to receive chunked streaming audio
    # @return [String] The binary audio data (usually an MP3)
    def convert(voice_id, text, **options)
      endpoint = "/v1/text-to-speech/#{voice_id}"
      request_body = { text: text }

      # Add optional parameters
      request_body[:model_id] = options[:model_id] if options[:model_id]
      request_body[:voice_settings] = options[:voice_settings] if options[:voice_settings]

      # Handle streaming optimization
      if options[:optimize_streaming]
        @client.post_with_custom_headers(endpoint, request_body, streaming_headers)
      else
        @client.post_binary(endpoint, request_body)
      end
    end

    # Alias for backward compatibility and convenience
    alias_method :text_to_speech, :convert

    private

    attr_reader :client

    def streaming_headers
      {
        "Accept" => "audio/mpeg",
        "Transfer-Encoding" => "chunked"
      }
    end
  end
end
