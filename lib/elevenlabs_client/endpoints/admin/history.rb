# frozen_string_literal: true

require 'cgi'

module ElevenlabsClient
  module Admin
    class History
      def initialize(client)
        @client = client
      end

      # GET /v1/history
      # Returns a list of your generated audio
      # Documentation: https://elevenlabs.io/docs/api-reference/history/get-generated-items
      #
      # @param options [Hash] Optional parameters
      # @option options [Integer] :page_size How many history items to return at maximum (max 1000, default 100)
      # @option options [String] :start_after_history_item_id After which ID to start fetching (for pagination)
      # @option options [String] :voice_id ID of the voice to filter for
      # @option options [String] :search Search term for filtering history items
      # @option options [String] :source Source of the generated history item ("TTS" or "STS")
      # @return [Hash] Response containing history items, pagination info
      def list(**options)
        endpoint = "/v1/history"
        
        # Build query parameters
        query_params = {}
        query_params[:page_size] = options[:page_size] if options[:page_size]
        query_params[:start_after_history_item_id] = options[:start_after_history_item_id] if options[:start_after_history_item_id]
        query_params[:voice_id] = options[:voice_id] if options[:voice_id]
        query_params[:search] = options[:search] if options[:search]
        query_params[:source] = options[:source] if options[:source]
        
        # Add query parameters to endpoint if any exist
        if query_params.any?
          query_string = query_params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
          endpoint += "?#{query_string}"
        end

        @client.get(endpoint)
      end

      # GET /v1/history/:history_item_id
      # Retrieves a history item by ID
      # Documentation: https://elevenlabs.io/docs/api-reference/history/get-history-item
      #
      # @param history_item_id [String] ID of the history item
      # @return [Hash] The history item data
      def get(history_item_id)
        endpoint = "/v1/history/#{history_item_id}"
        @client.get(endpoint)
      end

      # DELETE /v1/history/:history_item_id
      # Delete a history item by its ID
      # Documentation: https://elevenlabs.io/docs/api-reference/history/delete-history-item
      #
      # @param history_item_id [String] ID of the history item to delete
      # @return [Hash] Status response
      def delete(history_item_id)
        endpoint = "/v1/history/#{history_item_id}"
        @client.delete(endpoint)
      end

      # GET /v1/history/:history_item_id/audio
      # Returns the audio of a history item
      # Documentation: https://elevenlabs.io/docs/api-reference/history/get-audio-from-history-item
      #
      # @param history_item_id [String] ID of the history item
      # @return [String] The binary audio data
      def get_audio(history_item_id)
        endpoint = "/v1/history/#{history_item_id}/audio"
        @client.get_binary(endpoint)
      end

      # POST /v1/history/download
      # Download one or more history items
      # Documentation: https://elevenlabs.io/docs/api-reference/history/download-history-items
      #
      # @param history_item_ids [Array<String>] List of history item IDs to download
      # @param options [Hash] Optional parameters
      # @option options [String] :output_format Output format ("wav" or "default")
      # @return [String] The binary audio data (single file) or zip file (multiple files)
      def download(history_item_ids, **options)
        endpoint = "/v1/history/download"
        request_body = { history_item_ids: history_item_ids }
        
        # Add optional parameters
        request_body[:output_format] = options[:output_format] if options[:output_format]

        @client.post_binary(endpoint, request_body)
      end

      # Alias methods for convenience
      alias_method :get_history_item, :get
      alias_method :get_generated_items, :list
      alias_method :delete_history_item, :delete
      alias_method :get_audio_from_history_item, :get_audio
      alias_method :download_history_items, :download

      private

      attr_reader :client
    end
  end
end
