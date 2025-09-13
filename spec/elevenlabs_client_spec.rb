# frozen_string_literal: true

RSpec.describe ElevenlabsClient do
  it "has a version number" do
    expect(ElevenlabsClient::VERSION).not_to be nil
  end

  describe ".new" do
    it "creates a new client instance" do
      client = ElevenlabsClient.new(api_key: "test_key")
      expect(client).to be_a(ElevenlabsClient::Client)
    end

    it "passes options to the client" do
      client = ElevenlabsClient.new(api_key: "test_key", base_url: "https://custom.api.com")
      expect(client.api_key).to eq("test_key")
      expect(client.base_url).to eq("https://custom.api.com")
    end
  end
end
