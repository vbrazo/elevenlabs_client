# frozen_string_literal: true

module ElevenlabsClient
  class ForcedAlignment
    def initialize(client)
      @client = client
    end

    # POST /v1/forced-alignment
    # Force align an audio file to text. Get timing information for each character and word
    # Documentation: https://elevenlabs.io/docs/api-reference/forced-alignment
    #
    # @param audio_file [IO, File] The audio file to align (must be less than 1GB)
    # @param filename [String] Original filename for the audio file
    # @param text [String] The text to align with the audio
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :enabled_spooled_file Stream file in chunks for large files (defaults to false)
    # @return [Hash] JSON response containing characters, words arrays with timing info, and loss score
    def create(audio_file, filename, text, **options)
      endpoint = "/v1/forced-alignment"
      
      payload = {
        file: @client.file_part(audio_file, filename),
        text: text
      }
      
      # Add optional parameters if provided
      payload[:enabled_spooled_file] = options[:enabled_spooled_file] unless options[:enabled_spooled_file].nil?

      @client.post_multipart(endpoint, payload)
    end

    # Alias methods for convenience
    alias_method :align, :create
    alias_method :force_align, :create

    private

    attr_reader :client
  end
end
