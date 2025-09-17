# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::WorkspaceMembers do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:members) { client.workspace_members }

  describe "#update_member" do
    it "requires email" do
      expect { members.update_member(email: "") }.to raise_error(ArgumentError)
    end

    it "updates member attributes" do
      stub_request(:post, "https://api.elevenlabs.io/v1/workspace/members")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" }, body: { email: "user@example.com", is_locked: true, workspace_role: "workspace_admin" }.to_json)
        .to_return(status: 200, body: { status: "ok" }.to_json, headers: { "Content-Type" => "application/json" })

      result = members.update_member(email: "user@example.com", is_locked: true, workspace_role: "workspace_admin")
      expect(result["status"]).to eq("ok")
    end
  end
end
