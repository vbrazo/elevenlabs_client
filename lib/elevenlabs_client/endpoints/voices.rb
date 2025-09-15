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

    # POST /v1/similar-voices
    # Returns a list of shared voices similar to the provided audio sample
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/similar-voices
    #
    # @param audio_file [IO, File] Audio file to find similar voices for
    # @param filename [String] Original filename for the audio file
    # @param options [Hash] Optional parameters
    # @option options [Float] :similarity_threshold Threshold for voice similarity (0-2)
    # @option options [Integer] :top_k Number of most similar voices to return (1-100)
    # @return [Hash] Response containing similar voices
    def find_similar(audio_file, filename, **options)
      endpoint = "/v1/similar-voices"
      
      payload = {
        audio_file: @client.file_part(audio_file, filename)
      }
      
      payload[:similarity_threshold] = options[:similarity_threshold] if options[:similarity_threshold]
      payload[:top_k] = options[:top_k] if options[:top_k]

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/voices/add
    # Creates a new IVC (Instant Voice Cloning) voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/add-voice
    #
    # @param name [String] Name of the voice
    # @param audio_files [Array<IO, File>] Array of audio files for voice cloning
    # @param filenames [Array<String>] Array of original filenames
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :remove_background_noise Remove background noise (default: false)
    # @option options [String] :description Description of the voice
    # @option options [String] :labels Serialized labels dictionary
    # @return [Hash] Response containing voice_id and requires_verification status
    def create_ivc(name, audio_files, filenames, **options)
      endpoint = "/v1/voices/add"
      
      payload = { name: name }
      
      # Add optional parameters
      payload[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?
      payload[:description] = options[:description] if options[:description]
      payload[:labels] = options[:labels] if options[:labels]
      
      # Add audio files
      audio_files.each_with_index do |file, index|
        filename = filenames[index] || "audio_#{index}.mp3"
        payload["files[]"] = @client.file_part(file, filename)
      end

      @client.post_multipart(endpoint, payload)
    end

    # GET /v1/voices/settings/default
    # Gets the default settings for voices
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/default-settings
    #
    # @return [Hash] Default voice settings
    def get_default_settings
      endpoint = "/v1/voices/settings/default"
      @client.get(endpoint)
    end

    # GET /v1/voices/{voice_id}/settings
    # Returns the settings for a specific voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-settings
    #
    # @param voice_id [String] Voice ID
    # @return [Hash] Voice settings
    def get_settings(voice_id)
      endpoint = "/v1/voices/#{voice_id}/settings"
      @client.get(endpoint)
    end

    # POST /v1/voices/{voice_id}/settings/edit
    # Edit settings for a specific voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/edit-settings
    #
    # @param voice_id [String] Voice ID
    # @param options [Hash] Voice settings to update
    # @option options [Float] :stability Stability setting (0.0-1.0)
    # @option options [Boolean] :use_speaker_boost Enable speaker boost
    # @option options [Float] :similarity_boost Similarity boost setting (0.0-1.0)
    # @option options [Float] :style Style exaggeration (0.0-1.0)
    # @option options [Float] :speed Speed adjustment (0.25-4.0)
    # @return [Hash] Response with status
    def edit_settings(voice_id, **options)
      endpoint = "/v1/voices/#{voice_id}/settings/edit"
      
      payload = {}
      payload[:stability] = options[:stability] if options[:stability]
      payload[:use_speaker_boost] = options[:use_speaker_boost] unless options[:use_speaker_boost].nil?
      payload[:similarity_boost] = options[:similarity_boost] if options[:similarity_boost]
      payload[:style] = options[:style] if options[:style]
      payload[:speed] = options[:speed] if options[:speed]

      @client.post(endpoint, payload)
    end

    # GET /v1/voices/{voice_id}/samples/{sample_id}/audio
    # Returns the audio corresponding to a sample attached to a voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-sample-audio
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @return [String] Binary audio data
    def get_sample_audio(voice_id, sample_id)
      endpoint = "/v1/voices/#{voice_id}/samples/#{sample_id}/audio"
      @client.get(endpoint)
    end

    # POST /v1/voices/pvc
    # Creates a new PVC (Professional Voice Cloning) voice with metadata but no samples
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/create-pvc
    #
    # @param name [String] Name of the voice (max 100 characters)
    # @param language [String] Language used in the samples
    # @param options [Hash] Optional parameters
    # @option options [String] :description Description (max 500 characters)
    # @option options [Hash] :labels Serialized labels dictionary
    # @return [Hash] Response containing voice_id
    def create_pvc(name, language, **options)
      endpoint = "/v1/voices/pvc"
      
      payload = {
        name: name,
        language: language
      }
      
      payload[:description] = options[:description] if options[:description]
      payload[:labels] = options[:labels] if options[:labels]

      @client.post(endpoint, payload)
    end

    # POST /v1/voices/pvc/{voice_id}
    # Edit PVC voice metadata
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/update-pvc
    #
    # @param voice_id [String] Voice ID
    # @param options [Hash] Parameters to update
    # @option options [String] :name New name (max 100 characters)
    # @option options [String] :language New language
    # @option options [String] :description New description (max 500 characters)
    # @option options [Hash] :labels New labels dictionary
    # @return [Hash] Response containing voice_id
    def update_pvc(voice_id, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}"
      
      payload = {}
      payload[:name] = options[:name] if options[:name]
      payload[:language] = options[:language] if options[:language]
      payload[:description] = options[:description] if options[:description]
      payload[:labels] = options[:labels] if options[:labels]

      @client.post(endpoint, payload)
    end

    # POST /v1/voices/pvc/{voice_id}/train
    # Start PVC training process for a voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/train-pvc
    #
    # @param voice_id [String] Voice ID
    # @param options [Hash] Optional parameters
    # @option options [String] :model_id Model ID to use for conversion
    # @return [Hash] Response with status
    def train_pvc(voice_id, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}/train"
      
      payload = {}
      payload[:model_id] = options[:model_id] if options[:model_id]

      @client.post(endpoint, payload)
    end

    # POST /v1/voices/pvc/{voice_id}/samples
    # Add audio samples to a PVC voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/add-pvc-samples
    #
    # @param voice_id [String] Voice ID
    # @param audio_files [Array<IO, File>] Audio files for the voice
    # @param filenames [Array<String>] Original filenames
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :remove_background_noise Remove background noise (default: false)
    # @return [Array<Hash>] Array of sample information
    def add_pvc_samples(voice_id, audio_files, filenames, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples"
      
      payload = {}
      payload[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?
      
      # Add audio files
      audio_files.each_with_index do |file, index|
        filename = filenames[index] || "audio_#{index}.mp3"
        payload["files[]"] = @client.file_part(file, filename)
      end

      @client.post_multipart(endpoint, payload)
    end

    # POST /v1/voices/pvc/{voice_id}/samples/{sample_id}
    # Update a PVC voice sample - apply noise removal or select speaker
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/update-pvc-sample
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @param options [Hash] Update parameters
    # @option options [Boolean] :remove_background_noise Remove background noise
    # @option options [Array<String>] :selected_speaker_ids Speaker IDs for training
    # @option options [Integer] :trim_start_time Start time in milliseconds
    # @option options [Integer] :trim_end_time End time in milliseconds
    # @return [Hash] Response containing voice_id
    def update_pvc_sample(voice_id, sample_id, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}"
      
      payload = {}
      payload[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?
      payload[:selected_speaker_ids] = options[:selected_speaker_ids] if options[:selected_speaker_ids]
      payload[:trim_start_time] = options[:trim_start_time] if options[:trim_start_time]
      payload[:trim_end_time] = options[:trim_end_time] if options[:trim_end_time]

      @client.post(endpoint, payload)
    end

    # DELETE /v1/voices/pvc/{voice_id}/samples/{sample_id}
    # Delete a sample from a PVC voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/delete-pvc-sample
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @return [Hash] Response with status
    def delete_pvc_sample(voice_id, sample_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}"
      @client.delete(endpoint)
    end

    # GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/audio
    # Retrieve voice sample audio with or without noise removal
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-pvc-sample-audio
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @param options [Hash] Optional parameters
    # @option options [Boolean] :remove_background_noise Remove background noise (default: false)
    # @return [Hash] Response with base64 audio data and metadata
    def get_pvc_sample_audio(voice_id, sample_id, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}/audio"
      
      params = {}
      params[:remove_background_noise] = options[:remove_background_noise] unless options[:remove_background_noise].nil?

      @client.get(endpoint, params)
    end

    # GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/waveform
    # Retrieve the visual waveform of a voice sample
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-pvc-waveform
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @return [Hash] Response with sample_id and visual_waveform array
    def get_pvc_sample_waveform(voice_id, sample_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}/waveform"
      @client.get(endpoint)
    end

    # GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/speakers
    # Retrieve speaker separation status and detected speakers
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-pvc-speakers
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @return [Hash] Response with separation status and speakers
    def get_pvc_speaker_separation_status(voice_id, sample_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}/speakers"
      @client.get(endpoint)
    end

    # POST /v1/voices/pvc/{voice_id}/samples/{sample_id}/separate-speakers
    # Start speaker separation process for a sample
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/start-speaker-separation
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @return [Hash] Response with status
    def start_pvc_speaker_separation(voice_id, sample_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}/separate-speakers"
      @client.post(endpoint)
    end

    # GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/speakers/{speaker_id}/audio
    # Retrieve separated audio for a specific speaker
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-separated-speaker-audio
    #
    # @param voice_id [String] Voice ID
    # @param sample_id [String] Sample ID
    # @param speaker_id [String] Speaker ID
    # @return [Hash] Response with base64 audio data and metadata
    def get_pvc_separated_speaker_audio(voice_id, sample_id, speaker_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/samples/#{sample_id}/speakers/#{speaker_id}/audio"
      @client.get(endpoint)
    end

    # POST /v1/voices/pvc/{voice_id}/verification
    # Request manual verification for a PVC voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/request-pvc-verification
    #
    # @param voice_id [String] Voice ID
    # @param verification_files [Array<IO, File>] Verification documents
    # @param filenames [Array<String>] Original filenames
    # @param options [Hash] Optional parameters
    # @option options [String] :extra_text Extra text for verification process
    # @return [Hash] Response with status
    def request_pvc_verification(voice_id, verification_files, filenames, **options)
      endpoint = "/v1/voices/pvc/#{voice_id}/verification"
      
      payload = {}
      payload[:extra_text] = options[:extra_text] if options[:extra_text]
      
      # Add verification files
      verification_files.each_with_index do |file, index|
        filename = filenames[index] || "verification_#{index}.pdf"
        payload["files[]"] = @client.file_part(file, filename)
      end

      @client.post_multipart(endpoint, payload)
    end

    # GET /v1/voices/pvc/{voice_id}/captcha
    # Get captcha for PVC voice verification
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/get-pvc-captcha
    #
    # @param voice_id [String] Voice ID
    # @return [Hash] Captcha data
    def get_pvc_captcha(voice_id)
      endpoint = "/v1/voices/pvc/#{voice_id}/captcha"
      @client.get(endpoint)
    end

    # POST /v1/voices/pvc/{voice_id}/captcha
    # Submit captcha verification for PVC voice
    # Documentation: https://elevenlabs.io/docs/api-reference/voices/verify-pvc-captcha
    #
    # @param voice_id [String] Voice ID
    # @param recording_file [IO, File] Audio recording of the user
    # @param filename [String] Original filename for the recording
    # @return [Hash] Response with status
    def verify_pvc_captcha(voice_id, recording_file, filename)
      endpoint = "/v1/voices/pvc/#{voice_id}/captcha"
      
      payload = {
        recording: @client.file_part(recording_file, filename)
      }

      @client.post_multipart(endpoint, payload)
    end

    alias_method :get_voice, :get
    alias_method :list_voices, :list
    alias_method :create_voice, :create
    alias_method :edit_voice, :edit
    alias_method :delete_voice, :delete
    alias_method :similar_voices, :find_similar
    alias_method :default_settings, :get_default_settings
    alias_method :voice_settings, :get_settings
    alias_method :update_settings, :edit_settings

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

    private

    attr_reader :client
  end
end
