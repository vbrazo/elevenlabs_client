# frozen_string_literal: true

module ElevenlabsClient
  class Voices
    def initialize(client)
      @client = client
    end

    # GET /v1/voices/{voice_id}
    # Retrieves details about a single voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-voice
    #
    # @param voice_id [String] The ID of the voice to retrieve
    # @return [Hash] Details of the voice
    def get(voice_id)
      endpoint = "/v1/voices/#{voice_id}"
      @client.get(endpoint)
    end

    # GET /v1/voices
    # Retrieves all voices associated with your Elevenlabs account
    # Documentation: https://elevenlabs.io/docs/api-reference/voices
    #
    # @return [Hash] The JSON response containing an array of voices
    def list
      endpoint = "/v1/voices"
      @client.get(endpoint)
    end

    # POST /v1/voices/add
    # Creates a new voice by cloning from audio samples
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/add-voice
    #
    # @param name [String] Name of the voice
    # @param samples [Array<File, IO>] Array of audio files to train the voice
    # @param options [Hash] Additional parameters
    # @option options [String] :description Description of the voice
    # @option options [Hash] :labels Metadata labels for the voice
    # @return [Hash] Response containing the new voice details
    def create(name, samples = [], **options)
      endpoint = "/v1/voices/add"
      
      # Build multipart payload
      payload = {
        "name" => name,
        "description" => options[:description] || ""
      }

      # Add labels if provided
      if options[:labels]
        options[:labels].each do |key, value|
          payload["labels[#{key}]"] = value.to_s
        end
      end

      # Add sample files
      samples.each_with_index do |sample, index|
        payload["files"] = @client.file_part(sample, "audio/mpeg")
      end

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/voices/{voice_id}/edit
    # Updates an existing voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/edit-voice
    #
    # @param voice_id [String] The ID of the voice to edit
    # @param samples [Array<File, IO>] Array of audio files (optional)
    # @param options [Hash] Voice parameters to update
    # @option options [String] :name New name for the voice
    # @option options [String] :description New description for the voice
    # @option options [Hash] :labels New labels for the voice
    # @return [Hash] Response containing the updated voice details
    def edit(voice_id, samples = [], **options)
      endpoint = "/v1/voices/#{voice_id}/edit"
      
      # Build multipart payload
      payload = {}
      
      # Add text fields if provided
      payload["name"] = options[:name] if options[:name]
      payload["description"] = options[:description] if options[:description]

      # Add labels if provided
      if options[:labels]
        options[:labels].each do |key, value|
          payload["labels[#{key}]"] = value.to_s
        end
      end

      # Add sample files if provided
      if samples && !samples.empty?
        samples.each_with_index do |sample, index|
          payload["files"] = @client.file_part(sample, "audio/mpeg")
        end
      end

      @client.post_multipart(endpoint, payload)
    end

    # DELETE /v1/voices/{voice_id}
    # Deletes a voice from your account
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/delete-voice
    #
    # @param voice_id [String] The ID of the voice to delete
    # @return [Hash] Response confirming deletion
    def delete(voice_id)
      endpoint = "/v1/voices/#{voice_id}"
      @client.delete(endpoint)
    end

    # Check if a voice is banned (safety control)
    # @param voice_id [String] The ID of the voice to check
    # @return [Boolean] True if the voice is banned
    def banned?(voice_id)
      voice = get(voice_id)
      voice["safety_control"] == "BAN"
    rescue ElevenlabsClient::ValidationError, ElevenlabsClient::APIError, ElevenlabsClient::NotFoundError
      # If we can't get the voice, assume it's not banned
      false
    end

    # Check if a voice is active (exists in the voice list)
    # @param voice_id [String] The ID of the voice to check
    # @return [Boolean] True if the voice is active
    def active?(voice_id)
      voices = list
      active_voice_ids = voices["voices"].map { |voice| voice["voice_id"] }
      active_voice_ids.include?(voice_id)
    rescue ElevenlabsClient::ValidationError, ElevenlabsClient::APIError, ElevenlabsClient::NotFoundError
      # If we can't get the voice list, assume it's not active
      false
    end

    # Alias methods for backward compatibility and convenience
    alias_method :get_voice, :get
    alias_method :list_voices, :list
    alias_method :create_voice, :create
    alias_method :edit_voice, :edit
    alias_method :delete_voice, :delete

    private

    attr_reader :client
  end
end
