# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Tools Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.tools accessor" do
    it "provides access to tools endpoint" do
      expect(client.tools).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::Tools)
    end
  end

  describe "tool management functionality via client" do
    let(:tool_id) { "tool123" }

    describe "listing tools" do
      let(:tools_response) do
        {
          "tools" => [
            {
              "id" => tool_id,
              "tool_config" => {
                "type" => "webhook",
                "name" => "Weather API",
                "description" => "Get current weather information",
                "response_timeout_secs" => 20,
                "disable_interruptions" => false,
                "force_pre_tool_speech" => false,
                "api_schema" => {
                  "url" => "https://api.weather.com/v1/current",
                  "method" => "GET",
                  "query_params_schema" => {
                    "properties" => {
                      "city" => {
                        "type" => "string",
                        "description" => "City name"
                      }
                    },
                    "required" => ["city"]
                  }
                }
              },
              "access_info" => {
                "is_creator" => true,
                "creator_name" => "John Doe",
                "creator_email" => "john@example.com",
                "role" => "admin"
              },
              "usage_stats" => {
                "avg_latency_secs" => 1.5,
                "total_calls" => 150
              }
            }
          ]
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: tools_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "lists tools through client interface" do
        result = client.tools.list

        expect(result).to eq(tools_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting tool details" do
      let(:tool_response) do
        {
          "id" => tool_id,
          "tool_config" => {
            "type" => "webhook",
            "name" => "Weather API",
            "description" => "Get current weather information for any city",
            "response_timeout_secs" => 30,
            "disable_interruptions" => false,
            "force_pre_tool_speech" => false,
            "assignments" => [
              {
                "source" => "response",
                "dynamic_variable" => "temperature",
                "value_path" => "$.main.temp"
              }
            ],
            "api_schema" => {
              "url" => "https://api.weather.com/v1/current",
              "method" => "GET",
              "query_params_schema" => {
                "properties" => {
                  "city" => {
                    "type" => "string",
                    "description" => "City name"
                  },
                  "units" => {
                    "type" => "string",
                    "enum" => ["metric", "imperial"]
                  }
                },
                "required" => ["city"]
              },
              "request_headers" => {
                "Authorization" => "Bearer API_KEY"
              }
            }
          },
          "access_info" => {
            "is_creator" => true,
            "creator_name" => "John Doe",
            "creator_email" => "john@example.com",
            "role" => "admin"
          },
          "usage_stats" => {
            "avg_latency_secs" => 1.5,
            "total_calls" => 150
          }
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: tool_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets tool details through client interface" do
        result = client.tools.get(tool_id)

        expect(result).to eq(tool_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "creating tool" do
      let(:tool_config) do
        {
          name: "Customer Database",
          description: "Query customer information from CRM",
          api_schema: {
            url: "https://api.crm.com/customers",
            method: "GET",
            query_params_schema: {
              properties: {
                customer_id: {
                  type: "string",
                  description: "Customer ID"
                }
              },
              required: ["customer_id"]
            }
          },
          response_timeout_secs: 25
        }
      end

      let(:create_response) do
        {
          "id" => "tool456",
          "tool_config" => {
            "type" => "webhook",
            "name" => "Customer Database",
            "description" => "Query customer information from CRM",
            "response_timeout_secs" => 25,
            "disable_interruptions" => false,
            "force_pre_tool_speech" => false,
            "api_schema" => {
              "url" => "https://api.crm.com/customers",
              "method" => "GET",
              "query_params_schema" => {
                "properties" => {
                  "customer_id" => {
                    "type" => "string",
                    "description" => "Customer ID"
                  }
                },
                "required" => ["customer_id"]
              }
            }
          },
          "access_info" => {
            "is_creator" => true,
            "creator_name" => "John Doe",
            "creator_email" => "john@example.com",
            "role" => "admin"
          },
          "usage_stats" => {
            "avg_latency_secs" => 0.0,
            "total_calls" => 0
          }
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates tool through client interface" do
        result = client.tools.create(tool_config: tool_config)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "updating tool" do
      let(:tool_config) do
        {
          name: "Enhanced Weather API",
          description: "Get current weather and forecast information",
          response_timeout_secs: 45,
          api_schema: {
            url: "https://api.weather.com/v2/current-and-forecast",
            method: "GET"
          }
        }
      end

      let(:update_response) do
        {
          "id" => tool_id,
          "tool_config" => {
            "type" => "webhook",
            "name" => "Enhanced Weather API",
            "description" => "Get current weather and forecast information",
            "response_timeout_secs" => 45,
            "api_schema" => {
              "url" => "https://api.weather.com/v2/current-and-forecast",
              "method" => "GET"
            }
          }
        }
      end

      before do
        stub_request(:patch, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(
            body: { tool_config: tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: update_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "updates tool through client interface" do
        result = client.tools.update(tool_id, tool_config: tool_config)

        expect(result).to eq(update_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(
            body: { tool_config: tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "deleting tool" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes tool through client interface" do
        result = client.tools.delete(tool_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting dependent agents" do
      let(:dependent_agents_response) do
        {
          "agents" => [
            {
              "id" => "agent123",
              "name" => "Customer Support Agent",
              "type" => "conversational"
            },
            {
              "id" => "agent456",
              "name" => "Sales Agent",
              "type" => "conversational"
            }
          ],
          "has_more" => false,
          "next_cursor" => nil
        }
      end

      context "without parameters" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}/dependent-agents")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: dependent_agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets dependent agents through client interface" do
          result = client.tools.get_dependent_agents(tool_id)

          expect(result).to eq(dependent_agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}/dependent-agents")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with query parameters" do
        let(:query_params) { "page_size=10&cursor=cursor123" }

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}/dependent-agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: dependent_agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets dependent agents with parameters through client interface" do
          result = client.tools.get_dependent_agents(tool_id, page_size: 10, cursor: "cursor123")

          expect(result).to eq(dependent_agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}/dependent-agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end
  end

  describe "error handling integration" do
    let(:tool_id) { "nonexistent_tool" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{tool_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Tool not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing tool" do
        expect { client.tools.get(tool_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.tools.list }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      let(:invalid_config) { { name: "" } }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: invalid_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Validation failed: name is required" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.tools.create(tool_config: invalid_config) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "complex tool creation integration" do
    describe "POST request tool with full schema" do
      let(:post_tool_config) do
        {
          name: "Create Support Ticket",
          description: "Create a new support ticket in the system",
          api_schema: {
            url: "https://api.helpdesk.com/tickets",
            method: "POST",
            request_body_schema: {
              type: "object",
              properties: {
                title: {
                  type: "string",
                  description: "Ticket title"
                },
                description: {
                  type: "string",
                  description: "Issue description"
                },
                priority: {
                  type: "string",
                  enum: ["low", "medium", "high", "urgent"],
                  description: "Priority level"
                },
                customer_email: {
                  type: "string",
                  format: "email",
                  description: "Customer email"
                }
              },
              required: ["title", "description", "customer_email"]
            },
            request_headers: {
              "Authorization" => "Bearer ${API_KEY}",
              "Content-Type" => "application/json"
            }
          },
          response_timeout_secs: 30,
          disable_interruptions: true,
          assignments: [
            {
              source: "response",
              dynamic_variable: "ticket_id",
              value_path: "$.ticket.id"
            },
            {
              source: "response",
              dynamic_variable: "ticket_url",
              value_path: "$.ticket.url"
            }
          ]
        }
      end

      let(:create_response) do
        {
          "id" => "tool789",
          "tool_config" => {
            "type" => "webhook",
            "name" => "Create Support Ticket",
            "description" => "Create a new support ticket in the system",
            "api_schema" => {
              "url" => "https://api.helpdesk.com/tickets",
              "method" => "POST",
              "request_body_schema" => {
                "type" => "object",
                "properties" => {
                  "title" => {
                    "type" => "string",
                    "description" => "Ticket title"
                  },
                  "description" => {
                    "type" => "string",
                    "description" => "Issue description"
                  },
                  "priority" => {
                    "type" => "string",
                    "enum" => ["low", "medium", "high", "urgent"],
                    "description" => "Priority level"
                  },
                  "customer_email" => {
                    "type" => "string",
                    "format" => "email",
                    "description" => "Customer email"
                  }
                },
                "required" => ["title", "description", "customer_email"]
              },
              "request_headers" => {
                "Authorization" => "Bearer ${API_KEY}",
                "Content-Type" => "application/json"
              }
            },
            "response_timeout_secs" => 30,
            "disable_interruptions" => true,
            "assignments" => [
              {
                "source" => "response",
                "dynamic_variable" => "ticket_id",
                "value_path" => "$.ticket.id"
              },
              {
                "source" => "response",
                "dynamic_variable" => "ticket_url",
                "value_path" => "$.ticket.url"
              }
            ]
          }
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: post_tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates complex POST tool through client interface" do
        result = client.tools.create(tool_config: post_tool_config)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: post_tool_config }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "tool with dynamic variables" do
      let(:tool_with_variables) do
        {
          name: "CRM Integration",
          description: "Advanced CRM integration with dynamic variables",
          api_schema: {
            url: "https://api.crm.com/customers",
            method: "GET",
            query_params_schema: {
              properties: {
                customer_id: {
                  type: "string",
                  description: "Customer ID"
                }
              },
              required: ["customer_id"]
            }
          },
          dynamic_variables: {
            dynamic_variable_placeholders: {
              "customer_name" => "Unknown Customer",
              "customer_tier" => "Standard"
            }
          },
          assignments: [
            {
              source: "response",
              dynamic_variable: "customer_name",
              value_path: "$.customer.name"
            },
            {
              source: "response",
              dynamic_variable: "customer_tier",
              value_path: "$.customer.tier"
            }
          ]
        }
      end

      let(:create_response) do
        {
          "id" => "tool999",
          "tool_config" => {
            "type" => "webhook",
            "name" => "CRM Integration",
            "description" => "Advanced CRM integration with dynamic variables",
            "api_schema" => {
              "url" => "https://api.crm.com/customers",
              "method" => "GET",
              "query_params_schema" => {
                "properties" => {
                  "customer_id" => {
                    "type" => "string",
                    "description" => "Customer ID"
                  }
                },
                "required" => ["customer_id"]
              }
            },
            "dynamic_variables" => {
              "dynamic_variable_placeholders" => {
                "customer_name" => "Unknown Customer",
                "customer_tier" => "Standard"
              }
            },
            "assignments" => [
              {
                "source" => "response",
                "dynamic_variable" => "customer_name",
                "value_path" => "$.customer.name"
              },
              {
                "source" => "response",
                "dynamic_variable" => "customer_tier",
                "value_path" => "$.customer.tier"
              }
            ]
          }
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: tool_with_variables }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates tool with dynamic variables through client interface" do
        result = client.tools.create(tool_config: tool_with_variables)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/tools")
          .with(
            body: { tool_config: tool_with_variables }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end
  end

  describe "full workflow integration" do
    let(:tool_id) { "tool123" }
    let(:new_tool_id) { "tool456" }

    it "supports complete tool lifecycle" do
      # List tools
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools")
        .to_return(
          status: 200,
          body: { "tools" => [{ "id" => tool_id, "tool_config" => { "name" => "Test Tool" } }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Create tool
      tool_config = {
        name: "Weather API",
        description: "Get weather information",
        api_schema: { url: "https://api.weather.com", method: "GET" }
      }

      stub_request(:post, "https://api.elevenlabs.io/v1/convai/tools")
        .to_return(
          status: 200,
          body: { "id" => new_tool_id, "tool_config" => tool_config }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get tool details
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
        .to_return(
          status: 200,
          body: { "id" => new_tool_id, "tool_config" => tool_config }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Update tool
      updated_config = tool_config.merge(description: "Enhanced weather API")
      stub_request(:patch, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
        .to_return(
          status: 200,
          body: { "id" => new_tool_id, "tool_config" => updated_config }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get dependent agents
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}/dependent-agents")
        .to_return(
          status: 200,
          body: { "agents" => [], "has_more" => false }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Delete tool
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      list_result = client.tools.list
      expect(list_result["tools"].first["id"]).to eq(tool_id)

      create_result = client.tools.create(tool_config: tool_config)
      expect(create_result["id"]).to eq(new_tool_id)

      get_result = client.tools.get(new_tool_id)
      expect(get_result["id"]).to eq(new_tool_id)

      update_result = client.tools.update(new_tool_id, tool_config: updated_config)
      expect(update_result["tool_config"]["description"]).to eq("Enhanced weather API")

      agents_result = client.tools.get_dependent_agents(new_tool_id)
      expect(agents_result["agents"]).to eq([])

      delete_result = client.tools.delete(new_tool_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/tools")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}/dependent-agents")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/tools/#{new_tool_id}")
    end
  end
end
