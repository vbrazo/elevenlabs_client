# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::McpServers do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:mcp_servers) { described_class.new(client) }

  describe "#create" do
    let(:endpoint) { "/v1/convai/mcp-servers" }
    let(:config) do
      {
        url: "https://example.com/mcp",
        name: "Test MCP Server",
        approval_policy: "auto_approve_all",
        transport: "SSE",
        description: "Test server"
      }
    end
    let(:response) do
      {
        "id" => "mcp_server_123",
        "config" => config.transform_keys(&:to_s),
        "metadata" => {
          "created_at" => 1234567890,
          "owner_user_id" => "user_123"
        },
        "access_info" => {
          "is_creator" => true,
          "creator_name" => "Test User",
          "creator_email" => "test@example.com",
          "role" => "admin"
        },
        "dependent_agents" => []
      }
    end

    before do
      allow(client).to receive(:post).with(endpoint, any_args).and_return(response)
    end

    it "creates MCP server successfully" do
      result = mcp_servers.create(config: config)

      expect(result).to eq(response)
      expect(result["id"]).to eq("mcp_server_123")
      expect(result["config"]["name"]).to eq("Test MCP Server")
      expect(result["config"]["approval_policy"]).to eq("auto_approve_all")
    end

    it "calls the correct endpoint with correct payload" do
      mcp_servers.create(config: config)

      expected_body = { config: config }
      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "requires config parameter" do
      expect {
        mcp_servers.create(config: nil)
      }.to raise_error(ArgumentError, "config is required")
    end

    it "requires non-empty config" do
      expect {
        mcp_servers.create(config: {})
      }.to raise_error(ArgumentError, "config is required")
    end

    it "handles config with authentication" do
      auth_config = config.merge(
        secret_token: { secret_id: "secret_123" },
        request_headers: { "Authorization" => "Bearer token" }
      )

      mcp_servers.create(config: auth_config)

      expected_body = { config: auth_config }
      expect(client).to have_received(:post).with(endpoint, expected_body)
    end
  end

  describe "#list" do
    let(:endpoint) { "/v1/convai/mcp-servers" }
    let(:response) do
      {
        "mcp_servers" => [
          {
            "id" => "mcp_server_123",
            "config" => {
              "url" => "https://example.com/mcp",
              "name" => "Test Server 1",
              "approval_policy" => "auto_approve_all"
            },
            "dependent_agents" => []
          },
          {
            "id" => "mcp_server_456",
            "config" => {
              "url" => "https://api.example.com/mcp",
              "name" => "Test Server 2",
              "approval_policy" => "require_approval_per_tool"
            },
            "dependent_agents" => []
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with(endpoint).and_return(response)
    end

    it "lists MCP servers successfully" do
      result = mcp_servers.list

      expect(result).to eq(response)
      expect(result["mcp_servers"].size).to eq(2)
      expect(result["mcp_servers"].first["id"]).to eq("mcp_server_123")
    end

    it "calls the correct endpoint" do
      mcp_servers.list

      expect(client).to have_received(:get).with(endpoint)
    end
  end

  describe "#get" do
    let(:server_id) { "mcp_server_123" }
    let(:endpoint) { "/v1/convai/mcp-servers/#{server_id}" }
    let(:response) do
      {
        "id" => server_id,
        "config" => {
          "url" => "https://example.com/mcp",
          "name" => "Test MCP Server",
          "approval_policy" => "auto_approve_all",
          "tool_approval_hashes" => [
            {
              "tool_name" => "test_tool",
              "tool_hash" => "hash123",
              "approval_policy" => "auto_approved"
            }
          ]
        },
        "metadata" => {
          "created_at" => 1234567890,
          "owner_user_id" => "user_123"
        },
        "dependent_agents" => []
      }
    end

    before do
      allow(client).to receive(:get).with(endpoint).and_return(response)
    end

    it "gets MCP server successfully" do
      result = mcp_servers.get(server_id)

      expect(result).to eq(response)
      expect(result["id"]).to eq(server_id)
      expect(result["config"]["name"]).to eq("Test MCP Server")
    end

    it "calls the correct endpoint" do
      mcp_servers.get(server_id)

      expect(client).to have_received(:get).with(endpoint)
    end

    it "requires mcp_server_id parameter" do
      expect {
        mcp_servers.get(nil)
      }.to raise_error(ArgumentError, "mcp_server_id is required")

      expect {
        mcp_servers.get("")
      }.to raise_error(ArgumentError, "mcp_server_id is required")

      expect {
        mcp_servers.get("   ")
      }.to raise_error(ArgumentError, "mcp_server_id is required")
    end
  end

  describe "#update_approval_policy" do
    let(:server_id) { "mcp_server_123" }
    let(:endpoint) { "/v1/convai/mcp-servers/#{server_id}/approval-policy" }
    let(:approval_policy) { "require_approval_all" }
    let(:response) do
      {
        "id" => server_id,
        "config" => {
          "approval_policy" => approval_policy
        }
      }
    end

    before do
      allow(client).to receive(:patch).with(endpoint, any_args).and_return(response)
    end

    it "updates approval policy successfully" do
      result = mcp_servers.update_approval_policy(server_id, approval_policy: approval_policy)

      expect(result).to eq(response)
      expect(result["config"]["approval_policy"]).to eq(approval_policy)
    end

    it "calls the correct endpoint with correct payload" do
      mcp_servers.update_approval_policy(server_id, approval_policy: approval_policy)

      expected_body = { approval_policy: approval_policy }
      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end

    it "requires mcp_server_id parameter" do
      expect {
        mcp_servers.update_approval_policy(nil, approval_policy: approval_policy)
      }.to raise_error(ArgumentError, "mcp_server_id is required")
    end

    it "requires approval_policy parameter" do
      expect {
        mcp_servers.update_approval_policy(server_id, approval_policy: nil)
      }.to raise_error(ArgumentError, "approval_policy is required")

      expect {
        mcp_servers.update_approval_policy(server_id, approval_policy: "")
      }.to raise_error(ArgumentError, "approval_policy is required")
    end

    it "validates approval_policy values" do
      valid_policies = %w[auto_approve_all require_approval_all require_approval_per_tool]
      
      valid_policies.each do |policy|
        expect {
          mcp_servers.update_approval_policy(server_id, approval_policy: policy)
        }.not_to raise_error
      end

      expect {
        mcp_servers.update_approval_policy(server_id, approval_policy: "invalid_policy")
      }.to raise_error(ArgumentError, /approval_policy must be one of/)
    end
  end

  describe "#create_tool_approval" do
    let(:server_id) { "mcp_server_123" }
    let(:endpoint) { "/v1/convai/mcp-servers/#{server_id}/tool-approvals" }
    let(:tool_name) { "test_tool" }
    let(:tool_description) { "A test tool" }
    let(:response) do
      {
        "id" => server_id,
        "config" => {
          "tool_approval_hashes" => [
            {
              "tool_name" => tool_name,
              "tool_hash" => "hash123",
              "approval_policy" => "auto_approved"
            }
          ]
        }
      }
    end

    before do
      allow(client).to receive(:post).with(endpoint, any_args).and_return(response)
    end

    it "creates tool approval successfully" do
      result = mcp_servers.create_tool_approval(
        server_id,
        tool_name: tool_name,
        tool_description: tool_description
      )

      expect(result).to eq(response)
    end

    it "calls the correct endpoint with correct payload" do
      mcp_servers.create_tool_approval(
        server_id,
        tool_name: tool_name,
        tool_description: tool_description
      )

      expected_body = {
        tool_name: tool_name,
        tool_description: tool_description
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "handles optional parameters" do
      input_schema = { type: "object", properties: { id: { type: "string" } } }
      approval_policy = "requires_approval"

      mcp_servers.create_tool_approval(
        server_id,
        tool_name: tool_name,
        tool_description: tool_description,
        input_schema: input_schema,
        approval_policy: approval_policy
      )

      expected_body = {
        tool_name: tool_name,
        tool_description: tool_description,
        input_schema: input_schema,
        approval_policy: approval_policy
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "requires mcp_server_id parameter" do
      expect {
        mcp_servers.create_tool_approval(
          nil,
          tool_name: tool_name,
          tool_description: tool_description
        )
      }.to raise_error(ArgumentError, "mcp_server_id is required")
    end

    it "requires tool_name parameter" do
      expect {
        mcp_servers.create_tool_approval(
          server_id,
          tool_name: nil,
          tool_description: tool_description
        )
      }.to raise_error(ArgumentError, "tool_name is required")
    end

    it "requires tool_description parameter" do
      expect {
        mcp_servers.create_tool_approval(
          server_id,
          tool_name: tool_name,
          tool_description: nil
        )
      }.to raise_error(ArgumentError, "tool_description is required")
    end
  end

  describe "#delete_tool_approval" do
    let(:server_id) { "mcp_server_123" }
    let(:tool_name) { "test_tool" }
    let(:endpoint) { "/v1/convai/mcp-servers/#{server_id}/tool-approvals/#{tool_name}" }
    let(:response) do
      {
        "id" => server_id,
        "config" => {
          "tool_approval_hashes" => []
        }
      }
    end

    before do
      allow(client).to receive(:delete).with(endpoint).and_return(response)
    end

    it "deletes tool approval successfully" do
      result = mcp_servers.delete_tool_approval(server_id, tool_name)

      expect(result).to eq(response)
    end

    it "calls the correct endpoint" do
      mcp_servers.delete_tool_approval(server_id, tool_name)

      expect(client).to have_received(:delete).with(endpoint)
    end

    it "requires mcp_server_id parameter" do
      expect {
        mcp_servers.delete_tool_approval(nil, tool_name)
      }.to raise_error(ArgumentError, "mcp_server_id is required")
    end

    it "requires tool_name parameter" do
      expect {
        mcp_servers.delete_tool_approval(server_id, nil)
      }.to raise_error(ArgumentError, "tool_name is required")
    end
  end

  describe "convenience method aliases" do
    before do
      allow(client).to receive(:get).and_return({})
      allow(client).to receive(:post).and_return({})
      allow(client).to receive(:patch).and_return({})
      allow(client).to receive(:delete).and_return({})
    end

    it "provides servers alias for list" do
      mcp_servers.servers

      expect(client).to have_received(:get).with("/v1/convai/mcp-servers")
    end

    it "provides get_server alias for get" do
      mcp_servers.get_server("server_123")

      expect(client).to have_received(:get).with("/v1/convai/mcp-servers/server_123")
    end

    it "provides update_policy alias for update_approval_policy" do
      mcp_servers.update_policy("server_123", approval_policy: "auto_approve_all")

      expect(client).to have_received(:patch).with(
        "/v1/convai/mcp-servers/server_123/approval-policy",
        { approval_policy: "auto_approve_all" }
      )
    end

    it "provides approve_tool alias for create_tool_approval" do
      mcp_servers.approve_tool(
        "server_123",
        tool_name: "test_tool",
        tool_description: "Test tool"
      )

      expect(client).to have_received(:post).with(
        "/v1/convai/mcp-servers/server_123/tool-approvals",
        { tool_name: "test_tool", tool_description: "Test tool" }
      )
    end

    it "provides remove_tool_approval alias for delete_tool_approval" do
      mcp_servers.remove_tool_approval("server_123", "test_tool")

      expect(client).to have_received(:delete).with(
        "/v1/convai/mcp-servers/server_123/tool-approvals/test_tool"
      )
    end
  end

  describe "error scenarios" do
    let(:server_id) { "mcp_server_123" }

    context "when client raises an error" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::APIError, "API Error")
      end

      it "propagates the error" do
        expect {
          mcp_servers.create(
            config: {
              url: "https://example.com",
              name: "Test",
              approval_policy: "auto_approve_all"
            }
          )
        }.to raise_error(ElevenlabsClient::APIError, "API Error")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end

      it "raises AuthenticationError" do
        expect {
          mcp_servers.list
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end
    end

    context "when server not found" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::NotFoundError, "Server not found")
      end

      it "raises NotFoundError" do
        expect {
          mcp_servers.get("nonexistent_server")
        }.to raise_error(ElevenlabsClient::NotFoundError, "Server not found")
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid configuration")
      end

      it "raises UnprocessableEntityError" do
        expect {
          mcp_servers.create(
            config: {
              url: "invalid-url",
              name: "Test",
              approval_policy: "auto_approve_all"
            }
          )
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid configuration")
      end
    end

    context "when forbidden" do
      before do
        allow(client).to receive(:patch).and_raise(ElevenlabsClient::ForbiddenError, "Access denied")
      end

      it "raises ForbiddenError" do
        expect {
          mcp_servers.update_approval_policy(server_id, approval_policy: "require_approval_all")
        }.to raise_error(ElevenlabsClient::ForbiddenError, "Access denied")
      end
    end
  end

  describe "parameter validation edge cases" do
    it "handles string server IDs with whitespace" do
      expect {
        mcp_servers.get("  mcp_server_123  ")
      }.to raise_error(URI::InvalidURIError)
    end

    it "handles empty approval policy after strip" do
      expect {
        mcp_servers.update_approval_policy("server_123", approval_policy: "   ")
      }.to raise_error(ArgumentError, "approval_policy is required")
    end

    it "handles string tool names with whitespace" do
      expect {
        mcp_servers.create_tool_approval(
          "server_123",
          tool_name: "   ",
          tool_description: "Test"
        )
      }.to raise_error(ArgumentError, "tool_name is required")
    end

    it "filters out nil options in create_tool_approval" do
      allow(client).to receive(:post).and_return({})

      mcp_servers.create_tool_approval(
        "server_123",
        tool_name: "test_tool",
        tool_description: "Test tool",
        input_schema: nil,
        approval_policy: nil,
        custom_option: "value"
      )

      expected_body = {
        tool_name: "test_tool",
        tool_description: "Test tool",
        custom_option: "value"
      }

      expect(client).to have_received(:post).with(
        "/v1/convai/mcp-servers/server_123/tool-approvals",
        expected_body
      )
    end
  end
end
