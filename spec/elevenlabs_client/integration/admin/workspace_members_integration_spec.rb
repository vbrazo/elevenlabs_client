# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin::WorkspaceMembers Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }

  it "updates a member" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/members")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "user@example.com", workspace_role: "workspace_member" }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_members.update_member(email: "user@example.com", workspace_role: "workspace_member")
    expect(result["status"]).to eq("ok")
  end
end
