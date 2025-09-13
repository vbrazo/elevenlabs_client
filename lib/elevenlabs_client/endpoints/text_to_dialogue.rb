# frozen_string_literal: true

module ElevenlabsClient
  class TextToDialogue
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-dialogue
    # Converts a list of text and voice ID pairs into speech (dialogue) and returns audio.
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-dialogue/convert
    #
    # @param inputs [Array<Hash>] A list of dialogue inputs, each containing text and a voice ID
    # @option inputs [String] :text The text to be converted to speech
    # @option inputs [String] :voice_id The voice ID to use for this text
    # @param options [Hash] Optional parameters
    # @option options [String] :model_id Identifier of the model to be used
    # @option options [Hash] :settings Settings controlling the dialogue generation
    # @option options [Integer] :seed Best effort to sample deterministically
    # @return [String] The binary audio data (usually an MP3)
    def convert(inputs, **options)
      endpoint = "/v1/text-to-dialogue"
      request_body = { inputs: inputs }

      # Add optional parameters
      request_body[:model_id] = options[:model_id] if options[:model_id]
      request_body[:settings] = options[:settings] if options[:settings] && !options[:settings].empty?
      request_body[:seed] = options[:seed] if options[:seed]

      @client.post_binary(endpoint, request_body)
    end

    # Alias for backward compatibility and convenience
    alias_method :text_to_dialogue, :convert

    private

    attr_reader :client
  end
end
