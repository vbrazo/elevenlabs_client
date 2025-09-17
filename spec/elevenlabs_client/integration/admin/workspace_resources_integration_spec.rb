# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin::WorkspaceResources Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }

  it "gets resource metadata" do
    stub_request(:get, "https://api.elevenlabs.io/v1/workspace/resources/abc")
      .with(headers: { "xi-api-key" => "test_api_key" }, query: { resource_type: "voice" })
      .to_return(status: 200, body: { resource_id: "abc", resource_type: "voice" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_resources.get_resource(resource_id: "abc", resource_type: "voice")
    expect(result["resource_id"]).to eq("abc")
  end

  it "shares a resource" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/resources/abc/share")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { role: "admin", resource_type: "voice", group_id: "g1" }.to_json)
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_resources.share(resource_id: "abc", role: "admin", resource_type: "voice", group_id: "g1")
    expect(result).to be_a(Hash)
  end

  it "unshares a resource" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/resources/abc/unshare")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { resource_type: "voice", user_email: "user@example.com" }.to_json)
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_resources.unshare(resource_id: "abc", resource_type: "voice", user_email: "user@example.com")
    expect(result).to be_a(Hash)
  end
end
