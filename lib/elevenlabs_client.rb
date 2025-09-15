# frozen_string_literal: true

require_relative "elevenlabs_client/version"
require_relative "elevenlabs_client/errors"
require_relative "elevenlabs_client/settings"
require_relative "elevenlabs_client/endpoints/admin/history"
require_relative "elevenlabs_client/endpoints/admin/models"
require_relative "elevenlabs_client/endpoints/admin/samples"
require_relative "elevenlabs_client/endpoints/admin/service_accounts"
require_relative "elevenlabs_client/endpoints/admin/usage"
require_relative "elevenlabs_client/endpoints/admin/user"
require_relative "elevenlabs_client/endpoints/admin/voice_library"
require_relative "elevenlabs_client/endpoints/admin/webhooks"
require_relative "elevenlabs_client/endpoints/audio_isolation"
require_relative "elevenlabs_client/endpoints/audio_native"
require_relative "elevenlabs_client/endpoints/dubs"
require_relative "elevenlabs_client/endpoints/forced_alignment"
require_relative "elevenlabs_client/endpoints/music"
require_relative "elevenlabs_client/endpoints/sound_generation"
require_relative "elevenlabs_client/endpoints/speech_to_speech"
require_relative "elevenlabs_client/endpoints/speech_to_text"
require_relative "elevenlabs_client/endpoints/text_to_speech"
require_relative "elevenlabs_client/endpoints/text_to_dialogue"
require_relative "elevenlabs_client/endpoints/text_to_voice"
require_relative "elevenlabs_client/endpoints/voices"
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
