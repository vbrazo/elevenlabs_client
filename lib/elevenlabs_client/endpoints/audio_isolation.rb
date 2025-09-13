# frozen_string_literal: true

module ElevenlabsClient
  class AudioIsolation
    def initialize(client)
      @client = client
    end

    # POST /v1/audio-isolation
    # Removes background noise from audio
    # Documentation: https://elevenlabs.io/docs/api-reference/audio-isolation
    #
    # @param audio_file [IO, File] The audio file from which vocals/speech will be isolated
    # @param filename [String] Original filename for the audio file
    # @param options [Hash] Optional parameters
    # @option options [String] :file_format Format of input audio ('pcm_s16le_16' or 'other', defaults to 'other')
    # @return [String] Binary audio data with background noise removed
    def isolate(audio_file, filename, **options)
      endpoint = "/v1/audio-isolation"
      
      payload = {
        audio: @client.file_part(audio_file, filename)
      }
      
      # Add optional parameters if provided
      payload[:file_format] = options[:file_format] if options[:file_format]

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/audio-isolation/stream
    # Removes background noise from audio with streaming response
    # Documentation: https://elevenlabs.io/docs/api-reference/audio-isolation/stream
    #
    # @param audio_file [IO, File] The audio file from which vocals/speech will be isolated
    # @param filename [String] Original filename for the audio file
    # @param options [Hash] Optional parameters
    # @option options [String] :file_format Format of input audio ('pcm_s16le_16' or 'other', defaults to 'other')
    # @param block [Proc] Block to handle each chunk of streaming audio data
    # @return [Faraday::Response] Response object for streaming
    def isolate_stream(audio_file, filename, **options, &block)
      endpoint = "/v1/audio-isolation/stream"
      
      payload = {
        audio: @client.file_part(audio_file, filename)
      }
      
      # Add optional parameters if provided
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

    private

    attr_reader :client
  end
end
