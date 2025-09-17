# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::WorkspaceInvites do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:invites) { client.workspace_invites }

  describe "#invite" do
    it "requires email" do
      expect { invites.invite(email: "") }.to raise_error(ArgumentError)
    end

    it "posts invite" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/invites/add")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "john@example.com" }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = invites.invite(email: "john@example.com")
      expect(result).to eq({ "status" => "ok" })
    end
  end

  describe "#invite_bulk" do
    it "requires non-empty emails array" do
      expect { invites.invite_bulk(emails: []) }.to raise_error(ArgumentError)
    end

    it "posts bulk invites" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/invites/add-bulk")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { emails: ["a@b.com", "c@d.com"] }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = invites.invite_bulk(emails: ["a@b.com", "c@d.com"])
      expect(result["status"]).to eq("ok")
    end
  end

  describe "#delete_invite" do
    it "requires email" do
      expect { invites.delete_invite(email: "") }.to raise_error(ArgumentError)
    end

    it "deletes invite with body" do
      stub_request(:delete, "https://api.elevenlabs.io/v1/workspace/invites")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "john@example.com" }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = invites.delete_invite(email: "john@example.com")
      expect(result["status"]).to eq("ok")
    end
  end
end


