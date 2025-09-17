# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"

module ElevenlabsClient
  # HTTP client wrapper that handles all HTTP communication
  # Separates HTTP concerns from business logic
  class HttpClient
    DEFAULT_BASE_URL = "https://api.elevenlabs.io"

    attr_reader :base_url, :api_key

    def initialize(api_key:, base_url: DEFAULT_BASE_URL)
      @api_key = api_key
      @base_url = base_url
      @conn = build_connection
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
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json if body
      end

      handle_response(response)
    end

    # Makes an authenticated DELETE request
    # @param path [String] API endpoint path
    # @return [Hash] Response body
    def delete(path)
      response = @conn.delete(path) do |req|
        req.headers["xi-api-key"] = api_key
      end

      handle_response(response)
    end

    # Makes an authenticated DELETE request with JSON body
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @return [Hash] Response body
    def delete_with_body(path, body = nil)
      response = @conn.delete(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json if body
      end

      handle_response(response)
    end

    # Makes an authenticated PATCH request
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @return [Hash] Response body
    def patch(path, body = nil)
      response = @conn.patch(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json if body
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

    # Makes an authenticated GET request expecting binary response
    # @param path [String] API endpoint path
    # @return [String] Binary response body
    def get_binary(path)
      response = @conn.get(path) do |req|
        req.headers["xi-api-key"] = api_key
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

      handle_response(response)
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
        handle_response(response)
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

      handle_response(response)
    end

    # Makes an authenticated GET request with streaming response
    # @param path [String] API endpoint path
    # @param block [Proc] Block to handle each chunk
    # @return [Faraday::Response] Response object
    def get_streaming(path, &block)
      response = @conn.get(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Accept"] = "audio/mpeg"
        
        # Set up streaming callback
        req.options.on_data = proc do |chunk, _|
          block.call(chunk) if block_given?
        end
      end

      handle_response(response)
    end

    # Makes an authenticated POST request with streaming response for timestamp data
    # @param path [String] API endpoint path
    # @param body [Hash, nil] Request body
    # @param block [Proc] Block to handle each JSON chunk with timestamps
    # @return [Faraday::Response] Response object
    def post_streaming_with_timestamps(path, body = nil, &block)
      buffer = ""
      
      response = @conn.post(path) do |req|
        req.headers["xi-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json if body
        
        # Set up streaming callback for JSON chunks
        req.options.on_data = proc do |chunk, _|
          if block_given?
            buffer += chunk
            
            # Process complete JSON objects
            while buffer.include?("\n")
              line, buffer = buffer.split("\n", 2)
              next if line.strip.empty?
              
              begin
                json_data = JSON.parse(line)
                block.call(json_data)
              rescue JSON::ParserError
                # Skip malformed JSON lines
                next
              end
            end
          end
        end
      end

      handle_response(response)
    end

    # Helper method to create Faraday::Multipart::FilePart
    # @param file_io [IO] File IO object
    # @param filename [String] Original filename
    # @return [Faraday::Multipart::FilePart]
    def file_part(file_io, filename)
      Faraday::Multipart::FilePart.new(file_io, mime_for(filename), filename)
    end

    private

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
      when 400
        error_message = extract_error_message(response.body)
        raise BadRequestError, error_message.empty? ? "Bad request - invalid parameters" : error_message
      when 401
        error_message = extract_error_message(response.body)
        raise AuthenticationError, error_message.empty? ? "Invalid API key or authentication failed" : error_message
      when 402
        error_message = extract_error_message(response.body)
        raise PaymentRequiredError, error_message.empty? ? "Payment required" : error_message
      when 403
        error_message = extract_error_message(response.body)
        raise ForbiddenError, error_message.empty? ? "Access forbidden" : error_message
      when 404
        error_message = extract_error_message(response.body)
        raise NotFoundError, error_message.empty? ? "Resource not found" : error_message
      when 408
        error_message = extract_error_message(response.body)
        raise TimeoutError, error_message.empty? ? "Request timeout" : error_message
      when 422
        error_message = extract_error_message(response.body)
        raise UnprocessableEntityError, error_message.empty? ? "Unprocessable entity - invalid data" : error_message
      when 429
        error_message = extract_error_message(response.body)
        raise RateLimitError, error_message.empty? ? "Rate limit exceeded" : error_message
      when 503
        error_message = extract_error_message(response.body)
        raise ServiceUnavailableError, error_message.empty? ? "Service unavailable" : error_message
      when 400..499
        error_message = extract_error_message(response.body)
        raise ValidationError, error_message.empty? ? "Client error occurred with status #{response.status}" : error_message
      else
        error_message = extract_error_message(response.body)
        raise APIError, error_message.empty? ? "API request failed with status #{response.status}" : error_message
      end
    end

    def extract_error_message(response_body)
      return "" if response_body.nil? || response_body.empty?
      
      # Handle non-string response bodies
      body_str = response_body.is_a?(String) ? response_body : response_body.to_s
      
      begin
        error_info = JSON.parse(body_str)
        
        # Try different common error message fields
        message = error_info["detail"] || 
                 error_info["message"] || 
                 error_info["error"] ||
                 error_info["errors"]
        
        # Handle nested detail objects
        if message.is_a?(Hash)
          message = message["message"] || message.to_s
        elsif message.is_a?(Array)
          message = message.first.to_s
        end
        
        message.to_s
      rescue JSON::ParserError, TypeError
        # If not JSON or can't be parsed, return the raw body (truncated if too long)
        body_str.length > 200 ? "#{body_str[0..200]}..." : body_str
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
