# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class PronunciationDictionaries
      def initialize(client)
        @client = client
      end

      # POST /v1/pronunciation-dictionaries/add-from-file (multipart)
      # Creates a new pronunciation dictionary from a lexicon .PLS file
      # Required: name
      # Optional: file (IO + filename), description, workspace_access
      def add_from_file(name:, file_io: nil, filename: nil, description: nil, workspace_access: nil)
        raise ArgumentError, "name is required" if name.nil? || name.to_s.strip.empty?

        endpoint = "/v1/pronunciation-dictionaries/add-from-file"
        payload = { name: name }
        payload[:description] = description if description
        payload[:workspace_access] = workspace_access if workspace_access

        if file_io && filename
          payload[:file] = @client.file_part(file_io, filename)
        end

        @client.post_multipart(endpoint, payload)
      end

      alias_method :create_from_file, :add_from_file

      # POST /v1/pronunciation-dictionaries/add-from-rules (json)
      # Creates a new pronunciation dictionary from provided rules
      # Required: name, rules (Array)
      # Optional: description, workspace_access
      def add_from_rules(name:, rules:, description: nil, workspace_access: nil)
        raise ArgumentError, "name is required" if name.nil? || name.to_s.strip.empty?
        raise ArgumentError, "rules must be a non-empty Array" unless rules.is_a?(Array) && !rules.empty?

        endpoint = "/v1/pronunciation-dictionaries/add-from-rules"
        body = { name: name, rules: rules }
        body[:description] = description if description
        body[:workspace_access] = workspace_access if workspace_access

        @client.post(endpoint, body)
      end

      alias_method :create_from_rules, :add_from_rules

      # GET /v1/pronunciation-dictionaries/:pronunciation_dictionary_id
      def get_pronunciation_dictionary(pronunciation_dictionary_id)
        raise ArgumentError, "pronunciation_dictionary_id is required" if pronunciation_dictionary_id.nil? || pronunciation_dictionary_id.to_s.strip.empty?

        endpoint = "/v1/pronunciation-dictionaries/#{pronunciation_dictionary_id}"
        @client.get(endpoint)
      end

      alias_method :get, :get_pronunciation_dictionary

      # PATCH /v1/pronunciation-dictionaries/:pronunciation_dictionary_id
      # Accepts partial attributes like archived, name, description, workspace_access
      def update_pronunciation_dictionary(pronunciation_dictionary_id, **attributes)
        raise ArgumentError, "pronunciation_dictionary_id is required" if pronunciation_dictionary_id.nil? || pronunciation_dictionary_id.to_s.strip.empty?
        endpoint = "/v1/pronunciation-dictionaries/#{pronunciation_dictionary_id}"
        @client.patch(endpoint, attributes)
      end

      alias_method :update, :update_pronunciation_dictionary

      # GET /v1/pronunciation-dictionaries/:dictionary_id/:version_id/download
      # Returns raw PLS file contents
      def download_pronunciation_dictionary_version(dictionary_id:, version_id:)
        raise ArgumentError, "dictionary_id is required" if dictionary_id.nil? || dictionary_id.to_s.strip.empty?
        raise ArgumentError, "version_id is required" if version_id.nil? || version_id.to_s.strip.empty?

        endpoint = "/v1/pronunciation-dictionaries/#{dictionary_id}/#{version_id}/download"
        @client.get_binary(endpoint)
      end

      alias_method :download_version, :download_pronunciation_dictionary_version

      # GET /v1/pronunciation-dictionaries
      # Optional query: cursor, page_size, sort, sort_direction
      def list_pronunciation_dictionaries(cursor: nil, page_size: nil, sort: nil, sort_direction: nil)
        params = {
          cursor: cursor,
          page_size: page_size,
          sort: sort,
          sort_direction: sort_direction
        }.compact

        @client.get("/v1/pronunciation-dictionaries", params)
      end

      alias_method :list, :list_pronunciation_dictionaries

      private

      attr_reader :client
    end
  end
end


