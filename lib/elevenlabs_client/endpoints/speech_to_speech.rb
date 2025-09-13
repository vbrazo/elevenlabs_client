# frozen_string_literal: true

module ElevenlabsClient
  class SpeechToSpeech
    def initialize(client)
      @client = client
    end

    # POST /v1/speech-to-speech/:voice_id
    # Transform audio from one voice to another. Maintain full control over emotion, timing and delivery.
    # Documentation: https://elevenlabs.io/docs/api-reference/speech-to-speech
    #
    # @param voice_id [String] ID of the voice to be used
    # @param audio_file [IO, File] The audio file which holds the content and emotion
    # @param filename [String] Original filename for the audio file
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :enable_logging Enable logging (default: true)
    # @option options [Integer] :optimize_streaming_latency Latency optimization level (0-4, deprecated)
    # @option options [String] :output_format Output format (default: "mp3_44100_128")
    # @option options [String] :model_id Model identifier (default: "eleven_english_sts_v2")
    # @option options [String] :voice_settings JSON encoded voice settings
    # @option options [Integer] :seed Deterministic sampling seed (0-4294967295)
    # @option options [Boolean] :remove_background_noise Remove background noise (default: false)
    # @option options [String] :file_format Input file format ("pcm_s16le_16" or "other")
    # @return [String] Binary audio data
    def convert(voice_id, audio_file, filename, **options)
      endpoint = "/v1/speech-to-speech/#{voice_id}"
      
      # Build query parameters
      query_params = {}
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      query_params[:optimize_streaming_latency] = options[:optimize_streaming_latency] if options[:optimize_streaming_latency]
      query_params[:output_format] = options[:output_format] if options[:output_format]
      
      # Add query parameters to endpoint if any exist
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end

      # Build multipart payload
      payload = {
        audio: @client.file_part(audio_file, filename)
      }
      
      # Add optional form parameters
      payload[:model_id] = options[:model_id] if options[:model_id]
      payload[:voice_settings] = options[:voice_settings] if options[:voice_settings]
      payload[:seed] = options[:seed] if options[:seed]
      payload[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?
      payload[:file_format] = options[:file_format] if options[:file_format]

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/speech-to-speech/:voice_id/stream
    # Stream audio from one voice to another. Maintain full control over emotion, timing and delivery.
    # Documentation: https://elevenlabs.io/docs/api-reference/speech-to-speech/stream
    #
    # @param voice_id [String] ID of the voice to be used
    # @param audio_file [IO, File] The audio file which holds the content and emotion
    # @param filename [String] Original filename for the audio file
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :enable_logging Enable logging (default: true)
    # @option options [Integer] :optimize_streaming_latency Latency optimization level (0-4, deprecated)
    # @option options [String] :output_format Output format (default: "mp3_44100_128")
    # @option options [String] :model_id Model identifier (default: "eleven_english_sts_v2")
    # @option options [String] :voice_settings JSON encoded voice settings
    # @option options [Integer] :seed Deterministic sampling seed (0-4294967295)
    # @option options [Boolean] :remove_background_noise Remove background noise (default: false)
    # @option options [String] :file_format Input file format ("pcm_s16le_16" or "other")
    # @param block [Proc] Block to handle each chunk of streaming audio data
    # @return [Faraday::Response] Response object for streaming
    def convert_stream(voice_id, audio_file, filename, **options, &block)
      endpoint = "/v1/speech-to-speech/#{voice_id}/stream"
      
      # Build query parameters
      query_params = {}
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      query_params[:optimize_streaming_latency] = options[:optimize_streaming_latency] if options[:optimize_streaming_latency]
      query_params[:output_format] = options[:output_format] if options[:output_format]
      
      # Add query parameters to endpoint if any exist
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end

      # Build multipart payload
      payload = {
        audio: @client.file_part(audio_file, filename)
      }
      
      # Add optional form parameters
      payload[:model_id] = options[:model_id] if options[:model_id]
      payload[:voice_settings] = options[:voice_settings] if options[:voice_settings]
      payload[:seed] = options[:seed] if options[:seed]
      payload[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?
      payload[:file_format] = options[:file_format] if options[:file_format]

      # Use streaming multipart request
      response = @client.instance_variable_get(:@conn).post(endpoint) do |req|
        req.headers["xi-api-key"] = @client.api_key
        req.body = payload
        
        # Set up streaming callback if block provided
        if block_given?
          req.options.on_data = proc do |chunk, _|
            block.call(chunk)
          end
        end
      end

      @client.send(:handle_response, response)
    end

    # Alias methods for convenience
    alias_method :voice_changer, :convert
    alias_method :voice_changer_stream, :convert_stream

    private

    attr_reader :client
  end
end