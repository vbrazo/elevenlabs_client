# frozen_string_literal: true

module ElevenlabsClient
  # Main client class for the ElevenLabs API
  # Refactored for better maintainability and architecture
  class Client
    attr_reader :http_client

    def initialize(api_key: nil, base_url: nil, **options)
      # Create configuration
      configuration = Configuration.new
      configuration.api_key = api_key if api_key
      configuration.base_url = base_url if base_url
      
      # Apply any additional options
      options.each do |key, value|
        configuration.public_send("#{key}=", value) if configuration.respond_to?("#{key}=")
      end

      # Validate configuration
      configuration.validate!

      # Create HTTP client
      @http_client = HttpClient.new(
        api_key: configuration.resolved_api_key,
        base_url: configuration.resolved_base_url
      )

      # Initialize endpoints directly for now (simpler approach)
      initialize_endpoints
    end

    private

    def initialize_endpoints
      # Core TTS/Audio endpoints
      @dubs = Dubs.new(self)
      @text_to_speech = TextToSpeech.new(self)
      @text_to_dialogue = TextToDialogue.new(self)
      @sound_generation = SoundGeneration.new(self)
      @text_to_voice = TextToVoice.new(self)
      @voices = Voices.new(self)
      @music = Endpoints::Music.new(self)
      @audio_isolation = AudioIsolation.new(self)
      @audio_native = AudioNative.new(self)
      @forced_alignment = ForcedAlignment.new(self)
      @speech_to_speech = SpeechToSpeech.new(self)
      @speech_to_text = SpeechToText.new(self)
      @websocket_text_to_speech = WebSocketTextToSpeech.new(self)

      # Admin endpoints
      @models = Admin::Models.new(self)
      @history = Admin::History.new(self)
      @usage = Admin::Usage.new(self)
      @user = Admin::User.new(self)
      @voice_library = Admin::VoiceLibrary.new(self)
      @samples = Admin::Samples.new(self)
      @pronunciation_dictionaries = Admin::PronunciationDictionaries.new(self)
      @service_accounts = Admin::ServiceAccounts.new(self)
      @webhooks = Admin::Webhooks.new(self)
      @workspace_groups = Admin::WorkspaceGroups.new(self)
      @workspace_invites = Admin::WorkspaceInvites.new(self)
      @workspace_members = Admin::WorkspaceMembers.new(self)
      @workspace_resources = Admin::WorkspaceResources.new(self)
      @workspace_webhooks = Admin::WorkspaceWebhooks.new(self)
      @service_account_api_keys = Admin::ServiceAccountApiKeys.new(self)

      # Agents Platform endpoints
      @agents = Endpoints::AgentsPlatform::Agents.new(self)
      @conversations = Endpoints::AgentsPlatform::Conversations.new(self)
      @tools = Endpoints::AgentsPlatform::Tools.new(self)
      @knowledge_base = Endpoints::AgentsPlatform::KnowledgeBase.new(self)
      @tests = Endpoints::AgentsPlatform::Tests.new(self)
      @test_invocations = Endpoints::AgentsPlatform::TestInvocations.new(self)
      @phone_numbers = Endpoints::AgentsPlatform::PhoneNumbers.new(self)
      @widgets = Endpoints::AgentsPlatform::Widgets.new(self)
      @outbound_calling = Endpoints::AgentsPlatform::OutboundCalling.new(self)
      @batch_calling = Endpoints::AgentsPlatform::BatchCalling.new(self)
      @workspace = Endpoints::AgentsPlatform::Workspace.new(self)
      @llm_usage = Endpoints::AgentsPlatform::LlmUsage.new(self)
      @mcp_servers = Endpoints::AgentsPlatform::McpServers.new(self)
    end

    public

    # Endpoint accessors
    attr_reader :dubs, :text_to_speech, :text_to_dialogue, :sound_generation, :text_to_voice, 
                :voices, :music, :audio_isolation, :audio_native, :forced_alignment, 
                :speech_to_speech, :speech_to_text, :websocket_text_to_speech,
                :models, :history, :usage, :user, :voice_library, :samples, 
                :pronunciation_dictionaries, :service_accounts, :webhooks,
                :workspace_groups, :workspace_invites, :workspace_members, :workspace_resources,
                :workspace_webhooks, :service_account_api_keys,
                :agents, :conversations, :tools, :knowledge_base, :tests, :test_invocations,
                :phone_numbers, :widgets, :outbound_calling, :batch_calling, :workspace,
                :llm_usage, :mcp_servers

    # Delegate HTTP methods to http_client for backward compatibility
    def get(path, params = {})
      http_client.get(path, params)
    end

    def post(path, body = nil)
      http_client.post(path, body)
    end

    def patch(path, body = nil)
      http_client.patch(path, body)
    end

    def delete(path)
      http_client.delete(path)
    end

    def delete_with_body(path, body = nil)
      http_client.delete_with_body(path, body)
    end

    def post_multipart(path, payload)
      http_client.post_multipart(path, payload)
    end

    def get_binary(path)
      http_client.get_binary(path)
    end

    def post_binary(path, body = nil)
      http_client.post_binary(path, body)
    end

    def post_with_custom_headers(path, body = nil, custom_headers = {})
      http_client.post_with_custom_headers(path, body, custom_headers)
    end

    def post_streaming(path, body = nil, &block)
      http_client.post_streaming(path, body, &block)
    end

    def get_streaming(path, &block)
      http_client.get_streaming(path, &block)
    end

    def post_streaming_with_timestamps(path, body = nil, &block)
      http_client.post_streaming_with_timestamps(path, body, &block)
    end

    def file_part(file_io, filename)
      http_client.file_part(file_io, filename)
    end

    # Convenience accessors for backward compatibility
    def base_url
      http_client.base_url
    end

    def api_key
      http_client.api_key
    end

    # Debug information
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} " \
      "base_url=#{base_url.inspect} " \
      "endpoints=#{@endpoints.keys.inspect}>"
    end

    # Health check method
    def health_check
      begin
        # Try a simple API call to verify connectivity
        get("/v1/models")
        { status: :ok, message: "Client is healthy" }
      rescue => e
        { status: :error, message: e.message, error_class: e.class.name }
      end
    end

  end
end
