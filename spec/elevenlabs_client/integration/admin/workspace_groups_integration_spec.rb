# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin::WorkspaceGroups Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }

  it "searches for groups by name" do
    stub_request(:get, "https://api.elevenlabs.io/v1/workspace/groups/search")
      .with(headers: { "xi-api-key" => "test_api_key" }, query: { name: "team" })
      .to_return(status: 200, body: [{ name: "team", id: "g1", members_emails: ["a@b.com"] }].to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_groups.search(name: "team")
    expect(result).to be_a(Array)
    expect(result.first["id"]).to eq("g1")
  end

  it "adds a member to a group" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/groups/g1/members")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "a@b.com" }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_groups.add_member(group_id: "g1", email: "a@b.com")
    expect(result["status"]).to eq("ok")
  end

  it "removes a member from a group" do
    stub_request(:post, "https://api.elevenlabs.io/v1/workspace/groups/g1/members/remove")
      .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "a@b.com" }.to_json)
      .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

    result = client.workspace_groups.remove_member(group_id: "g1", email: "a@b.com")
    expect(result["status"]).to eq("ok")
  end
end
