# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin::WorkspaceInvites Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }

  it "invites a single user" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/invites/add")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "john@example.com" }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_invites.invite(email: "john@example.com")
    expect(result["status"]).to eq("ok")
  end

  it "invites multiple users" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/invites/add-bulk")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { emails: ["a@b.com"] }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_invites.invite_bulk(emails: ["a@b.com"])
    expect(result["status"]).to eq("ok")
  end

  it "deletes an invite" do
    stub_request(:delete, "https://api.elevenlabs.io/v1/workspace/invites")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "john@example.com" }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_invites.delete_invite(email: "john@example.com")
    expect(result["status"]).to eq("ok")
  end
end
