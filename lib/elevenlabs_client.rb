# frozen_string_literal: true

require_relative "elevenlabs_client/version"
require_relative "elevenlabs_client/errors"
require_relative "elevenlabs_client/settings"
require_relative "elevenlabs_client/dubs"
require_relative "elevenlabs_client/client"

module ElevenlabsClient
  class Error < StandardError; end

  # Convenience method to create a new client
  def self.new(**options)
    Client.new(**options)
  end

  # Convenience method to configure the client
  def self.configure(&block)
    Settings.configure(&block)
  end
end
