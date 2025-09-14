# frozen_string_literal: true

module ElevenlabsClient
  class TextToDialogueStream
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-dialogue/stream
    # Converts a list of text and voice ID pairs into speech (dialogue) and returns an audio stream.
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-dialogue/stream
    #
    # @param inputs [Array<Hash>] A list of dialogue inputs, each containing text and a voice ID
    # @param options [Hash] Optional parameters
    # @option options [String] :model_id Identifier of the model to be used (default: "eleven_v3")
    # @option options [String] :language_code ISO 639-1 language code
    # @option options [Hash] :settings Settings controlling the dialogue generation
    # @option options [Array<Hash>] :pronunciation_dictionary_locators Pronunciation dictionary locators (max 3)
    # @option options [Integer] :seed Deterministic sampling seed (0-4294967295)
    # @option options [String] :apply_text_normalization Text normalization mode ("auto", "on", "off")
    # @option options [String] :output_format Output format (defaults to "mp3_44100_128")
    # @param block [Proc] Block to handle each audio chunk
    # @return [Faraday::Response] The response object
    def stream(inputs, **options, &block)
      # Build endpoint with optional query params
      output_format = options[:output_format] || "mp3_44100_128"
      endpoint = "/v1/text-to-dialogue/stream?output_format=#{output_format}"

      # Build request body
      request_body = { inputs: inputs }
      request_body[:model_id] = options[:model_id] if options[:model_id]
      request_body[:language_code] = options[:language_code] if options[:language_code]
      request_body[:settings] = options[:settings] if options[:settings]
      request_body[:pronunciation_dictionary_locators] = options[:pronunciation_dictionary_locators] if options[:pronunciation_dictionary_locators]
      request_body[:seed] = options[:seed] if options[:seed]
      request_body[:apply_text_normalization] = options[:apply_text_normalization] if options[:apply_text_normalization]

      @client.post_streaming(endpoint, request_body, &block)
    end

    # Alias for convenience
    alias_method :text_to_dialogue_stream, :stream

    private

    attr_reader :client
  end
end


