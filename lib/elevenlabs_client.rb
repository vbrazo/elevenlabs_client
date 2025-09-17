# frozen_string_literal: true

require_relative "elevenlabs_client/version"
require_relative "elevenlabs_client/errors"
require_relative "elevenlabs_client/settings"
require_relative "elevenlabs_client/configuration"
require_relative "elevenlabs_client/http_client"

# Load all endpoint files
require_relative "elevenlabs_client/endpoints/admin/history"
require_relative "elevenlabs_client/endpoints/admin/models"
require_relative "elevenlabs_client/endpoints/admin/pronunciation_dictionaries"
require_relative "elevenlabs_client/endpoints/admin/samples"
require_relative "elevenlabs_client/endpoints/admin/service_accounts"
require_relative "elevenlabs_client/endpoints/admin/service_account_api_keys"
require_relative "elevenlabs_client/endpoints/admin/usage"
require_relative "elevenlabs_client/endpoints/admin/user"
require_relative "elevenlabs_client/endpoints/admin/voice_library"
require_relative "elevenlabs_client/endpoints/admin/webhooks"
require_relative "elevenlabs_client/endpoints/admin/workspace_groups"
require_relative "elevenlabs_client/endpoints/admin/workspace_invites"
require_relative "elevenlabs_client/endpoints/admin/workspace_members"
require_relative "elevenlabs_client/endpoints/admin/workspace_resources"
require_relative "elevenlabs_client/endpoints/admin/workspace_webhooks"

require_relative "elevenlabs_client/endpoints/agents_platform/agents"
require_relative "elevenlabs_client/endpoints/agents_platform/batch_calling"
require_relative "elevenlabs_client/endpoints/agents_platform/conversations"
require_relative "elevenlabs_client/endpoints/agents_platform/knowledge_base"
require_relative "elevenlabs_client/endpoints/agents_platform/mcp_servers"
require_relative "elevenlabs_client/endpoints/agents_platform/llm_usage"
require_relative "elevenlabs_client/endpoints/agents_platform/phone_numbers"
require_relative "elevenlabs_client/endpoints/agents_platform/outbound_calling"
require_relative "elevenlabs_client/endpoints/agents_platform/tools"
require_relative "elevenlabs_client/endpoints/agents_platform/tests"
require_relative "elevenlabs_client/endpoints/agents_platform/test_invocations"
require_relative "elevenlabs_client/endpoints/agents_platform/widgets"
require_relative "elevenlabs_client/endpoints/agents_platform/workspace"

require_relative "elevenlabs_client/endpoints/audio_isolation"
require_relative "elevenlabs_client/endpoints/audio_native"
require_relative "elevenlabs_client/endpoints/dubs"
require_relative "elevenlabs_client/endpoints/forced_alignment"
require_relative "elevenlabs_client/endpoints/music"
require_relative "elevenlabs_client/endpoints/sound_generation"
require_relative "elevenlabs_client/endpoints/speech_to_speech"
require_relative "elevenlabs_client/endpoints/speech_to_text"
require_relative "elevenlabs_client/endpoints/text_to_speech"
require_relative "elevenlabs_client/endpoints/text_to_dialogue"
require_relative "elevenlabs_client/endpoints/text_to_voice"
require_relative "elevenlabs_client/endpoints/voices"
require_relative "elevenlabs_client/endpoints/websocket_text_to_speech"
require_relative "elevenlabs_client/client"

module ElevenlabsClient
  class << self
    # Create a new client instance
    # @param options [Hash] Client configuration options
    # @return [Client] New client instance
    def new(**options)
      Client.new(**options)
    end

    # Configure the client globally
    # @yield [Settings] Global settings object  
    def configure(&block)
      Settings.configure(&block)
    end

    # Get global configuration
    # @return [Configuration] Global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Reset global configuration to defaults
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Get a client using global configuration
    # @return [Client] Client with global configuration
    def client
      new
    end

    # Get version information
    # @return [Hash] Version and build information
    def version_info
      {
        version: VERSION,
        ruby_version: RUBY_VERSION
      }
    end

    # Health check for the library
    # @return [Hash] Health status
    def health_check
      begin
        client_instance = client
        api_health = client_instance.health_check
        
        {
          status: :ok,
          library_version: VERSION,
          api_health: api_health
        }
      rescue => e
        {
          status: :error,
          error: e.message,
          error_class: e.class.name
        }
      end
    end

    # Backward compatibility method
    alias_method :configure_v1, :configure
  end
end
