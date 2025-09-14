# frozen_string_literal: true

module ElevenlabsClient
  class Models
    def initialize(client)
      @client = client
    end

    # GET /v1/models
    # Gets a list of available models
    # Documentation: https://elevenlabs.io/docs/api-reference/models/list
    #
    # @return [Hash] The JSON response containing an array of models
    def list
      endpoint = "/v1/models"
      @client.get(endpoint)
    end

    alias_method :list_models, :list

    private

    attr_reader :client
  end
end
