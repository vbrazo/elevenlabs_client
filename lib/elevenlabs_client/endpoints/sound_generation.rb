# frozen_string_literal: true

module ElevenlabsClient
  class SoundGeneration
    def initialize(client)
      @client = client
    end

    # POST /v1/sound-generation
    # Convert text to sound effects and retrieve audio (binary data)
    # Documentation: https://elevenlabs.io/docs/api-reference/sound-generation
    #
    # @param text [String] Text prompt describing the sound effect
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :loop Whether to create a looping sound effect (default: false)
    # @option options [Float] :duration_seconds Duration in seconds (0.5 to 30, default: nil for auto-detection)
    # @option options [Float] :prompt_influence Prompt influence (0.0 to 1.0, default: 0.3)
    # @option options [String] :output_format Output format (e.g., "mp3_22050_32", default: "mp3_44100_128")
    # @return [String] The binary audio data (usually an MP3)
    def generate(text, **options)
      endpoint = "/v1/sound-generation"
      request_body = { text: text }

      # Add optional parameters if provided
      request_body[:loop] = options[:loop] unless options[:loop].nil?
      request_body[:duration_seconds] = options[:duration_seconds] if options[:duration_seconds]
      request_body[:prompt_influence] = options[:prompt_influence] if options[:prompt_influence]

      # Handle output_format as query parameter
      query_params = {}
      query_params[:output_format] = options[:output_format] if options[:output_format]

      # Build endpoint with query parameters if any
      full_endpoint = query_params.any? ? "#{endpoint}?#{URI.encode_www_form(query_params)}" : endpoint

      @client.post_binary(full_endpoint, request_body)
    end

    alias_method :sound_generation, :generate

    private

    attr_reader :client
  end
end
