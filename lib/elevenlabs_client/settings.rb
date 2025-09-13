# frozen_string_literal: true

module ElevenlabsClient
  class Settings
    class << self
      attr_accessor :properties

      def configure
        self.properties ||= {}
        yield(self) if block_given?
      end

      def elevenlabs_base_uri
        properties&.dig(:elevenlabs_base_uri) || ENV["ELEVENLABS_BASE_URL"] || "https://api.elevenlabs.io"
      end

      def elevenlabs_api_key
        properties&.dig(:elevenlabs_api_key) || ENV["ELEVENLABS_API_KEY"]
      end

      # Reset configuration (useful for testing)
      def reset!
        self.properties = {}
      end
    end
  end
end
