# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::WorkspaceResources do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:resources) { client.workspace_resources }

  describe "#get_resource" do
    it "requires resource_id and resource_type" do
      expect { resources.get_resource(resource_id: "", resource_type: "voice") }.to raise_error(ArgumentError)
      expect { resources.get_resource(resource_id: "abc", resource_type: "") }.to raise_error(ArgumentError)
    end

    it "fetches resource metadata" do
      stub_request(:get, "https://api.elevenlabs.io/v1/workspace/resources/abc")
        .with(headers: { "xi-api-key" => "test_api_key" }, query: { resource_type: "voice" })
        .to_return(status: 200, body: { resource_id: "abc", resource_type: "voice" }.to_json, headers: { "Content-Type" => "application/json" })

      result = resources.get_resource(resource_id: "abc", resource_type: "voice")
      expect(result["resource_id"]).to eq("abc")
    end
  end

  describe "#share" do
    it "requires role and resource info" do
      expect { resources.share(resource_id: "", role: "admin", resource_type: "voice") }.to raise_error(ArgumentError)
      expect { resources.share(resource_id: "abc", role: "", resource_type: "voice") }.to raise_error(ArgumentError)
    end

    it "shares resource with user" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/resources/abc/share")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { role: "admin", resource_type: "voice", user_email: "user@example.com" }.to_json)
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      result = resources.share(resource_id: "abc", role: "admin", resource_type: "voice", user_email: "user@example.com")
      expect(result).to be_a(Hash)
    end
  end

  describe "#unshare" do
    it "unshares resource" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/resources/abc/unshare")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { resource_type: "voice", group_id: "g1" }.to_json)
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      result = resources.unshare(resource_id: "abc", resource_type: "voice", group_id: "g1")
      expect(result).to be_a(Hash)
    end
  end
end
