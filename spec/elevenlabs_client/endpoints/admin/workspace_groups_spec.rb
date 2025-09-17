# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::WorkspaceGroups do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:groups) { client.workspace_groups }

  describe "#search" do
    it "requires name" do
      expect { groups.search(name: "") }.to raise_error(ArgumentError)
    end

    it "queries the endpoint with name" do
      stub_request(:get, "https://api.elevenlabs.io/v1/workspace/groups/search")
        .with(headers: { "xi-api-key" => "test_api_key" }, query: { name: "team" })
        .to_return(status: 200, body: [{ name: "team", id: "g1", members_emails: ["a@b.com"] }].to_json, headers: { "Content-Type" => "application/json" })

      result = groups.search(name: "team")
      expect(result).to be_a(Array)
      expect(result.first).to include("name" => "team", "id" => "g1")
    end
  end

  describe "#add_member" do
    it "validates group_id and email" do
      expect { groups.add_member(group_id: nil, email: "a@b.com") }.to raise_error(ArgumentError)
      expect { groups.add_member(group_id: "g1", email: "") }.to raise_error(ArgumentError)
    end

    it "posts to add member" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/groups/g1/members")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "a@b.com" }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = groups.add_member(group_id: "g1", email: "a@b.com")
      expect(result).to eq({ "status" => "ok" })
    end
  end

  describe "#remove_member" do
    it "validates group_id and email" do
      expect { groups.remove_member(group_id: nil, email: "a@b.com") }.to raise_error(ArgumentError)
      expect { groups.remove_member(group_id: "g1", email: "") }.to raise_error(ArgumentError)
    end

    it "posts to remove member" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/groups/g1/members/remove")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "a@b.com" }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = groups.remove_member(group_id: "g1", email: "a@b.com")
      expect(result).to eq({ "status" => "ok" })
    end
  end
end


