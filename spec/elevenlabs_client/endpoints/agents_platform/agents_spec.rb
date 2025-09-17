# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Agents do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:agents) { described_class.new(client) }

  describe "#create" do
    let(:agent_request) do
      {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are a helpful assistant",
              llm: "gpt-4o-mini"
            },
            first_message: "Hello! How can I help you?"
          }
        },
        name: "Test Agent",
        tags: ["test", "demo"]
      }
    end

    let(:agent_response) do
      {
        "agent_id" => "J3Pbu5gP6NNKBscdCdwB"
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agents/create", agent_request)
                                    .and_return(agent_response)
    end

    it "creates an agent successfully" do
      result = agents.create(**agent_request)
      expect(result).to eq(agent_response)
      expect(client).to have_received(:post).with("/v1/convai/agents/create", agent_request)
    end
  end

  describe "#get" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:agent_response) do
      {
        "agent_id" => agent_id,
        "name" => "Test Agent",
        "conversation_config" => {
          "agent" => {
            "prompt" => {
              "prompt" => "You are a helpful assistant",
              "llm" => "gpt-4o-mini"
            },
            "first_message" => "Hello! How can I help you?",
            "language" => "en"
          }
        },
        "metadata" => {
          "created_at_unix_secs" => 1716153600,
          "updated_at_unix_secs" => 1716153600
        },
        "tags" => ["test", "demo"]
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/agents/#{agent_id}")
                                   .and_return(agent_response)
    end

    it "retrieves an agent successfully" do
      result = agents.get(agent_id)
      expect(result).to eq(agent_response)
      expect(client).to have_received(:get).with("/v1/convai/agents/#{agent_id}")
    end
  end

  describe "#list" do
    let(:list_response) do
      {
        "agents" => [
          {
            "agent_id" => "J3Pbu5gP6NNKBscdCdwB",
            "name" => "Test Agent 1",
            "tags" => ["test"],
            "created_at_unix_secs" => 1716153600,
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "Test User",
              "creator_email" => "test@example.com",
              "role" => "admin"
            }
          },
          {
            "agent_id" => "K4Qcv6rQ7OOLCtdeDwC",
            "name" => "Test Agent 2",
            "tags" => ["demo"],
            "created_at_unix_secs" => 1716140000,
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "Test User",
              "creator_email" => "test@example.com",
              "role" => "admin"
            }
          }
        ],
        "has_more" => false,
        "next_cursor" => nil
      }
    end

    context "without parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/agents")
                                     .and_return(list_response)
      end

      it "lists agents successfully" do
        result = agents.list
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/agents")
      end
    end

    context "with parameters" do
      let(:params) { { page_size: 10, search: "test", sort_by: "name", sort_direction: "asc" } }

      before do
        allow(client).to receive(:get).with("/v1/convai/agents?page_size=10&search=test&sort_by=name&sort_direction=asc")
                                     .and_return(list_response)
      end

      it "lists agents with query parameters" do
        result = agents.list(**params)
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/agents?page_size=10&search=test&sort_by=name&sort_direction=asc")
      end
    end
  end

  describe "#update" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:update_params) do
      {
        name: "Updated Agent",
        tags: ["updated", "test"],
        conversation_config: {
          agent: {
            first_message: "Hello! I'm your updated assistant."
          }
        }
      }
    end

    let(:updated_response) do
      {
        "agent_id" => agent_id,
        "name" => "Updated Agent",
        "conversation_config" => {
          "agent" => {
            "first_message" => "Hello! I'm your updated assistant."
          }
        },
        "tags" => ["updated", "test"]
      }
    end

    before do
      allow(client).to receive(:patch).with("/v1/convai/agents/#{agent_id}", update_params)
                                     .and_return(updated_response)
    end

    it "updates an agent successfully" do
      result = agents.update(agent_id, **update_params)
      expect(result).to eq(updated_response)
      expect(client).to have_received(:patch).with("/v1/convai/agents/#{agent_id}", update_params)
    end
  end

  describe "#delete" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/agents/#{agent_id}")
                                      .and_return(delete_response)
    end

    it "deletes an agent successfully" do
      result = agents.delete(agent_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/agents/#{agent_id}")
    end
  end

  describe "#duplicate" do
    let(:source_agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:duplicate_params) { { name: "Duplicated Agent" } }
    let(:duplicate_response) do
      {
        "agent_id" => "K4Qcv6rQ7OOLCtdeDwC"
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agents/#{source_agent_id}/duplicate", duplicate_params)
                                    .and_return(duplicate_response)
    end

    it "duplicates an agent successfully" do
      result = agents.duplicate(source_agent_id, **duplicate_params)
      expect(result).to eq(duplicate_response)
      expect(client).to have_received(:post).with("/v1/convai/agents/#{source_agent_id}/duplicate", duplicate_params)
    end
  end

  describe "#link" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:link_response) do
      {
        "agent_id" => agent_id,
        "token" => {
          "token" => "abc123def456",
          "expires_at_unix_secs" => 1719745200,
          "created_at_unix_secs" => 1716153600,
          "is_active" => true,
          "usage_count" => 0
        }
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/agents/#{agent_id}/link")
                                   .and_return(link_response)
    end

    it "retrieves agent link information successfully" do
      result = agents.link(agent_id)
      expect(result).to eq(link_response)
      expect(client).to have_received(:get).with("/v1/convai/agents/#{agent_id}/link")
    end
  end

  describe "#simulate_conversation" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:simulation_params) do
      {
        simulation_specification: {
          simulated_user_config: {
            persona: "A customer with a billing question"
          }
        },
        extra_evaluation_criteria: [
          {
            name: "Helpfulness",
            description: "How helpful was the agent's response?"
          }
        ],
        new_turns_limit: 10
      }
    end

    let(:simulation_response) do
      {
        "simulated_conversation" => [
          {
            "role" => "user",
            "time_in_call_secs" => 1,
            "message" => "I have a question about my bill",
            "source_medium" => "audio"
          },
          {
            "role" => "agent",
            "time_in_call_secs" => 3,
            "message" => "I'd be happy to help you with your billing question. What specific information do you need?",
            "source_medium" => "audio"
          }
        ],
        "analysis" => {
          "call_successful" => "success",
          "transcript_summary" => "Customer inquired about billing, agent offered assistance",
          "evaluation_criteria_results" => {
            "Helpfulness" => "5"
          },
          "call_summary_title" => "Billing Inquiry"
        }
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agents/#{agent_id}/simulate-conversation", simulation_params)
                                    .and_return(simulation_response)
    end

    it "simulates a conversation successfully" do
      result = agents.simulate_conversation(agent_id, **simulation_params)
      expect(result).to eq(simulation_response)
      expect(client).to have_received(:post).with("/v1/convai/agents/#{agent_id}/simulate-conversation", simulation_params)
    end
  end

  describe "#simulate_conversation_stream" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:simulation_params) do
      {
        simulation_specification: {
          simulated_user_config: {
            persona: "A customer with a technical question"
          }
        }
      }
    end

    let(:streaming_response) { "streaming_data_chunk" }

    before do
      allow(client).to receive(:post_streaming).with("/v1/convai/agents/#{agent_id}/simulate-conversation/stream", simulation_params)
                                              .and_return(streaming_response)
    end

    it "starts streaming simulation successfully" do
      result = agents.simulate_conversation_stream(agent_id, **simulation_params)
      expect(result).to eq(streaming_response)
      expect(client).to have_received(:post_streaming).with("/v1/convai/agents/#{agent_id}/simulate-conversation/stream", simulation_params)
    end

    context "with block" do
      it "passes block to streaming method" do
        block = proc { |chunk| puts chunk }
        agents.simulate_conversation_stream(agent_id, **simulation_params, &block)
        expect(client).to have_received(:post_streaming).with("/v1/convai/agents/#{agent_id}/simulate-conversation/stream", simulation_params)
      end
    end
  end

  describe "#calculate_llm_usage" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:usage_params) do
      {
        prompt_length: 500,
        number_of_pages: 10,
        rag_enabled: true
      }
    end

    let(:usage_response) do
      {
        "llm_prices" => [
          {
            "llm" => "gpt-4o-mini",
            "price_per_minute" => 0.15
          },
          {
            "llm" => "gpt-4o",
            "price_per_minute" => 0.75
          }
        ]
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agent/#{agent_id}/llm-usage/calculate", usage_params)
                                    .and_return(usage_response)
    end

    it "calculates LLM usage successfully" do
      result = agents.calculate_llm_usage(agent_id, **usage_params)
      expect(result).to eq(usage_response)
      expect(client).to have_received(:post).with("/v1/convai/agent/#{agent_id}/llm-usage/calculate", usage_params)
    end

    context "without parameters" do
      before do
        allow(client).to receive(:post).with("/v1/convai/agent/#{agent_id}/llm-usage/calculate", {})
                                      .and_return(usage_response)
      end

      it "calculates usage with default parameters" do
        result = agents.calculate_llm_usage(agent_id)
        expect(result).to eq(usage_response)
        expect(client).to have_received(:post).with("/v1/convai/agent/#{agent_id}/llm-usage/calculate", {})
      end
    end
  end

  describe "error handling" do
    let(:agent_id) { "nonexistent_agent" }

    context "when agent is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/agents/#{agent_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Agent not found")
      end

      it "raises NotFoundError" do
        expect { agents.get(agent_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Agent not found")
      end
    end

    context "when validation fails" do
      let(:invalid_request) { { conversation_config: {} } }

      before do
        allow(client).to receive(:post).with("/v1/convai/agents/create", invalid_request)
                                      .and_raise(ElevenlabsClient::ValidationError, "Validation failed")
      end

      it "raises ValidationError" do
        expect { agents.create(**invalid_request) }.to raise_error(ElevenlabsClient::ValidationError, "Validation failed")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/agents")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { agents.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "parameter handling" do
    describe "#list" do
      context "with nil parameters" do
        let(:params) { { page_size: 10, search: nil, sort_by: "name" } }
        let(:expected_query) { "page_size=10&sort_by=name" }

        before do
          allow(client).to receive(:get).with("/v1/convai/agents?#{expected_query}")
                                       .and_return({ "agents" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          agents.list(**params)
          expect(client).to have_received(:get).with("/v1/convai/agents?#{expected_query}")
        end
      end
    end

    describe "#update" do
      let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }

      context "with nil parameters" do
        let(:params) { { name: "Updated Agent", tags: nil, conversation_config: { agent: { language: "en" } } } }
        let(:expected_body) { { name: "Updated Agent", conversation_config: { agent: { language: "en" } } } }

        before do
          allow(client).to receive(:patch).with("/v1/convai/agents/#{agent_id}", expected_body)
                                         .and_return({ "agent_id" => agent_id })
        end

        it "filters out nil parameters" do
          agents.update(agent_id, **params)
          expect(client).to have_received(:patch).with("/v1/convai/agents/#{agent_id}", expected_body)
        end
      end
    end
  end
end
