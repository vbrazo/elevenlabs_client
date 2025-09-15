# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class Samples
      def initialize(client)
        @client = client
      end

      # DELETE /v1/voices/:voice_id/samples/:sample_id
      # Delete voice sample
      # Documentation: https://elevenlabs.io/docs/api-reference/samples/delete-voice-sample
      #
      # @param voice_id [String] ID of the voice to be used. You can use the Get voices endpoint to list all the available voices.
      # @param sample_id [String] ID of the sample to be used. You can use the Get voices endpoint to list all the available samples for a voice.
      # @return [Hash] The JSON response containing the status of the deletion request.
      def delete_sample(voice_id:, sample_id:)
        endpoint = "/v1/voices/#{voice_id}/samples/#{sample_id}"
        @client.delete(endpoint)
      end

      alias_method :delete_voice_sample, :delete_sample
      alias_method :remove_sample, :delete_sample

      private

      attr_reader :client
    end
  end
end
