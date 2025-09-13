# frozen_string_literal: true

require_relative "elevenlabs_client/version"
require_relative "elevenlabs_client/client"
require_relative "elevenlabs_client/errors"

module ElevenlabsClient
  class Error < StandardError; end

  # Convenience method to create a new client
  def self.new(**options)
    Client.new(**options)
  end
end
