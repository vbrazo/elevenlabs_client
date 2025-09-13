# frozen_string_literal: true

# config/initializers/elevenlabs_client.rb
#
# This initializer configures the ElevenLabs client with environment variables.
# Place this file in your Rails app at config/initializers/elevenlabs_client.rb

ElevenlabsClient::Settings.configure do |config|
  config.properties = {
    elevenlabs_base_uri: ENV["ELEVENLABS_BASE_URL"],
    elevenlabs_api_key: ENV["ELEVENLABS_API_KEY"],
  }
end

# After this configuration, you can use the client anywhere in your app:
#
# client = ElevenlabsClient.new
# client.dubs.create(file_io: file, filename: "video.mp4", target_languages: ["es", "pt"])
#
# The client will automatically use the configured settings.
