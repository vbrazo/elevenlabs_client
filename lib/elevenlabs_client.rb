# frozen_string_literal: true

require_relative "elevenlabs_client/version"
require_relative "elevenlabs_client/errors"
require_relative "elevenlabs_client/settings"
require_relative "elevenlabs_client/endpoints/dubs"
require_relative "elevenlabs_client/endpoints/text_to_speech"
require_relative "elevenlabs_client/endpoints/text_to_speech_stream"
require_relative "elevenlabs_client/endpoints/text_to_speech_with_timestamps"
require_relative "elevenlabs_client/endpoints/text_to_speech_stream_with_timestamps"
require_relative "elevenlabs_client/endpoints/text_to_dialogue"
require_relative "elevenlabs_client/endpoints/text_to_dialogue_stream"
require_relative "elevenlabs_client/endpoints/sound_generation"
require_relative "elevenlabs_client/endpoints/text_to_voice"
require_relative "elevenlabs_client/endpoints/models"
require_relative "elevenlabs_client/endpoints/voices"
require_relative "elevenlabs_client/endpoints/music"
require_relative "elevenlabs_client/endpoints/audio_isolation"
require_relative "elevenlabs_client/endpoints/audio_native"
require_relative "elevenlabs_client/endpoints/forced_alignment"
require_relative "elevenlabs_client/endpoints/speech_to_speech"
require_relative "elevenlabs_client/endpoints/speech_to_text"
require_relative "elevenlabs_client/endpoints/websocket_text_to_speech"
require_relative "elevenlabs_client/client"

module ElevenlabsClient
  # Convenience method to create a new client
  def self.new(**options)
    Client.new(**options)
  end

  # Convenience method to configure the client
  def self.configure(&block)
    Settings.configure(&block)
  end
end
