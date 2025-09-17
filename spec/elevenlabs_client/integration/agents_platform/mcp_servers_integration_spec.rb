# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Agents Platform MCP Servers Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "MCP Servers Management" do
    describe "POST /v1/convai/mcp-servers" do
      context "successful server creation" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/mcp-servers")
            .with(
              body: {
                config: {
                  url: "https://example.com/mcp",
                  name: "Test MCP Server",
                  approval_policy: "auto_approve_all",
                  transport: "SSE",
                  description: "Test server for integration"
                }
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "mcp_server_123",
                config: {
                  url: "https://example.com/mcp",
                  name: "Test MCP Server",
                  approval_policy: "auto_approve_all",
                  transport: "SSE",
                  description: "Test server for integration",
                  tool_approval_hashes: []
                },
                metadata: {
                  created_at: 1234567890,
                  owner_user_id: "user_123"
                },
                access_info: {
                  is_creator: true,
                  creator_name: "Test User",
                  creator_email: "test@example.com",
                  role: "admin"
                },
                dependent_agents: []
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates MCP server successfully" do
          result = client.mcp_servers.create(
            config: {
              url: "https://example.com/mcp",
              name: "Test MCP Server",
              approval_policy: "auto_approve_all",
              transport: "SSE",
              description: "Test server for integration"
            }
          )

          expect(result["id"]).to eq("mcp_server_123")
          expect(result["config"]["name"]).to eq("Test MCP Server")
          expect(result["config"]["approval_policy"]).to eq("auto_approve_all")
          expect(result["access_info"]["is_creator"]).to be true
          expect(result["dependent_agents"]).to be_empty
        end

        it "provides server access information" do
          result = client.mcp_servers.create(
            config: {
              url: "https://example.com/mcp",
              name: "Test MCP Server",
              approval_policy: "auto_approve_all",
              transport: "SSE",
              description: "Test server for integration"
            }
          )

          access_info = result["access_info"]
          expect(access_info["creator_name"]).to eq("Test User")
          expect(access_info["creator_email"]).to eq("test@example.com")
          expect(access_info["role"]).to eq("admin")
        end

        it "sends correct request format" do
          client.mcp_servers.create(
            config: {
              url: "https://example.com/mcp",
              name: "Test MCP Server",
              approval_policy: "auto_approve_all",
              transport: "SSE",
              description: "Test server for integration"
            }
          )

          expect(WebMock).to have_requested(:post, "#{base_url}/v1/convai/mcp-servers")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "server with authentication" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/mcp-servers")
            .with(
              body: {
                config: {
                  url: "https://secure-api.com/mcp",
                  name: "Secure MCP Server",
                  approval_policy: "require_approval_per_tool",
                  transport: "SSE",
                  secret_token: { secret_id: "secret_456" },
                  request_headers: {
                    "Authorization" => "Bearer token",
                    "Content-Type" => "application/json"
                  }
                }
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "mcp_server_456",
                config: {
                  url: "https://secure-api.com/mcp",
                  name: "Secure MCP Server",
                  approval_policy: "require_approval_per_tool",
                  transport: "SSE",
                  secret_token: { secret_id: "secret_456" },
                  request_headers: {
                    "Authorization" => "Bearer token",
                    "Content-Type" => "application/json"
                  }
                }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates secure server with authentication" do
          result = client.mcp_servers.create(
            config: {
              url: "https://secure-api.com/mcp",
              name: "Secure MCP Server",
              approval_policy: "require_approval_per_tool",
              transport: "SSE",
              secret_token: { secret_id: "secret_456" },
              request_headers: {
                "Authorization" => "Bearer token",
                "Content-Type" => "application/json"
              }
            }
          )

          expect(result["id"]).to eq("mcp_server_456")
          expect(result["config"]["secret_token"]["secret_id"]).to eq("secret_456")
          expect(result["config"]["request_headers"]["Authorization"]).to eq("Bearer token")
          expect(result["config"]["approval_policy"]).to eq("require_approval_per_tool")
        end
      end

      context "creation error scenarios" do
        context "when validation fails" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/mcp-servers")
              .to_return(status: 422, body: { detail: "Invalid server configuration" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.mcp_servers.create(
                config: {
                  url: "invalid-url",
                  name: "Test Server",
                  approval_policy: "invalid_policy"
                }
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when authentication fails" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/mcp-servers")
              .to_return(status: 401, body: { detail: "Authentication failed" }.to_json)
          end

          it "raises AuthenticationError" do
            expect {
              client.mcp_servers.create(
                config: {
                  url: "https://example.com/mcp",
                  name: "Test Server",
                  approval_policy: "auto_approve_all"
                }
              )
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end
      end
    end

    describe "GET /v1/convai/mcp-servers" do
      context "successful listing" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers")
            .to_return(
              status: 200,
              body: {
                mcp_servers: [
                  {
                    id: "mcp_server_123",
                    config: {
                      url: "https://api1.example.com/mcp",
                      name: "Customer API",
                      approval_policy: "auto_approve_all",
                      transport: "SSE",
                      tool_approval_hashes: [
                        {
                          tool_name: "get_customer",
                          tool_hash: "hash123",
                          approval_policy: "auto_approved"
                        }
                      ]
                    },
                    metadata: {
                      created_at: 1234567890,
                      owner_user_id: "user_123"
                    },
                    access_info: {
                      is_creator: true,
                      creator_name: "John Doe",
                      creator_email: "john@example.com",
                      role: "admin"
                    },
                    dependent_agents: [
                      { type: "conversational" }
                    ]
                  },
                  {
                    id: "mcp_server_456",
                    config: {
                      url: "https://api2.example.com/mcp",
                      name: "Inventory API",
                      approval_policy: "require_approval_per_tool",
                      transport: "SSE",
                      tool_approval_hashes: []
                    },
                    metadata: {
                      created_at: 1234567891,
                      owner_user_id: "user_456"
                    },
                    access_info: {
                      is_creator: false,
                      creator_name: "Jane Smith",
                      creator_email: "jane@example.com",
                      role: "viewer"
                    },
                    dependent_agents: []
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists all MCP servers in workspace" do
          result = client.mcp_servers.list

          expect(result["mcp_servers"].size).to eq(2)
          
          customer_api = result["mcp_servers"].find { |s| s["config"]["name"] == "Customer API" }
          expect(customer_api["id"]).to eq("mcp_server_123")
          expect(customer_api["config"]["approval_policy"]).to eq("auto_approve_all")
          expect(customer_api["config"]["tool_approval_hashes"].size).to eq(1)
          expect(customer_api["dependent_agents"].size).to eq(1)

          inventory_api = result["mcp_servers"].find { |s| s["config"]["name"] == "Inventory API" }
          expect(inventory_api["id"]).to eq("mcp_server_456")
          expect(inventory_api["config"]["approval_policy"]).to eq("require_approval_per_tool")
          expect(inventory_api["config"]["tool_approval_hashes"]).to be_empty
          expect(inventory_api["dependent_agents"]).to be_empty
        end

        it "provides access control information" do
          result = client.mcp_servers.list

          customer_api = result["mcp_servers"].first
          expect(customer_api["access_info"]["is_creator"]).to be true
          expect(customer_api["access_info"]["role"]).to eq("admin")

          inventory_api = result["mcp_servers"].last
          expect(inventory_api["access_info"]["is_creator"]).to be false
          expect(inventory_api["access_info"]["role"]).to eq("viewer")
        end

        it "enables server analytics" do
          result = client.mcp_servers.list
          
          servers = result["mcp_servers"]
          total_servers = servers.size
          total_tools = servers.sum { |s| s["config"]["tool_approval_hashes"].size }
          total_agents = servers.sum { |s| s["dependent_agents"].size }
          
          policies = servers.map { |s| s["config"]["approval_policy"] }
          policy_distribution = policies.group_by(&:itself).transform_values(&:count)
          
          expect(total_servers).to eq(2)
          expect(total_tools).to eq(1)
          expect(total_agents).to eq(1)
          expect(policy_distribution["auto_approve_all"]).to eq(1)
          expect(policy_distribution["require_approval_per_tool"]).to eq(1)
        end
      end

      context "empty server list" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers")
            .to_return(
              status: 200,
              body: { mcp_servers: [] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles empty server list gracefully" do
          result = client.mcp_servers.list

          expect(result["mcp_servers"]).to be_empty
        end
      end
    end

    describe "GET /v1/convai/mcp-servers/:mcp_server_id" do
      let(:server_id) { "mcp_server_123" }

      context "successful server retrieval" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers/#{server_id}")
            .to_return(
              status: 200,
              body: {
                id: server_id,
                config: {
                  url: "https://enterprise-api.com/mcp",
                  name: "Enterprise MCP Server",
                  approval_policy: "require_approval_per_tool",
                  transport: "SSE",
                  secret_token: { secret_id: "secret_789" },
                  request_headers: {
                    "Authorization" => "Bearer enterprise-token",
                    "X-API-Version" => "v2"
                  },
                  description: "Enterprise API with comprehensive tools",
                  tool_approval_hashes: [
                    {
                      tool_name: "search_customers",
                      tool_hash: "hash123",
                      approval_policy: "auto_approved"
                    },
                    {
                      tool_name: "update_customer",
                      tool_hash: "hash456",
                      approval_policy: "requires_approval"
                    },
                    {
                      tool_name: "delete_customer",
                      tool_hash: "hash789",
                      approval_policy: "requires_approval"
                    }
                  ]
                },
                metadata: {
                  created_at: 1234567890,
                  owner_user_id: "user_123"
                },
                access_info: {
                  is_creator: true,
                  creator_name: "Admin User",
                  creator_email: "admin@enterprise.com",
                  role: "admin"
                },
                dependent_agents: [
                  { type: "conversational" },
                  { type: "conversational" }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves detailed server information" do
          result = client.mcp_servers.get(server_id)

          expect(result["id"]).to eq(server_id)
          expect(result["config"]["name"]).to eq("Enterprise MCP Server")
          expect(result["config"]["approval_policy"]).to eq("require_approval_per_tool")
          expect(result["config"]["secret_token"]["secret_id"]).to eq("secret_789")
          expect(result["config"]["description"]).to eq("Enterprise API with comprehensive tools")
        end

        it "provides detailed tool approval information" do
          result = client.mcp_servers.get(server_id)

          tools = result["config"]["tool_approval_hashes"]
          expect(tools.size).to eq(3)

          auto_approved = tools.select { |t| t["approval_policy"] == "auto_approved" }
          requires_approval = tools.select { |t| t["approval_policy"] == "requires_approval" }

          expect(auto_approved.size).to eq(1)
          expect(requires_approval.size).to eq(2)

          expect(auto_approved.first["tool_name"]).to eq("search_customers")
          expect(requires_approval.map { |t| t["tool_name"] }).to include("update_customer", "delete_customer")
        end

        it "shows dependency information" do
          result = client.mcp_servers.get(server_id)

          expect(result["dependent_agents"].size).to eq(2)
          expect(result["access_info"]["is_creator"]).to be true
        end
      end

      context "server not found" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers/nonexistent")
            .to_return(status: 404, body: { detail: "MCP server not found" }.to_json)
        end

        it "raises NotFoundError" do
          expect {
            client.mcp_servers.get("nonexistent")
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end
    end

    describe "PATCH /v1/convai/mcp-servers/:mcp_server_id/approval-policy" do
      let(:server_id) { "mcp_server_123" }

      context "successful policy update" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/mcp-servers/#{server_id}/approval-policy")
            .with(
              body: { approval_policy: "require_approval_all" }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: server_id,
                config: {
                  name: "Updated Server",
                  approval_policy: "require_approval_all",
                  tool_approval_hashes: []
                }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "updates approval policy successfully" do
          result = client.mcp_servers.update_approval_policy(
            server_id,
            approval_policy: "require_approval_all"
          )

          expect(result["id"]).to eq(server_id)
          expect(result["config"]["approval_policy"]).to eq("require_approval_all")
        end

        it "sends correct request format" do
          client.mcp_servers.update_approval_policy(
            server_id,
            approval_policy: "require_approval_all"
          )

          expect(WebMock).to have_requested(:patch, "#{base_url}/v1/convai/mcp-servers/#{server_id}/approval-policy")
            .with(
              headers: { "xi-api-key" => "test-api-key" },
              body: { approval_policy: "require_approval_all" }.to_json
            )
        end
      end

      context "policy update scenarios" do
        %w[auto_approve_all require_approval_all require_approval_per_tool].each do |policy|
          before do
            stub_request(:patch, "#{base_url}/v1/convai/mcp-servers/#{server_id}/approval-policy")
              .with(body: { approval_policy: policy }.to_json)
              .to_return(
                status: 200,
                body: {
                  id: server_id,
                  config: { approval_policy: policy }
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "supports #{policy} policy" do
            result = client.mcp_servers.update_approval_policy(
              server_id,
              approval_policy: policy
            )

            expect(result["config"]["approval_policy"]).to eq(policy)
          end
        end
      end
    end

    describe "POST /v1/convai/mcp-servers/:mcp_server_id/tool-approvals" do
      let(:server_id) { "mcp_server_123" }

      context "successful tool approval" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/mcp-servers/#{server_id}/tool-approvals")
            .with(
              body: {
                tool_name: "get_customer_data",
                tool_description: "Retrieves customer information from CRM",
                input_schema: {
                  type: "object",
                  properties: {
                    customer_id: { type: "string", description: "Customer ID" }
                  },
                  required: ["customer_id"]
                },
                approval_policy: "auto_approved"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: server_id,
                config: {
                  tool_approval_hashes: [
                    {
                      tool_name: "get_customer_data",
                      tool_hash: "hash123",
                      approval_policy: "auto_approved"
                    }
                  ]
                }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates tool approval successfully" do
          result = client.mcp_servers.create_tool_approval(
            server_id,
            tool_name: "get_customer_data",
            tool_description: "Retrieves customer information from CRM",
            input_schema: {
              type: "object",
              properties: {
                customer_id: { type: "string", description: "Customer ID" }
              },
              required: ["customer_id"]
            },
            approval_policy: "auto_approved"
          )

          expect(result["id"]).to eq(server_id)
          tools = result["config"]["tool_approval_hashes"]
          expect(tools.size).to eq(1)
          expect(tools.first["tool_name"]).to eq("get_customer_data")
          expect(tools.first["approval_policy"]).to eq("auto_approved")
        end
      end

      context "batch tool approval workflow" do
        let(:tools_to_approve) do
          [
            {
              name: "search_customers",
              description: "Search customer database",
              schema: { type: "object", properties: { query: { type: "string" } } },
              policy: "auto_approved"
            },
            {
              name: "update_customer",
              description: "Update customer record",
              schema: { type: "object", properties: { id: { type: "string" }, data: { type: "object" } } },
              policy: "requires_approval"
            },
            {
              name: "delete_customer",
              description: "Delete customer record",
              schema: { type: "object", properties: { id: { type: "string" } } },
              policy: "requires_approval"
            }
          ]
        end

        before do
          tools_to_approve.each_with_index do |tool, index|
            stub_request(:post, "#{base_url}/v1/convai/mcp-servers/#{server_id}/tool-approvals")
              .with(
                body: {
                  tool_name: tool[:name],
                  tool_description: tool[:description],
                  input_schema: tool[:schema],
                  approval_policy: tool[:policy]
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  id: server_id,
                  config: {
                    tool_approval_hashes: tools_to_approve[0..index].map.with_index do |t, i|
                      {
                        tool_name: t[:name],
                        tool_hash: "hash#{i + 1}",
                        approval_policy: t[:policy]
                      }
                    end
                  }
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end
        end

        it "supports batch tool approval workflow" do
          approved_tools = []

          tools_to_approve.each do |tool|
            result = client.mcp_servers.create_tool_approval(
              server_id,
              tool_name: tool[:name],
              tool_description: tool[:description],
              input_schema: tool[:schema],
              approval_policy: tool[:policy]
            )

            approved_tools = result["config"]["tool_approval_hashes"]
          end

          expect(approved_tools.size).to eq(3)

          auto_approved = approved_tools.select { |t| t["approval_policy"] == "auto_approved" }
          requires_approval = approved_tools.select { |t| t["approval_policy"] == "requires_approval" }

          expect(auto_approved.size).to eq(1)
          expect(requires_approval.size).to eq(2)
          expect(auto_approved.first["tool_name"]).to eq("search_customers")
        end
      end
    end

    describe "DELETE /v1/convai/mcp-servers/:mcp_server_id/tool-approvals/:tool_name" do
      let(:server_id) { "mcp_server_123" }
      let(:tool_name) { "get_customer_data" }

      context "successful tool approval removal" do
        before do
          stub_request(:delete, "#{base_url}/v1/convai/mcp-servers/#{server_id}/tool-approvals/#{tool_name}")
            .to_return(
              status: 200,
              body: {
                id: server_id,
                config: {
                  tool_approval_hashes: []
                }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "removes tool approval successfully" do
          result = client.mcp_servers.delete_tool_approval(server_id, tool_name)

          expect(result["id"]).to eq(server_id)
          expect(result["config"]["tool_approval_hashes"]).to be_empty
        end

        it "sends correct request format" do
          client.mcp_servers.delete_tool_approval(server_id, tool_name)

          expect(WebMock).to have_requested(:delete, "#{base_url}/v1/convai/mcp-servers/#{server_id}/tool-approvals/#{tool_name}")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end
    end

    describe "Complete MCP Server Workflow" do
      let(:server_config) do
        {
          url: "https://workflow-api.com/mcp",
          name: "Workflow Test Server",
          approval_policy: "require_approval_per_tool",
          transport: "SSE",
          description: "Complete workflow test"
        }
      end

      before do
        # Stub server creation
        stub_request(:post, "#{base_url}/v1/convai/mcp-servers")
          .to_return(
            status: 200,
            body: {
              id: "workflow_server",
              config: server_config,
              metadata: { created_at: Time.now.to_i },
              access_info: { is_creator: true, role: "admin" },
              dependent_agents: []
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Stub tool approval
        stub_request(:post, "#{base_url}/v1/convai/mcp-servers/workflow_server/tool-approvals")
          .to_return(
            status: 200,
            body: {
              id: "workflow_server",
              config: {
                tool_approval_hashes: [
                  { tool_name: "workflow_tool", approval_policy: "auto_approved" }
                ]
              }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Stub policy update
        stub_request(:patch, "#{base_url}/v1/convai/mcp-servers/workflow_server/approval-policy")
          .to_return(
            status: 200,
            body: {
              id: "workflow_server",
              config: { approval_policy: "auto_approve_all" }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Stub server retrieval
        stub_request(:get, "#{base_url}/v1/convai/mcp-servers/workflow_server")
          .to_return(
            status: 200,
            body: {
              id: "workflow_server",
              config: {
                **server_config,
                approval_policy: "auto_approve_all",
                tool_approval_hashes: [
                  { tool_name: "workflow_tool", approval_policy: "auto_approved" }
                ]
              }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "completes full MCP server management workflow" do
        # 1. Create server
        server = client.mcp_servers.create(config: server_config)
        expect(server["id"]).to eq("workflow_server")

        # 2. Approve a tool
        updated_server = client.mcp_servers.create_tool_approval(
          server["id"],
          tool_name: "workflow_tool",
          tool_description: "Test workflow tool"
        )
        expect(updated_server["config"]["tool_approval_hashes"].size).to eq(1)

        # 3. Update approval policy
        policy_updated = client.mcp_servers.update_approval_policy(
          server["id"],
          approval_policy: "auto_approve_all"
        )
        expect(policy_updated["config"]["approval_policy"]).to eq("auto_approve_all")

        # 4. Verify final state
        final_server = client.mcp_servers.get(server["id"])
        expect(final_server["config"]["approval_policy"]).to eq("auto_approve_all")
        expect(final_server["config"]["tool_approval_hashes"].size).to eq(1)
      end
    end

    describe "Error Handling and Edge Cases" do
      context "network timeout scenarios" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers")
            .to_timeout
        end

        it "handles network timeouts appropriately" do
          expect {
            client.mcp_servers.list
          }.to raise_error(Faraday::ConnectionFailed)
        end
      end

      context "malformed response scenarios" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/mcp-servers")
            .to_return(
              status: 200,
              body: "Invalid JSON response",
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles malformed JSON responses" do
          expect {
            client.mcp_servers.list
          }.to raise_error(Faraday::ParsingError)
        end
      end

      context "forbidden access scenarios" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/mcp-servers/restricted_server/approval-policy")
            .to_return(status: 403, body: { detail: "Access denied" }.to_json)
        end

        it "handles forbidden access appropriately" do
          expect {
            client.mcp_servers.update_approval_policy(
              "restricted_server",
              approval_policy: "auto_approve_all"
            )
          }.to raise_error(ElevenlabsClient::ForbiddenError)
        end
      end
    end

    describe "Convenience Alias Methods" do
      before do
        stub_request(:get, "#{base_url}/v1/convai/mcp-servers")
          .to_return(
            status: 200,
            body: { mcp_servers: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        stub_request(:get, "#{base_url}/v1/convai/mcp-servers/test_server")
          .to_return(
            status: 200,
            body: { id: "test_server" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "supports servers alias for list" do
        client.mcp_servers.servers
        expect(WebMock).to have_requested(:get, "#{base_url}/v1/convai/mcp-servers")
      end

      it "supports get_server alias for get" do
        client.mcp_servers.get_server("test_server")
        expect(WebMock).to have_requested(:get, "#{base_url}/v1/convai/mcp-servers/test_server")
      end
    end
  end
end
