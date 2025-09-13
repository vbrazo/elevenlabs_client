# frozen_string_literal: true

module ElevenlabsClient
  class AudioNative
    def initialize(client)
      @client = client
    end

    # POST /v1/audio-native
    # Creates Audio Native enabled project, optionally starts conversion and returns project ID and embeddable HTML snippet
    # Documentation: https://elevenlabs.io/docs/api-reference/audio-native/create
    #
    # @param name [String] Project name
    # @param options [Hash] Optional parameters
    # @option options [String] :image Image URL used in the player (deprecated)
    # @option options [String] :author Author used in the player
    # @option options [String] :title Title used in the player
    # @option options [Boolean] :small Whether to use small player (deprecated, defaults to false)
    # @option options [String] :text_color Text color used in the player
    # @option options [String] :background_color Background color used in the player
    # @option options [Integer] :sessionization Minutes to persist session (deprecated, defaults to 0)
    # @option options [String] :voice_id Voice ID used to voice the content
    # @option options [String] :model_id TTS Model ID used in the player
    # @option options [IO, File] :file Text or HTML input file containing article content
    # @option options [String] :filename Original filename for the file
    # @option options [Boolean] :auto_convert Whether to auto convert project to audio (defaults to false)
    # @option options [String] :apply_text_normalization Text normalization mode ('auto', 'on', 'off', 'apply_english')
    # @return [Hash] JSON response containing project_id, converting status, and html_snippet
    def create(name, **options)
      endpoint = "/v1/audio-native"
      
      payload = { name: name }
      
      # Add optional parameters if provided
      payload[:image] = options[:image] if options[:image]
      payload[:author] = options[:author] if options[:author]
      payload[:title] = options[:title] if options[:title]
      payload[:small] = options[:small] unless options[:small].nil?
      payload[:text_color] = options[:text_color] if options[:text_color]
      payload[:background_color] = options[:background_color] if options[:background_color]
      payload[:sessionization] = options[:sessionization] if options[:sessionization]
      payload[:voice_id] = options[:voice_id] if options[:voice_id]
      payload[:model_id] = options[:model_id] if options[:model_id]
      payload[:auto_convert] = options[:auto_convert] unless options[:auto_convert].nil?
      payload[:apply_text_normalization] = options[:apply_text_normalization] if options[:apply_text_normalization]
      
      # Add file if provided
      if options[:file] && options[:filename]
        payload[:file] = @client.file_part(options[:file], options[:filename])
      end

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/audio-native/:project_id/content
    # Updates content for the specific AudioNative Project
    # Documentation: https://elevenlabs.io/docs/api-reference/audio-native/update
    #
    # @param project_id [String] The ID of the project to be used
    # @param options [Hash] Optional parameters
    # @option options [IO, File] :file Text or HTML input file containing article content
    # @option options [String] :filename Original filename for the file
    # @option options [Boolean] :auto_convert Whether to auto convert project to audio (defaults to false)
    # @option options [Boolean] :auto_publish Whether to auto publish after conversion (defaults to false)
    # @return [Hash] JSON response containing project_id, converting, publishing status, and html_snippet
    def update_content(project_id, **options)
      endpoint = "/v1/audio-native/#{project_id}/content"
      
      payload = {}
      
      # Add optional parameters if provided
      payload[:auto_convert] = options[:auto_convert] unless options[:auto_convert].nil?
      payload[:auto_publish] = options[:auto_publish] unless options[:auto_publish].nil?
      
      # Add file if provided
      if options[:file] && options[:filename]
        payload[:file] = @client.file_part(options[:file], options[:filename])
      end

      @client.post_multipart(endpoint, payload)
    end

    # GET /v1/audio-native/:project_id/settings
    # Get player settings for the specific project
    # Documentation: https://elevenlabs.io/docs/api-reference/audio-native/settings
    #
    # @param project_id [String] The ID of the Studio project
    # @return [Hash] JSON response containing enabled status, snapshot_id, and settings
    def get_settings(project_id)
      endpoint = "/v1/audio-native/#{project_id}/settings"
      @client.get(endpoint)
    end

    # Alias methods for convenience
    alias_method :create_project, :create
    alias_method :update_project_content, :update_content
    alias_method :project_settings, :get_settings

    private

    attr_reader :client
  end
end
