# frozen_string_literal: true

module ElevenlabsClient
  class TextToVoice
    def initialize(client)
      @client = client
    end

    # POST /v1/text-to-voice/design
    # Designs a voice based on a description
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-voice/design
    #
    # @param voice_description [String] Description of the voice (20-1000 characters)
    # @param options [Hash] Optional parameters
    # @option options [String] :output_format Output format (e.g., "mp3_44100_192")
    # @option options [String] :model_id Model to use (e.g., "eleven_multilingual_ttv_v2", "eleven_ttv_v3")
    # @option options [String] :text Text to generate (100-1000 characters, optional)
    # @option options [Boolean] :auto_generate_text Auto-generate text (default: false)
    # @option options [Float] :loudness Loudness level (-1 to 1, default: 0.5)
    # @option options [Integer] :seed Random seed (0 to 2147483647, optional)
    # @option options [Float] :guidance_scale Guidance scale (0 to 100, default: 5)
    # @option options [Boolean] :stream_previews Stream previews (default: false)
    # @option options [String] :remixing_session_id Remixing session ID (optional)
    # @option options [String] :remixing_session_iteration_id Remixing session iteration ID (optional)
    # @option options [Float] :quality Quality level (-1 to 1, optional)
    # @option options [String] :reference_audio_base64 Base64 encoded reference audio (optional, requires eleven_ttv_v3)
    # @option options [Float] :prompt_strength Prompt strength (0 to 1, optional, requires eleven_ttv_v3)
    # @return [Hash] JSON response containing previews and text
    def design(voice_description, **options)
      endpoint = "/v1/text-to-voice/design"
      request_body = { voice_description: voice_description }

      # Add optional parameters if provided
      request_body[:output_format] = options[:output_format] if options[:output_format]
      request_body[:model_id] = options[:model_id] if options[:model_id]
      request_body[:text] = options[:text] if options[:text]
      request_body[:auto_generate_text] = options[:auto_generate_text] unless options[:auto_generate_text].nil?
      request_body[:loudness] = options[:loudness] if options[:loudness]
      request_body[:seed] = options[:seed] if options[:seed]
      request_body[:guidance_scale] = options[:guidance_scale] if options[:guidance_scale]
      request_body[:stream_previews] = options[:stream_previews] unless options[:stream_previews].nil?
      request_body[:remixing_session_id] = options[:remixing_session_id] if options[:remixing_session_id]
      request_body[:remixing_session_iteration_id] = options[:remixing_session_iteration_id] if options[:remixing_session_iteration_id]
      request_body[:quality] = options[:quality] if options[:quality]
      request_body[:reference_audio_base64] = options[:reference_audio_base64] if options[:reference_audio_base64]
      request_body[:prompt_strength] = options[:prompt_strength] if options[:prompt_strength]

      @client.post(endpoint, request_body)
    end

    # POST /v1/text-to-voice
    # Creates a voice from the designed voice generated_voice_id
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-voice
    #
    # @param voice_name [String] Name of the voice
    # @param voice_description [String] Description of the voice (20-1000 characters)
    # @param generated_voice_id [String] The generated voice ID from design_voice
    # @param options [Hash] Optional parameters
    # @option options [Hash] :labels Optional metadata for the voice
    # @option options [Array<String>] :played_not_selected_voice_ids Optional list of voice IDs played but not selected
    # @return [Hash] JSON response containing voice_id and other voice details
    def create(voice_name, voice_description, generated_voice_id, **options)
      endpoint = "/v1/text-to-voice"
      request_body = {
        voice_name: voice_name,
        voice_description: voice_description,
        generated_voice_id: generated_voice_id
      }

      # Add optional parameters if provided
      request_body[:labels] = options[:labels] if options[:labels]
      request_body[:played_not_selected_voice_ids] = options[:played_not_selected_voice_ids] if options[:played_not_selected_voice_ids]

      @client.post(endpoint, request_body)
    end

    # GET /v1/text-to-voice/:generated_voice_id/stream
    # Stream a voice preview that was created via the /v1/text-to-voice/design endpoint
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-voice/stream-voice-preview
    #
    # @param generated_voice_id [String] The generated_voice_id to stream
    # @param block [Proc] Block to handle each streaming chunk
    # @return [Faraday::Response] The response object
    def stream_preview(generated_voice_id, &block)
      endpoint = "/v1/text-to-voice/#{generated_voice_id}/stream"
      @client.get_streaming(endpoint, &block)
    end

    # GET /v1/voices
    # Retrieves all voices associated with your Elevenlabs account
    # Documentation: https://elevenlabs.io/docs/api-reference/voices
    #
    # @return [Hash] The JSON response containing an array of voices
    def list_voices
      endpoint = "/v1/voices"
      @client.get(endpoint)
    end

    alias_method :design_voice, :design
    alias_method :create_from_generated_voice, :create
    alias_method :stream_voice_preview, :stream_preview

    private

    attr_reader :client
  end
end
