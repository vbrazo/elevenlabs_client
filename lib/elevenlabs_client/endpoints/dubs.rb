# frozen_string_literal: true

module ElevenlabsClient
  class Dubs
    def initialize(client)
      @client = client
    end

    # POST /v1/dubbing (multipart)
    # Creates a new dubbing job
    # 
    # @param file_io [IO] The audio/video file to dub
    # @param filename [String] Original filename 
    # @param target_languages [Array<String>] Target language codes (e.g., ["es", "pt", "fr"])
    # @param name [String, nil] Optional name for the dubbing job
    # @param options [Hash] Additional options (drop_background_audio, use_profanity_filter, etc.)
    # @return [Hash] Response containing dubbing job details
    def create(file_io:, filename:, target_languages:, name: nil, **options)
      payload = {
        file: @client.file_part(file_io, filename),
        mode: "automatic",
        target_languages: target_languages,
        name: name
      }.compact.merge(options)

      @client.post_multipart("/v1/dubbing", payload)
    end

    # GET /v1/dubbing/{id}
    # Retrieves dubbing job details
    #
    # @param dubbing_id [String] The dubbing job ID
    # @return [Hash] Dubbing job details
    def get(dubbing_id)
      @client.get("/v1/dubbing/#{dubbing_id}")
    end

    # GET /v1/dubbing
    # Lists dubbing jobs
    #
    # @param params [Hash] Query parameters (dubbing_status, page_size, etc.)
    # @return [Hash] List of dubbing jobs
    def list(params = {})
      @client.get("/v1/dubbing", params)
    end

    # GET /v1/dubbing/{id}/resources
    # Retrieves dubbing resources for editing (if dubbing_studio: true was used)
    #
    # @param dubbing_id [String] The dubbing job ID
    # @return [Hash] Dubbing resources
    def resources(dubbing_id)
      @client.get("/v1/dubbing/#{dubbing_id}/resources")
    end

    private

    attr_reader :client
  end
end
