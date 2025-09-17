# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Agents Platform Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.agents accessor" do
    it "provides access to agents endpoint" do
      expect(client.agents).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::Agents)
    end
  end

  describe "agent management functionality via client" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:agent_config) do
      {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are a helpful customer support agent",
              llm: "gpt-4o-mini",
              temperature: 0.7
            },
            first_message: "Hello! How can I help you today?",
            language: "en"
          },
          tts: {
            voice_id: "cjVigY5qzO86Huf0OWal",
            model_id: "eleven_turbo_v2"
          }
        },
        name: "Customer Support Agent",
        tags: ["customer-support", "test"]
      }
    end

    describe "creating an agent" do
      let(:create_response) { { "agent_id" => agent_id } }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/create")
          .with(
            body: agent_config.to_json,
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

      it "creates agent through client interface" do
        result = client.agents.create(**agent_config)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/create")
          .with(
            body: agent_config.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "getting agent details" do
      let(:agent_response) do
        {
          "agent_id" => agent_id,
          "name" => "Customer Support Agent",
          "conversation_config" => {
            "agent" => {
              "prompt" => {
                "prompt" => "You are a helpful customer support agent",
                "llm" => "gpt-4o-mini",
                "temperature" => 0.7
              },
              "first_message" => "Hello! How can I help you today?",
              "language" => "en"
            },
            "tts" => {
              "voice_id" => "cjVigY5qzO86Huf0OWal",
              "model_id" => "eleven_turbo_v2"
            }
          },
          "metadata" => {
            "created_at_unix_secs" => 1716153600,
            "updated_at_unix_secs" => 1716153600
          },
          "tags" => ["customer-support", "test"]
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: agent_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets agent details through client interface" do
        result = client.agents.get(agent_id)

        expect(result).to eq(agent_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "listing agents" do
      let(:agents_response) do
        {
          "agents" => [
            {
              "agent_id" => agent_id,
              "name" => "Customer Support Agent",
              "tags" => ["customer-support", "test"],
              "created_at_unix_secs" => 1716153600,
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
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists agents through client interface" do
          result = client.agents.list

          expect(result).to eq(agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agents")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with query parameters" do
        let(:query_params) { "page_size=10&search=support&sort_by=name&sort_direction=asc" }

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists agents with query parameters through client interface" do
          result = client.agents.list(
            page_size: 10,
            search: "support",
            sort_by: "name",
            sort_direction: "asc"
          )

          expect(result).to eq(agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "updating an agent" do
      let(:update_params) do
        {
          name: "Updated Customer Support Agent",
          tags: ["customer-support", "updated"],
          conversation_config: {
            agent: {
              first_message: "Hi there! I'm your updated support assistant."
            }
          }
        }
      end

      let(:update_response) do
        {
          "agent_id" => agent_id,
          "name" => "Updated Customer Support Agent",
          "conversation_config" => {
            "agent" => {
              "first_message" => "Hi there! I'm your updated support assistant."
            }
          },
          "tags" => ["customer-support", "updated"]
        }
      end

      before do
        stub_request(:patch, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(
            body: update_params.to_json,
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

      it "updates agent through client interface" do
        result = client.agents.update(agent_id, **update_params)

        expect(result).to eq(update_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(
            body: update_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "deleting an agent" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes agent through client interface" do
        result = client.agents.delete(agent_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "duplicating an agent" do
      let(:source_agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
      let(:new_agent_id) { "K4Qcv6rQ7OOLCtdeDwC" }
      let(:duplicate_params) { { name: "Duplicated Agent" } }
      let(:duplicate_response) { { "agent_id" => new_agent_id } }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{source_agent_id}/duplicate")
          .with(
            body: duplicate_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: duplicate_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "duplicates agent through client interface" do
        result = client.agents.duplicate(source_agent_id, **duplicate_params)

        expect(result).to eq(duplicate_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{source_agent_id}/duplicate")
          .with(
            body: duplicate_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "getting agent link" do
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
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/link")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: link_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets agent link through client interface" do
        result = client.agents.link(agent_id)

        expect(result).to eq(link_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/link")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "simulating conversation" do
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/simulate-conversation")
          .with(
            body: simulation_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: simulation_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "simulates conversation through client interface" do
        result = client.agents.simulate_conversation(agent_id, **simulation_params)

        expect(result).to eq(simulation_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/simulate-conversation")
          .with(
            body: simulation_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "calculating LLM usage" do
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent/#{agent_id}/llm-usage/calculate")
          .with(
            body: usage_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: usage_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "calculates LLM usage through client interface" do
        result = client.agents.calculate_llm_usage(agent_id, **usage_params)

        expect(result).to eq(usage_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent/#{agent_id}/llm-usage/calculate")
          .with(
            body: usage_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "streaming conversation simulation" do
      let(:simulation_params) do
        {
          simulation_specification: {
            simulated_user_config: {
              persona: "A customer with a technical question"
            }
          }
        }
      end

      before do
        # Mock the streaming response
        allow(client).to receive(:post_streaming)
          .with("/v1/convai/agents/#{agent_id}/simulate-conversation/stream", simulation_params)
          .and_return("streaming_response")
      end

      it "starts streaming simulation through client interface" do
        result = client.agents.simulate_conversation_stream(agent_id, **simulation_params)

        expect(result).to eq("streaming_response")
        expect(client).to have_received(:post_streaming)
          .with("/v1/convai/agents/#{agent_id}/simulate-conversation/stream", simulation_params)
      end
    end
  end

  describe "error handling integration" do
    let(:agent_id) { "nonexistent_agent" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Agent not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing agent" do
        expect { client.agents.get(agent_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.agents.list }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      let(:invalid_config) { { conversation_config: {} } }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/create")
          .with(
            body: invalid_config.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Validation failed: conversation_config is required" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.agents.create(**invalid_config) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "full workflow integration" do
    let(:agent_id) { "J3Pbu5gP6NNKBscdCdwB" }
    let(:new_agent_id) { "K4Qcv6rQ7OOLCtdeDwC" }

    it "supports complete agent lifecycle" do
      # Create agent
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/create")
        .to_return(
          status: 200,
          body: { "agent_id" => agent_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get agent
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
        .to_return(
          status: 200,
          body: { "agent_id" => agent_id, "name" => "Test Agent" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Update agent
      stub_request(:patch, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
        .to_return(
          status: 200,
          body: { "agent_id" => agent_id, "name" => "Updated Test Agent" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Duplicate agent
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/duplicate")
        .to_return(
          status: 200,
          body: { "agent_id" => new_agent_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Delete agent
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      create_result = client.agents.create(conversation_config: { agent: { prompt: { prompt: "Test" } } })
      expect(create_result["agent_id"]).to eq(agent_id)

      get_result = client.agents.get(agent_id)
      expect(get_result["agent_id"]).to eq(agent_id)

      update_result = client.agents.update(agent_id, name: "Updated Test Agent")
      expect(update_result["name"]).to eq("Updated Test Agent")

      duplicate_result = client.agents.duplicate(agent_id, name: "Duplicated Agent")
      expect(duplicate_result["agent_id"]).to eq(new_agent_id)

      delete_result = client.agents.delete(agent_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/create")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/duplicate")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}")
    end
  end
end
