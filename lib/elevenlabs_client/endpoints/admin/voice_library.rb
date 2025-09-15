# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class VoiceLibrary
      def initialize(client)
        @client = client
      end

      # GET /v1/shared-voices
      # Retrieves a list of shared voices
      # Documentation: https://elevenlabs.io/docs/api-reference/shared-voices/get-shared-voices
      #
      # @param page_size [Integer] How many shared voices to return at maximum. Cannot exceed 100, defaults to 30
      # @param category [String] Voice category used for filtering ("professional", "famous", "high_quality")
      # @param gender [String, nil] Gender used for filtering
      # @param age [String, nil] Age used for filtering
      # @param accent [String, nil] Accent used for filtering
      # @param language [String, nil] Language used for filtering
      # @param locale [String, nil] Locale used for filtering
      # @param search [String, nil] Search term used for filtering
      # @param use_cases [Array<String>, nil] Use-case used for filtering
      # @param descriptives [Array<String>, nil] Descriptive terms used for filtering
      # @param featured [Boolean] Filter featured voices (defaults to false)
      # @param min_notice_period_days [Integer, nil] Filter voices with a minimum notice period
      # @param include_custom_rates [Boolean, nil] Include/exclude voices with custom rates
      # @param include_live_moderated [Boolean, nil] Include/exclude voices that are live moderated
      # @param reader_app_enabled [Boolean] Filter voices that are enabled for the reader app (defaults to false)
      # @param owner_id [String, nil] Filter voices by public owner ID
      # @param sort [String, nil] Sort criteria
      # @param page [Integer] Page number (defaults to 0)
      # @return [Hash] The JSON response containing voices array and pagination info
      def get_shared_voices(page_size: nil, category: nil, gender: nil, age: nil, accent: nil, language: nil, locale: nil, search: nil, use_cases: nil, descriptives: nil, featured: nil, min_notice_period_days: nil, include_custom_rates: nil, include_live_moderated: nil, reader_app_enabled: nil, owner_id: nil, sort: nil, page: nil)
        endpoint = "/v1/shared-voices"
        
        params = {}
        params[:page_size] = page_size if page_size
        params[:category] = category if category
        params[:gender] = gender if gender
        params[:age] = age if age
        params[:accent] = accent if accent
        params[:language] = language if language
        params[:locale] = locale if locale
        params[:search] = search if search
        params[:use_cases] = use_cases if use_cases
        params[:descriptives] = descriptives if descriptives
        params[:featured] = featured unless featured.nil?
        params[:min_notice_period_days] = min_notice_period_days if min_notice_period_days
        params[:include_custom_rates] = include_custom_rates unless include_custom_rates.nil?
        params[:include_live_moderated] = include_live_moderated unless include_live_moderated.nil?
        params[:reader_app_enabled] = reader_app_enabled unless reader_app_enabled.nil?
        params[:owner_id] = owner_id if owner_id
        params[:sort] = sort if sort
        params[:page] = page if page
        
        @client.get(endpoint, params)
      end

      # POST /v1/voices/add/:public_user_id/:voice_id
      # Add a shared voice to your collection of voices
      # Documentation: https://elevenlabs.io/docs/api-reference/shared-voices/add-shared-voice
      #
      # @param public_user_id [String] Public user ID used to publicly identify ElevenLabs users
      # @param voice_id [String] ID of the voice to be used
      # @param new_name [String] The name that identifies this voice
      # @return [Hash] The JSON response containing the voice_id
      def add_shared_voice(public_user_id:, voice_id:, new_name:)
        endpoint = "/v1/voices/add/#{public_user_id}/#{voice_id}"
        
        body = {
          new_name: new_name
        }
        
        @client.post(endpoint, body)
      end

      alias_method :shared_voices, :get_shared_voices
      alias_method :list_shared_voices, :get_shared_voices
      alias_method :add_voice, :add_shared_voice

      private

      attr_reader :client
    end
  end
end
