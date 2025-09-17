# frozen_string_literal: true

module ElevenlabsClient
  # Configuration management for the ElevenLabs client
  class Configuration
    DEFAULT_BASE_URL = "https://api.elevenlabs.io"
    DEFAULT_API_KEY_ENV = "ELEVENLABS_API_KEY"
    DEFAULT_BASE_URL_ENV = "ELEVENLABS_BASE_URL"

    attr_accessor :api_key, :base_url, :api_key_env, :base_url_env, :timeout, :open_timeout,
                  :retry_count, :retry_delay, :user_agent, :logger, :log_level

    def initialize
      @api_key = nil
      @base_url = DEFAULT_BASE_URL
      @api_key_env = DEFAULT_API_KEY_ENV
      @base_url_env = DEFAULT_BASE_URL_ENV
      @timeout = 30
      @open_timeout = 10
      @retry_count = 3
      @retry_delay = 1
      @user_agent = "ElevenlabsClient/#{ElevenlabsClient::VERSION}"
      @logger = nil
      @log_level = :info
    end

    # Get API key from configuration, environment, or Settings
    def resolved_api_key
      return @api_key if @api_key

      # Try Settings first
      if Settings.properties&.dig(:elevenlabs_api_key)
        return Settings.elevenlabs_api_key
      end

      # Then try environment variable
      env_key = ENV.fetch(@api_key_env) do
        raise AuthenticationError, 
          "#{@api_key_env} environment variable is required but not set and " \
          "Settings.properties[:elevenlabs_api_key] is not configured"
      end

      env_key
    end

    # Get base URL from configuration, environment, or Settings
    def resolved_base_url
      return @base_url if @base_url != DEFAULT_BASE_URL

      # Try Settings first
      if Settings.properties&.dig(:elevenlabs_base_uri)
        return Settings.elevenlabs_base_uri
      end

      # Then try environment variable, with default fallback
      ENV.fetch(@base_url_env, DEFAULT_BASE_URL)
    end

    # Validate configuration
    def validate!
      resolved_api_key # This will raise if API key is missing
      
      unless resolved_base_url.match?(/\Ahttps?:\/\//)
        raise ArgumentError, "Invalid base URL: #{resolved_base_url}"
      end

      unless timeout.is_a?(Numeric) && timeout > 0
        raise ArgumentError, "Timeout must be a positive number"
      end

      unless retry_count.is_a?(Integer) && retry_count >= 0
        raise ArgumentError, "Retry count must be a non-negative integer"
      end
    end

    # Create a hash representation of the configuration
    def to_h
      {
        api_key: api_key ? "[REDACTED]" : nil,
        base_url: resolved_base_url,
        timeout: timeout,
        open_timeout: open_timeout,
        retry_count: retry_count,
        retry_delay: retry_delay,
        user_agent: user_agent,
        log_level: log_level
      }
    end

    # Reset configuration to defaults
    def reset!
      initialize
    end
  end

  class << self
    # Global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the client globally
    def configure
      yield(configuration) if block_given?
      configuration.validate!
      configuration
    end

    # Reset global configuration
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Convenience method to get configured client
    def client
      Client.new
    end
  end
end
