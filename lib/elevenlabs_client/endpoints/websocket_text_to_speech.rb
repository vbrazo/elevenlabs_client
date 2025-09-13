# frozen_string_literal: true

require 'websocket-client-simple'
require 'json'

module ElevenlabsClient
  class WebSocketTextToSpeech
    def initialize(client)
      @client = client
      @base_url = client.base_url.gsub('https://', 'wss://').gsub('http://', 'ws://')
    end

    # Creates a WebSocket connection for real-time text-to-speech streaming
    # Documentation: https://elevenlabs.io/docs/api-reference/websockets/text-to-speech
    #
    # @param voice_id [String] The unique identifier for the voice
    # @param options [Hash] Optional parameters
    # @option options [String] :model_id The model ID to use
    # @option options [String] :language_code ISO 639-1 language code
    # @option options [Boolean] :enable_logging Enable logging (default: true)
    # @option options [Boolean] :enable_ssml_parsing Enable SSML parsing (default: false)
    # @option options [String] :output_format Output audio format
    # @option options [Integer] :inactivity_timeout Timeout in seconds (default: 20, max: 180)
    # @option options [Boolean] :sync_alignment Include timing data (default: false)
    # @option options [Boolean] :auto_mode Reduce latency mode (default: false)
    # @option options [String] :apply_text_normalization Text normalization ("auto", "on", "off")
    # @option options [Integer] :seed Deterministic sampling seed (0-4294967295)
    # @return [WebSocket::Client::Simple::Client] WebSocket client instance
    def connect_stream_input(voice_id, **options)
      endpoint = "/v1/text-to-speech/#{voice_id}/stream-input"
      
      # Build query parameters
      query_params = {}
      query_params[:model_id] = options[:model_id] if options[:model_id]
      query_params[:language_code] = options[:language_code] if options[:language_code]
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      query_params[:enable_ssml_parsing] = options[:enable_ssml_parsing] unless options[:enable_ssml_parsing].nil?
      query_params[:output_format] = options[:output_format] if options[:output_format]
      query_params[:inactivity_timeout] = options[:inactivity_timeout] if options[:inactivity_timeout]
      query_params[:sync_alignment] = options[:sync_alignment] unless options[:sync_alignment].nil?
      query_params[:auto_mode] = options[:auto_mode] unless options[:auto_mode].nil?
      query_params[:apply_text_normalization] = options[:apply_text_normalization] if options[:apply_text_normalization]
      query_params[:seed] = options[:seed] if options[:seed]
      
      # Add query parameters to endpoint if any
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end
      
      url = "#{@base_url}#{endpoint}"
      headers = { "xi-api-key" => @client.api_key }
      
      WebSocket::Client::Simple.connect(url, headers: headers)
    end

    # Creates a WebSocket connection for multi-context text-to-speech streaming
    # Documentation: https://elevenlabs.io/docs/api-reference/websockets/multi-context
    #
    # @param voice_id [String] The unique identifier for the voice
    # @param options [Hash] Optional parameters (same as connect_stream_input)
    # @return [WebSocket::Client::Simple::Client] WebSocket client instance
    def connect_multi_stream_input(voice_id, **options)
      endpoint = "/v1/text-to-speech/#{voice_id}/multi-stream-input"
      
      # Build query parameters (same as single stream)
      query_params = {}
      query_params[:model_id] = options[:model_id] if options[:model_id]
      query_params[:language_code] = options[:language_code] if options[:language_code]
      query_params[:enable_logging] = options[:enable_logging] unless options[:enable_logging].nil?
      query_params[:enable_ssml_parsing] = options[:enable_ssml_parsing] unless options[:enable_ssml_parsing].nil?
      query_params[:output_format] = options[:output_format] if options[:output_format]
      query_params[:inactivity_timeout] = options[:inactivity_timeout] if options[:inactivity_timeout]
      query_params[:sync_alignment] = options[:sync_alignment] unless options[:sync_alignment].nil?
      query_params[:auto_mode] = options[:auto_mode] unless options[:auto_mode].nil?
      query_params[:apply_text_normalization] = options[:apply_text_normalization] if options[:apply_text_normalization]
      query_params[:seed] = options[:seed] if options[:seed]
      
      # Add query parameters to endpoint if any
      if query_params.any?
        query_string = query_params.map { |k, v| "#{k}=#{v}" }.join("&")
        endpoint += "?#{query_string}"
      end
      
      url = "#{@base_url}#{endpoint}"
      headers = { "xi-api-key" => @client.api_key }
      
      WebSocket::Client::Simple.connect(url, headers: headers)
    end

    # Helper method to send initialization message for single stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param options [Hash] Initialization options
    # @option options [String] :text Initial text (usually a space)
    # @option options [Hash] :voice_settings Voice settings hash
    # @option options [String] :xi_api_key API key (will use client's key if not provided)
    def send_initialize_connection(ws, **options)
      message = {
        text: options[:text] || " ",
        voice_settings: options[:voice_settings] || {},
        xi_api_key: options[:xi_api_key] || @client.api_key
      }
      
      ws.send(message.to_json)
    end

    # Helper method to send text for single stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param text [String] Text to convert to speech
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :try_trigger_generation Try to trigger generation
    # @option options [Hash] :voice_settings Voice settings override
    def send_text(ws, text, **options)
      message = { text: text }
      message[:try_trigger_generation] = options[:try_trigger_generation] unless options[:try_trigger_generation].nil?
      message[:voice_settings] = options[:voice_settings] if options[:voice_settings]
      
      ws.send(message.to_json)
    end

    # Helper method to close connection for single stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    def send_close_connection(ws)
      message = { text: "" }
      ws.send(message.to_json)
    end

    # Helper method to send initialization message for multi-context stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    # @param options [Hash] Initialization options
    def send_initialize_connection_multi(ws, context_id, **options)
      message = {
        text: options[:text] || " ",
        voice_settings: options[:voice_settings] || {},
        context_id: context_id
      }
      
      ws.send(message.to_json)
    end

    # Helper method to initialize a new context in multi-stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    # @param options [Hash] Context options
    def send_initialize_context(ws, context_id, **options)
      message = {
        context_id: context_id,
        voice_settings: options[:voice_settings] || {}
      }
      message[:model_id] = options[:model_id] if options[:model_id]
      message[:language_code] = options[:language_code] if options[:language_code]
      
      ws.send(message.to_json)
    end

    # Helper method to send text for multi-context stream
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    # @param text [String] Text to convert to speech
    # @param options [Hash] Optional parameters
    def send_text_multi(ws, context_id, text, **options)
      message = {
        text: text,
        context_id: context_id
      }
      message[:flush] = options[:flush] unless options[:flush].nil?
      
      ws.send(message.to_json)
    end

    # Helper method to flush a context
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    def send_flush_context(ws, context_id)
      message = {
        context_id: context_id,
        flush: true
      }
      
      ws.send(message.to_json)
    end

    # Helper method to close a specific context
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    def send_close_context(ws, context_id)
      message = {
        context_id: context_id,
        close_context: true
      }
      
      ws.send(message.to_json)
    end

    # Helper method to keep a context alive
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    # @param context_id [String] Context identifier
    def send_keep_context_alive(ws, context_id)
      message = {
        context_id: context_id,
        keep_context_alive: true
      }
      
      ws.send(message.to_json)
    end

    # Helper method to close the entire socket
    # @param ws [WebSocket::Client::Simple::Client] WebSocket client
    def send_close_socket(ws)
      message = { close_socket: true }
      ws.send(message.to_json)
    end

    # Convenience method to create a complete streaming session
    # @param voice_id [String] The unique identifier for the voice
    # @param text_chunks [Array<String>] Array of text chunks to stream
    # @param options [Hash] Connection and voice options
    # @param block [Proc] Block to handle audio chunks
    def stream_text_to_speech(voice_id, text_chunks, **options, &block)
      ws = connect_stream_input(voice_id, **options)
      
      ws.on :open do
        # Initialize connection
        send_initialize_connection(ws, **options)
        
        # Send text chunks
        text_chunks.each_with_index do |chunk, index|
          send_text(ws, chunk, try_trigger_generation: (index == text_chunks.length - 1))
        end
        
        # Close connection
        send_close_connection(ws)
      end
      
      ws.on :message do |msg|
        data = JSON.parse(msg.data)
        if data['audio'] && block_given?
          # Decode base64 audio and yield to block
          audio_data = Base64.decode64(data['audio'])
          block.call(audio_data, data)
        end
      end
      
      ws.on :error do |e|
        raise APIError, "WebSocket error: #{e.message}"
      end
      
      ws
    end

    # Alias methods for convenience
    alias_method :connect_single_stream, :connect_stream_input
    alias_method :connect_multi_context, :connect_multi_stream_input

    private

    attr_reader :client
  end
end
