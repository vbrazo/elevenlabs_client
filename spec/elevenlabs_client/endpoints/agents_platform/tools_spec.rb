# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Tools do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:tools) { described_class.new(client) }

  describe "#list" do
    let(:list_response) do
      {
        "tools" => [
          {
            "id" => "tool123",
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
      allow(client).to receive(:get).with("/v1/convai/tools")
                                   .and_return(list_response)
    end

    it "lists tools successfully" do
      result = tools.list
      expect(result).to eq(list_response)
      expect(client).to have_received(:get).with("/v1/convai/tools")
    end
  end

  describe "#get" do
    let(:tool_id) { "tool123" }
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
      allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}")
                                   .and_return(tool_response)
    end

    it "retrieves tool details successfully" do
      result = tools.get(tool_id)
      expect(result).to eq(tool_response)
      expect(client).to have_received(:get).with("/v1/convai/tools/#{tool_id}")
    end
  end

  describe "#create" do
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
      allow(client).to receive(:post).with("/v1/convai/tools", { tool_config: tool_config })
                                    .and_return(create_response)
    end

    it "creates tool successfully" do
      result = tools.create(tool_config: tool_config)
      expect(result).to eq(create_response)
      expect(client).to have_received(:post).with("/v1/convai/tools", { tool_config: tool_config })
    end
  end

  describe "#update" do
    let(:tool_id) { "tool123" }
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
      allow(client).to receive(:patch).with("/v1/convai/tools/#{tool_id}", { tool_config: tool_config })
                                     .and_return(update_response)
    end

    it "updates tool successfully" do
      result = tools.update(tool_id, tool_config: tool_config)
      expect(result).to eq(update_response)
      expect(client).to have_received(:patch).with("/v1/convai/tools/#{tool_id}", { tool_config: tool_config })
    end
  end

  describe "#delete" do
    let(:tool_id) { "tool123" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/tools/#{tool_id}")
                                      .and_return(delete_response)
    end

    it "deletes tool successfully" do
      result = tools.delete(tool_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/tools/#{tool_id}")
    end
  end

  describe "#get_dependent_agents" do
    let(:tool_id) { "tool123" }
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
        allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents")
                                     .and_return(dependent_agents_response)
      end

      it "gets dependent agents successfully" do
        result = tools.get_dependent_agents(tool_id)
        expect(result).to eq(dependent_agents_response)
        expect(client).to have_received(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents")
      end
    end

    context "with parameters" do
      let(:params) { { page_size: 10, cursor: "cursor123" } }

      before do
        allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents?page_size=10&cursor=cursor123")
                                     .and_return(dependent_agents_response)
      end

      it "gets dependent agents with query parameters" do
        result = tools.get_dependent_agents(tool_id, **params)
        expect(result).to eq(dependent_agents_response)
        expect(client).to have_received(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents?page_size=10&cursor=cursor123")
      end
    end
  end

  describe "error handling" do
    let(:tool_id) { "nonexistent_tool" }

    context "when tool is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Tool not found")
      end

      it "raises NotFoundError" do
        expect { tools.get(tool_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Tool not found")
      end
    end

    context "when validation fails" do
      let(:invalid_config) { { name: "" } }

      before do
        allow(client).to receive(:post).with("/v1/convai/tools", { tool_config: invalid_config })
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Validation failed")
      end

      it "raises UnprocessableEntityError" do
        expect { tools.create(tool_config: invalid_config) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Validation failed")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/tools")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { tools.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "parameter handling" do
    describe "#get_dependent_agents" do
      let(:tool_id) { "tool123" }

      context "with nil parameters" do
        let(:params) { { page_size: 10, cursor: nil } }
        let(:expected_query) { "page_size=10" }

        before do
          allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents?#{expected_query}")
                                       .and_return({ "agents" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          tools.get_dependent_agents(tool_id, **params)
          expect(client).to have_received(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents?#{expected_query}")
        end
      end

      context "with empty parameters" do
        before do
          allow(client).to receive(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents")
                                       .and_return({ "agents" => [], "has_more" => false })
        end

        it "makes request without query parameters" do
          tools.get_dependent_agents(tool_id)
          expect(client).to have_received(:get).with("/v1/convai/tools/#{tool_id}/dependent-agents")
        end
      end
    end
  end

  describe "complex tool configurations" do
    describe "POST request tool" do
      let(:post_tool_config) do
        {
          name: "Create Support Ticket",
          description: "Create a new support ticket",
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
                  enum: ["low", "medium", "high", "urgent"]
                }
              },
              required: ["title", "description"]
            },
            request_headers: {
              "Authorization" => "Bearer ${API_KEY}",
              "Content-Type" => "application/json"
            }
          },
          response_timeout_secs: 30,
          assignments: [
            {
              source: "response",
              dynamic_variable: "ticket_id",
              value_path: "$.ticket.id"
            }
          ]
        }
      end

      let(:create_response) do
        {
          "id" => "tool789",
          "tool_config" => post_tool_config.merge("type" => "webhook")
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/tools", { tool_config: post_tool_config })
                                      .and_return(create_response)
      end

      it "creates POST tool with complex schema successfully" do
        result = tools.create(tool_config: post_tool_config)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/tools", { tool_config: post_tool_config })
      end
    end

    describe "tool with dynamic variables" do
      let(:tool_with_variables) do
        {
          name: "CRM Integration",
          description: "Advanced CRM integration with dynamic variables",
          api_schema: {
            url: "https://api.crm.com/customers",
            method: "GET"
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
          "tool_config" => tool_with_variables.merge("type" => "webhook")
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/tools", { tool_config: tool_with_variables })
                                      .and_return(create_response)
      end

      it "creates tool with dynamic variables successfully" do
        result = tools.create(tool_config: tool_with_variables)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/tools", { tool_config: tool_with_variables })
      end
    end
  end
end
