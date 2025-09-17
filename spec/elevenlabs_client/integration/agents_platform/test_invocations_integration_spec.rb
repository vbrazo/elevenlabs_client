# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Test Invocations Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.test_invocations accessor" do
    it "provides access to test invocations endpoint" do
      expect(client.test_invocations).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::TestInvocations)
    end
  end

  describe "test invocation management functionality via client" do
    let(:test_invocation_id) { "invocation123" }

    describe "getting test invocation details" do
      let(:invocation_response) do
        {
          "id" => test_invocation_id,
          "test_runs" => [
            {
              "test_run_id" => "run1",
              "test_invocation_id" => test_invocation_id,
              "agent_id" => "agent123",
              "status" => "completed",
              "test_id" => "test1",
              "workflow_node_id" => "node123",
              "agent_responses" => [
                {
                  "role" => "assistant",
                  "time_in_call_secs" => 2,
                  "message" => "Hello! How can I help you?",
                  "multivoice_message" => {
                    "parts" => [
                      {
                        "text" => "Hello! How can I help you?",
                        "voice_label" => "default",
                        "time_in_call_secs" => 2
                      }
                    ]
                  },
                  "tool_calls" => [],
                  "tool_results" => [],
                  "feedback" => {
                    "score" => "like",
                    "time_in_call_secs" => 5
                  },
                  "llm_override" => nil,
                  "conversation_turn_metrics" => {
                    "metrics" => {}
                  },
                  "rag_retrieval_info" => {
                    "chunks" => [
                      {
                        "document_id" => "doc123",
                        "chunk_id" => "chunk456",
                        "vector_distance" => 0.8
                      }
                    ],
                    "embedding_model" => "e5_mistral_7b_instruct",
                    "retrieval_query" => "help assistance",
                    "rag_latency_secs" => 0.5
                  },
                  "llm_usage" => {
                    "model_usage" => {}
                  },
                  "interrupted" => false,
                  "original_message" => "Hello! How can I help you?",
                  "source_medium" => "audio"
                }
              ],
              "test_name" => "Greeting Test",
              "condition_result" => {
                "result" => "success",
                "rationale" => {
                  "messages" => ["Agent responded politely and offered help"],
                  "summary" => "Test passed successfully"
                }
              },
              "last_updated_at_unix" => 1716240000,
              "metadata" => {
                "workspace_id" => "workspace123",
                "test_name" => "Greeting Test",
                "ran_by_user_email" => "user@example.com",
                "test_type" => "llm"
              }
            }
          ],
          "created_at" => 1716153600
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: invocation_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets test invocation details through client interface" do
        result = client.test_invocations.get(test_invocation_id)

        expect(result).to eq(invocation_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "resubmitting test runs" do
      let(:test_run_ids) { ["run1", "run2"] }
      let(:agent_id) { "agent123" }

      context "without configuration override" do
        let(:request_body) do
          {
            test_run_ids: test_run_ids,
            agent_id: agent_id
          }
        end

        let(:resubmit_response) do
          {
            "status" => "resubmitted",
            "test_run_ids" => test_run_ids
          }
        end

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
            .with(
              body: request_body.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: resubmit_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "resubmits test runs through client interface" do
          result = client.test_invocations.resubmit(test_invocation_id, test_run_ids: test_run_ids, agent_id: agent_id)

          expect(result).to eq(resubmit_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
            .with(
              body: request_body.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      context "with configuration override" do
        let(:agent_config_override) do
          {
            conversation_config: {
              agent: {
                prompt: {
                  prompt: "Enhanced customer service agent",
                  llm: "gpt-4o-mini"
                },
                first_message: "Hello! I'm here to help you.",
                language: "en"
              }
            }
          }
        end

        let(:request_body) do
          {
            test_run_ids: test_run_ids,
            agent_id: agent_id,
            agent_config_override: agent_config_override
          }
        end

        let(:resubmit_response) do
          {
            "status" => "resubmitted",
            "test_run_ids" => test_run_ids,
            "config_override_applied" => true
          }
        end

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
            .with(
              body: request_body.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: resubmit_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "resubmits test runs with configuration override through client interface" do
          result = client.test_invocations.resubmit(
            test_invocation_id,
            test_run_ids: test_run_ids,
            agent_id: agent_id,
            agent_config_override: agent_config_override
          )

          expect(result).to eq(resubmit_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
            .with(
              body: request_body.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end
    end
  end

  describe "error handling integration" do
    let(:test_invocation_id) { "nonexistent_invocation" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Test invocation not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing test invocation" do
        expect { client.test_invocations.get(test_invocation_id) }
          .to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.test_invocations.get(test_invocation_id) }
          .to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      let(:invalid_test_run_ids) { [] }
      let(:agent_id) { "agent123" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
          .with(
            body: { test_run_ids: invalid_test_run_ids, agent_id: agent_id }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "test_run_ids cannot be empty" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.test_invocations.resubmit(test_invocation_id, test_run_ids: invalid_test_run_ids, agent_id: agent_id) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "complex test invocation integration" do
    let(:test_invocation_id) { "complex_invocation" }
    let(:complex_response) do
      {
        "id" => test_invocation_id,
        "test_runs" => [
          {
            "test_run_id" => "run1",
            "test_invocation_id" => test_invocation_id,
            "agent_id" => "agent123",
            "status" => "completed",
            "test_id" => "test1",
            "workflow_node_id" => "node123",
            "agent_responses" => [
              {
                "role" => "user",
                "time_in_call_secs" => 0,
                "message" => "I need help with my order",
                "tool_calls" => [],
                "tool_results" => [],
                "feedback" => nil,
                "interrupted" => false,
                "source_medium" => "audio"
              },
              {
                "role" => "assistant",
                "time_in_call_secs" => 2,
                "message" => "I'd be happy to help you with your order. Let me look that up for you.",
                "tool_calls" => [
                  {
                    "request_id" => "req123",
                    "tool_name" => "order_lookup",
                    "params_as_json" => "{\"order_id\": \"12345\"}",
                    "tool_has_been_called" => true,
                    "type" => "system",
                    "tool_details" => {
                      "type" => "webhook",
                      "method" => "GET",
                      "url" => "https://api.example.com/orders/12345",
                      "headers" => {},
                      "path_params" => {},
                      "query_params" => {},
                      "body" => nil
                    }
                  }
                ],
                "tool_results" => [
                  {
                    "request_id" => "req123",
                    "tool_name" => "order_lookup",
                    "result_value" => "Order found: Status shipped",
                    "is_error" => false,
                    "tool_has_been_called" => true,
                    "tool_latency_secs" => 0.8,
                    "dynamic_variable_updates" => [
                      {
                        "variable_name" => "order_status",
                        "old_value" => "unknown",
                        "new_value" => "shipped",
                        "updated_at" => 1716240002.5,
                        "tool_name" => "order_lookup",
                        "tool_request_id" => "req123"
                      }
                    ],
                    "type" => "client"
                  }
                ],
                "interrupted" => false,
                "source_medium" => "audio"
              }
            ],
            "test_name" => "Order Lookup Test",
            "condition_result" => {
              "result" => "success",
              "rationale" => {
                "messages" => ["Agent successfully used order lookup tool"],
                "summary" => "Tool was called correctly with proper parameters"
              }
            },
            "last_updated_at_unix" => 1716240005,
            "metadata" => {
              "workspace_id" => "workspace123",
              "test_name" => "Order Lookup Test",
              "ran_by_user_email" => "user@example.com",
              "test_type" => "tool"
            }
          },
          {
            "test_run_id" => "run2",
            "test_invocation_id" => test_invocation_id,
            "agent_id" => "agent123",
            "status" => "completed",
            "test_id" => "test2",
            "workflow_node_id" => "node124",
            "agent_responses" => [
              {
                "role" => "assistant",
                "time_in_call_secs" => 1,
                "message" => "What?",
                "tool_calls" => [],
                "tool_results" => [],
                "interrupted" => false,
                "source_medium" => "audio"
              }
            ],
            "test_name" => "Greeting Test",
            "condition_result" => {
              "result" => "failure",
              "rationale" => {
                "messages" => ["Response was rude and unprofessional"],
                "summary" => "Agent failed to provide polite greeting"
              }
            },
            "last_updated_at_unix" => 1716240003,
            "metadata" => {
              "workspace_id" => "workspace123",
              "test_name" => "Greeting Test",
              "ran_by_user_email" => "user@example.com",
              "test_type" => "llm"
            }
          }
        ],
        "created_at" => 1716153600
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(
          status: 200,
          body: complex_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles complex test invocation with mixed results through client interface" do
      result = client.test_invocations.get(test_invocation_id)

      expect(result).to eq(complex_response)
      
      # Verify the response structure
      expect(result["test_runs"].length).to eq(2)
      expect(result["test_runs"][0]["condition_result"]["result"]).to eq("success")
      expect(result["test_runs"][1]["condition_result"]["result"]).to eq("failure")
      
      # Verify tool call details in first test run
      first_run = result["test_runs"][0]
      expect(first_run["agent_responses"][1]["tool_calls"]).to be_an(Array)
      expect(first_run["agent_responses"][1]["tool_calls"].first["tool_name"]).to eq("order_lookup")
      expect(first_run["agent_responses"][1]["tool_results"]).to be_an(Array)
      expect(first_run["agent_responses"][1]["tool_results"].first["result_value"]).to eq("Order found: Status shipped")
    end
  end

  describe "test invocation workflow integration" do
    let(:test_invocation_id) { "workflow_invocation" }
    let(:agent_id) { "agent789" }
    let(:failed_test_run_ids) { ["run2", "run3"] }

    it "supports complete test invocation management workflow" do
      # Step 1: Get initial test invocation
      initial_response = {
        "id" => test_invocation_id,
        "test_runs" => [
          {
            "test_run_id" => "run1",
            "status" => "completed",
            "condition_result" => { "result" => "success" }
          },
          {
            "test_run_id" => "run2",
            "status" => "completed",
            "condition_result" => { "result" => "failure" }
          },
          {
            "test_run_id" => "run3",
            "status" => "completed", 
            "condition_result" => { "result" => "failure" }
          }
        ],
        "created_at" => 1716153600
      }

      stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
        .to_return(
          status: 200,
          body: initial_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Step 2: Resubmit failed tests with improved configuration
      improved_config = {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are an enhanced customer service agent with improved training.",
              llm: "gpt-4o-mini"
            },
            first_message: "Hello! I'm here to provide excellent service.",
            language: "en"
          }
        }
      }

      resubmit_request = {
        test_run_ids: failed_test_run_ids,
        agent_id: agent_id,
        agent_config_override: improved_config
      }

      resubmit_response = {
        "status" => "resubmitted",
        "test_run_ids" => failed_test_run_ids,
        "config_override_applied" => true
      }

      stub_request(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
        .with(
          body: resubmit_request.to_json,
          headers: {
            "Content-Type" => "application/json",
            "xi-api-key" => api_key
          }
        )
        .to_return(
          status: 200,
          body: resubmit_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Step 3: Get updated test invocation after resubmission
      updated_response = {
        "id" => test_invocation_id,
        "test_runs" => [
          {
            "test_run_id" => "run1",
            "status" => "completed",
            "condition_result" => { "result" => "success" }
          },
          {
            "test_run_id" => "run2_resubmit",
            "status" => "completed",
            "condition_result" => { "result" => "success" }
          },
          {
            "test_run_id" => "run3_resubmit",
            "status" => "completed",
            "condition_result" => { "result" => "success" }
          }
        ],
        "created_at" => 1716153600
      }

      stub_request(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        ).times(1)

      # Execute workflow
      initial_result = client.test_invocations.get(test_invocation_id)
      expect(initial_result["test_runs"].length).to eq(3)

      resubmit_result = client.test_invocations.resubmit(
        test_invocation_id,
        test_run_ids: failed_test_run_ids,
        agent_id: agent_id,
        agent_config_override: improved_config
      )
      expect(resubmit_result["status"]).to eq("resubmitted")

      final_result = client.test_invocations.get(test_invocation_id)
      expect(final_result["test_runs"].all? { |run| run["condition_result"]["result"] == "success" }).to be true

      # Verify all requests were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}").twice
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
        .with(
          body: resubmit_request.to_json,
          headers: {
            "Content-Type" => "application/json",
            "xi-api-key" => api_key
          }
        )
    end
  end

  describe "complex configuration override integration" do
    let(:test_invocation_id) { "config_invocation" }
    let(:test_run_ids) { ["run1"] }
    let(:agent_id) { "agent456" }
    let(:complex_config_override) do
      {
        conversation_config: {
          agent: {
            prompt: {
              prompt: "You are an enhanced customer service agent with advanced training on empathy, problem-solving, and product knowledge.",
              llm: "gpt-4o-mini"
            },
            first_message: "Hello! I'm here to provide you with exceptional customer service. How may I assist you today?",
            language: "en"
          }
        },
        platform_settings: {
          webhook_url: "https://api.example.com/webhook",
          webhook_headers: {
            "Authorization" => "Bearer token123"
          }
        }
      }
    end

    let(:request_body) do
      {
        test_run_ids: test_run_ids,
        agent_id: agent_id,
        agent_config_override: complex_config_override
      }
    end

    let(:resubmit_response) do
      {
        "status" => "resubmitted",
        "test_run_ids" => test_run_ids,
        "agent_id" => agent_id,
        "configuration_updated" => true
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
        .with(
          body: request_body.to_json,
          headers: {
            "Content-Type" => "application/json",
            "xi-api-key" => api_key
          }
        )
        .to_return(
          status: 200,
          body: resubmit_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles complex configuration override in resubmit through client interface" do
      result = client.test_invocations.resubmit(
        test_invocation_id,
        test_run_ids: test_run_ids,
        agent_id: agent_id,
        agent_config_override: complex_config_override
      )
      
      expect(result).to eq(resubmit_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/test-invocations/#{test_invocation_id}/resubmit")
        .with(
          body: request_body.to_json,
          headers: {
            "Content-Type" => "application/json",
            "xi-api-key" => api_key
          }
        )
    end
  end
end
