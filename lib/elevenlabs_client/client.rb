# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module ElevenlabsClient
  class Client
    DEFAULT_BASE_URL = "https://api.elevenlabs.io"

    attr_reader :base_url, :api_key, :dubs, :text_to_speech, :text_to_speech_stream

    def initialize(api_key: nil, base_url: nil, api_key_env: "ELEVENLABS_API_KEY", base_url_env: "ELEVENLABS_BASE_URL")
      @api_key = api_key || fetch_api_key(api_key_env)
      @base_url = base_url || fetch_base_url(base_url_env)
      @conn = build_connection
      @dubs = Dubs.new(self)
      @text_to_speech = TextToSpeech.new(self)
      @text_to_speech_stream = TextToSpeechStream.new(self)
    end

    # Makes an authenticated GET request
    # @param path [String] API endpoint path
    # @param params [Hash] Query parameters
    # @return [Hash] Response body
    def get(path, params = {})
      response = @conn.get(path, params) do |req|
        req.headers["xi-api-key"] = api_key
      end

      handle_response(response)
    end

    # Makes an authenticated POST request
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @return [Hash] Response body
    def post(path, body = nil)
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.body = body if body
      end

      handle_response(response)
    end

    # Makes an authenticated multipart POST request
    # @param path [String] API endpoint path
    # @param payload [Hash] Multipart payload
    # @return [Hash] Response body
    def post_multipart(path, payload)
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.body = payload
      end

      handle_response(response)
    end

    # Makes an authenticated POST request expecting binary response
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @return [String] Binary response body
    def post_binary(path, body = nil)
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json if body
      end

      handle_binary_response(response)
    end

    # Makes an authenticated POST request with custom headers
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @param custom_headers [Hash] Additional headers
    # @return [String] Response body (binary or text)
    def post_with_custom_headers(path, body = nil, custom_headers = {})
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        custom_headers.each { |key, value| req.headers[key] = value }
        req.body = body.to_json if body
      end

      # For streaming/binary responses, return raw body
      if custom_headers["Accept"]&.include?("audio") || custom_headers["Transfer-Encoding"] == "chunked"
        handle_binary_response(response)
      else
        handle_response(response)
      end
    end

    # Makes an authenticated POST request with streaming response
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @param block [Proc] Block to handle each chunk
    # @return [Faraday::Response] Response object
    def post_streaming(path, body = nil, &block)
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "audio/mpeg"
        req.body = body.to_json if body
        
        # Set up streaming callback
        req.options.on_data = proc do |chunk, _|
          block.call(chunk) if block_given?
        end
      end

      handle_streaming_response(response)
    end

    # Helper method to create Faraday::Multipart::FilePart
    # @param file_io [IO] File IO object
    # @param filename [String] Original filename
    # @return [Faraday::Multipart::FilePart]
    def file_part(file_io, filename)
      Faraday::Multipart::FilePart.new(file_io, mime_for(filename), filename)
    end

    private

    def fetch_api_key(env_key = "ELEVENLABS_API_KEY")
      # First try Settings, then ENV, then raise error
      if Settings.properties&.dig(:elevenlabs_api_key)
        Settings.elevenlabs_api_key
      else
        ENV.fetch(env_key) do
          raise AuthenticationError, "#{env_key} environment variable is required but not set and Settings.properties[:elevenlabs_api_key] is not configured"
        end
      end
    end

    def fetch_base_url(env_key = "ELEVENLABS_BASE_URL")
      # First try Settings, then ENV, then default
      if Settings.properties&.dig(:elevenlabs_base_uri)
        Settings.elevenlabs_base_uri
      else
        ENV.fetch(env_key, DEFAULT_BASE_URL)
      end
    end

    def build_connection
      Faraday.new(url: base_url) do |f|
        f.request :multipart
        f.request :url_encoded
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 401
        raise AuthenticationError, "Invalid API key or authentication failed"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 400..499
        raise ValidationError, response.body.inspect
      else
        raise APIError, "API request failed with status #{response.status}: #{response.body.inspect}"
      end
    end

    def handle_binary_response(response)
      case response.status
      when 200..299
        response.body
      when 401
        raise AuthenticationError, "Invalid API key or authentication failed"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 400..499
        raise ValidationError, "API request failed with status #{response.status}"
      else
        raise APIError, "API request failed with status #{response.status}"
      end
    end

    def handle_streaming_response(response)
      case response.status
      when 200..299
        response
      when 401
        raise AuthenticationError, "Invalid API key or authentication failed"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 400..499
        raise ValidationError, "API request failed with status #{response.status}"
      else
        raise APIError, "API request failed with status #{response.status}"
      end
    end

    def mime_for(filename)
      ext = File.extname(filename).downcase
      case ext
      when ".mp4"  then "video/mp4"
      when ".mov"  then "video/quicktime"
      when ".avi"  then "video/x-msvideo"
      when ".mkv"  then "video/x-matroska"
      when ".mp3"  then "audio/mpeg"
      when ".wav"  then "audio/wav"
      when ".flac" then "audio/flac"
      when ".m4a"  then "audio/mp4"
      else "application/octet-stream"
      end
    end
  end
end
