# frozen_string_literal: true

module ElevenlabsClient
  class SpeechToText
    def initialize(client)
      @client = client
    end

    # POST /v1/speech-to-text
    # Transcribe an audio or video file
    # Documentation: https://elevenlabs.io/docs/api-reference/speech-to-text
    #
    # @param model_id [String] The ID of the model to use for transcription
    # @param options [Hash] Optional parameters
    # @option options [IO, File] :file The file to transcribe (required if no cloud_storage_url)
    # @option options [String] :filename Original filename (required if file provided)
    # @option options [String] :cloud_storage_url HTTPS URL of file to transcribe (required if no file)
    # @option options [Boolean] :enable_logging Enable logging (default: true)
    # @option options [String] :language_code ISO-639-1 or ISO-639-3 language code
    # @option options [Boolean] :tag_audio_events Tag audio events like (laughter) (default: true)
    # @option options [Integer] :num_speakers Maximum number of speakers (1-32)
    # @option options [String] :timestamps_granularity Timestamp granularity ("none", "word", "character")
    # @option options [Boolean] :diarize Annotate which speaker is talking (default: false)
    # @option options [Float] :diarization_threshold Diarization threshold (0.1-0.4)
    # @option options [Array] :additional_formats Additional export formats
    # @option options [String] :file_format Input file format ("pcm_s16le_16" or "other")
    # @option options [Boolean] :webhook Send result to webhook (default: false)
    # @option options [String] :webhook_id Specific webhook ID
    # @option options [Float] :temperature Randomness control (0.0-2.0)
    # @option options [Integer] :seed Deterministic sampling seed (0-2147483647)
    # @option options [Boolean] :use_multi_channel Multi-channel processing (default: false)
    # @option options [String, Hash] :webhook_metadata Metadata for webhook
    # @return [Hash] Transcription result or webhook response
    def create(model_id, **options)
      endpoint = "/v1/speech-to-text"
      
      # Build query parameters
      query_params = {}
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      
      # Add query parameters to endpoint if any exist
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end

      # Build multipart payload
      payload = {
        model_id: model_id
      }
      
      # Add file or cloud storage URL (exactly one is required)
      if options[:file] && options[:filename]
        payload[:file] = @client.file_part(options[:file], options[:filename])
      elsif options[:cloud_storage_url]
        payload[:cloud_storage_url] = options[:cloud_storage_url]
      else
        raise ArgumentError, "Either :file with :filename or :cloud_storage_url must be provided"
      end
      
      # Add optional form parameters
      payload[:language_code] = options[:language_code] if options[:language_code]
      payload[:tag_audio_events] = options[:tag_audio_events] unless options[:tag_audio_events].nil?
      payload[:num_speakers] = options[:num_speakers] if options[:num_speakers]
      payload[:timestamps_granularity] = options[:timestamps_granularity] if options[:timestamps_granularity]
      payload[:diarize] = options[:diarize] unless options[:diarize].nil?
      payload[:diarization_threshold] = options[:diarization_threshold] if options[:diarization_threshold]
      payload[:additional_formats] = options[:additional_formats] if options[:additional_formats]
      payload[:file_format] = options[:file_format] if options[:file_format]
      payload[:webhook] = options[:webhook] unless options[:webhook].nil?
      payload[:webhook_id] = options[:webhook_id] if options[:webhook_id]
      payload[:temperature] = options[:temperature] if options[:temperature]
      payload[:seed] = options[:seed] if options[:seed]
      payload[:use_multi_channel] = options[:use_multi_channel] unless options[:use_multi_channel].nil?
      
      # Handle webhook_metadata (can be string or hash)
      if options[:webhook_metadata]
        if options[:webhook_metadata].is_a?(Hash)
          payload[:webhook_metadata] = options[:webhook_metadata].to_json
        else
          payload[:webhook_metadata] = options[:webhook_metadata]
        end
      end

      @client.post_multipart(endpoint, payload)
    end

    # GET /v1/speech-to-text/transcripts/:transcription_id
    # Retrieve a previously generated transcript by its ID
    # Documentation: https://elevenlabs.io/docs/api-reference/speech-to-text/get-transcript
    #
    # @param transcription_id [String] The unique ID of the transcript to retrieve
    # @return [Hash] The transcript data
    def get_transcript(transcription_id)
      endpoint = "/v1/speech-to-text/transcripts/#{transcription_id}"
      @client.get(endpoint)
    end

    # Alias methods for convenience
    alias_method :transcribe, :create
    alias_method :get_transcription, :get_transcript
    alias_method :retrieve_transcript, :get_transcript

    private

    attr_reader :client
  end
end