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

    # DELETE /v1/dubbing/{id}
    # Deletes a dubbing project
    #
    # @param dubbing_id [String] The dubbing job ID
    # @return [Hash] Response with status
    def delete(dubbing_id)
      @client.delete("/v1/dubbing/#{dubbing_id}")
    end

    # GET /v1/dubbing/resource/{dubbing_id}
    # Gets dubbing resource with detailed information including segments, speakers, etc.
    #
    # @param dubbing_id [String] The dubbing job ID
    # @return [Hash] Detailed dubbing resource information
    def get_resource(dubbing_id)
      @client.get("/v1/dubbing/resource/#{dubbing_id}")
    end

    # POST /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/segment
    # Creates a new segment in dubbing resource
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param speaker_id [String] The speaker ID
    # @param start_time [Float] Start time of the segment
    # @param end_time [Float] End time of the segment
    # @param text [String, nil] Optional text for the segment
    # @param translations [Hash, nil] Optional translations map
    # @return [Hash] Response with version and new segment ID
    def create_segment(dubbing_id:, speaker_id:, start_time:, end_time:, text: nil, translations: nil)
      payload = {
        start_time: start_time,
        end_time: end_time,
        text: text,
        translations: translations
      }.compact

      @client.post("/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment", payload)
    end

    # DELETE /v1/dubbing/resource/{dubbing_id}/segment/{segment_id}
    # Deletes a single segment from the dubbing
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param segment_id [String] The segment ID
    # @return [Hash] Response with version
    def delete_segment(dubbing_id, segment_id)
      @client.delete("/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}")
    end

    # PATCH /v1/dubbing/resource/{dubbing_id}/segment/{segment_id}/{language}
    # Updates a single segment with new text and/or start/end times
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param segment_id [String] The segment ID
    # @param language [String] The language ID
    # @param start_time [Float, nil] Optional new start time
    # @param end_time [Float, nil] Optional new end time
    # @param text [String, nil] Optional new text
    # @return [Hash] Response with version
    def update_segment(dubbing_id:, segment_id:, language:, start_time: nil, end_time: nil, text: nil)
      payload = {
        start_time: start_time,
        end_time: end_time,
        text: text
      }.compact

      @client.patch("/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}/#{language}", payload)
    end

    # POST /v1/dubbing/resource/{dubbing_id}/transcribe
    # Regenerates transcriptions for specified segments
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param segments [Array<String>] List of segment IDs to transcribe
    # @return [Hash] Response with version
    def transcribe_segment(dubbing_id, segments)
      payload = { segments: segments }
      @client.post("/v1/dubbing/resource/#{dubbing_id}/transcribe", payload)
    end

    # POST /v1/dubbing/resource/{dubbing_id}/translate
    # Regenerates translations for specified segments/languages
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param segments [Array<String>] List of segment IDs to translate
    # @param languages [Array<String>, nil] Optional list of languages to translate
    # @return [Hash] Response with version
    def translate_segment(dubbing_id, segments, languages = nil)
      payload = {
        segments: segments,
        languages: languages
      }.compact

      @client.post("/v1/dubbing/resource/#{dubbing_id}/translate", payload)
    end

    # POST /v1/dubbing/resource/{dubbing_id}/dub
    # Regenerates dubs for specified segments/languages
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param segments [Array<String>] List of segment IDs to dub
    # @param languages [Array<String>, nil] Optional list of languages to dub
    # @return [Hash] Response with version
    def dub_segment(dubbing_id, segments, languages = nil)
      payload = {
        segments: segments,
        languages: languages
      }.compact

      @client.post("/v1/dubbing/resource/#{dubbing_id}/dub", payload)
    end

    # POST /v1/dubbing/resource/{dubbing_id}/render/{language}
    # Renders the output media for a language
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param language [String] The language to render
    # @param render_type [String] The type of render (mp4, aac, mp3, wav, aaf, tracks_zip, clips_zip)
    # @param normalize_volume [Boolean, nil] Whether to normalize volume (defaults to false)
    # @return [Hash] Response with version and render_id
    def render_project(dubbing_id:, language:, render_type:, normalize_volume: nil)
      payload = {
        render_type: render_type,
        normalize_volume: normalize_volume
      }.compact

      @client.post("/v1/dubbing/resource/#{dubbing_id}/render/#{language}", payload)
    end

    # PATCH /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}
    # Updates speaker metadata such as voice
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param speaker_id [String] The speaker ID
    # @param voice_id [String, nil] Voice ID from library or 'track-clone'/'clip-clone'
    # @param languages [Array<String>, nil] Languages to apply changes to
    # @return [Hash] Response with version
    def update_speaker(dubbing_id:, speaker_id:, voice_id: nil, languages: nil)
      payload = {
        voice_id: voice_id,
        languages: languages
      }.compact

      @client.patch("/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}", payload)
    end

    # GET /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/similar-voices
    # Gets similar voices for a speaker
    #
    # @param dubbing_id [String] The dubbing job ID
    # @param speaker_id [String] The speaker ID
    # @return [Hash] Response with list of similar voices
    def get_similar_voices(dubbing_id, speaker_id)
      @client.get("/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/similar-voices")
    end

    private

    attr_reader :client
  end
end
