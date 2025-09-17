# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::TestInvocations do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:test_invocations) { described_class.new(client) }

  describe "#get" do
    let(:test_invocation_id) { "invocation123" }
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
      allow(client).to receive(:get).with("/v1/convai/test-invocations/#{test_invocation_id}")
                                   .and_return(invocation_response)
    end

    it "retrieves test invocation details successfully" do
      result = test_invocations.get(test_invocation_id)
      expect(result).to eq(invocation_response)
      expect(client).to have_received(:get).with("/v1/convai/test-invocations/#{test_invocation_id}")
    end
  end

  describe "#resubmit" do
    let(:test_invocation_id) { "invocation123" }
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
        allow(client).to receive(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
                                      .and_return(resubmit_response)
      end

      it "resubmits test runs successfully" do
        result = test_invocations.resubmit(test_invocation_id, test_run_ids: test_run_ids, agent_id: agent_id)
        expect(result).to eq(resubmit_response)
        expect(client).to have_received(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
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
        allow(client).to receive(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
                                      .and_return(resubmit_response)
      end

      it "resubmits test runs with configuration override" do
        result = test_invocations.resubmit(
          test_invocation_id,
          test_run_ids: test_run_ids,
          agent_id: agent_id,
          agent_config_override: agent_config_override
        )
        expect(result).to eq(resubmit_response)
        expect(client).to have_received(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
      end
    end
  end

  describe "error handling" do
    let(:test_invocation_id) { "nonexistent_invocation" }

    context "when test invocation is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/test-invocations/#{test_invocation_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Test invocation not found")
      end

      it "raises NotFoundError" do
        expect { test_invocations.get(test_invocation_id) }
          .to raise_error(ElevenlabsClient::NotFoundError, "Test invocation not found")
      end
    end

    context "when validation fails on resubmit" do
      let(:invalid_test_run_ids) { [] }
      let(:agent_id) { "agent123" }

      before do
        allow(client).to receive(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", anything)
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "test_run_ids cannot be empty")
      end

      it "raises UnprocessableEntityError" do
        expect { test_invocations.resubmit(test_invocation_id, test_run_ids: invalid_test_run_ids, agent_id: agent_id) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "test_run_ids cannot be empty")
      end
    end

    context "when authentication fails" do
      let(:test_invocation_id) { "invocation123" }

      before do
        allow(client).to receive(:get).with("/v1/convai/test-invocations/#{test_invocation_id}")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { test_invocations.get(test_invocation_id) }
          .to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "complex test invocation data" do
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
                    "params_as_json" => '{"order_id": "12345"}',
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
      allow(client).to receive(:get).with("/v1/convai/test-invocations/#{test_invocation_id}")
                                   .and_return(complex_response)
    end

    it "handles complex test invocation with mixed results" do
      result = test_invocations.get(test_invocation_id)
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

  describe "resubmit with complex parameters" do
    let(:test_invocation_id) { "invocation123" }
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
      allow(client).to receive(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
                                    .and_return(resubmit_response)
    end

    it "handles complex configuration override in resubmit" do
      result = test_invocations.resubmit(
        test_invocation_id,
        test_run_ids: test_run_ids,
        agent_id: agent_id,
        agent_config_override: complex_config_override
      )
      
      expect(result).to eq(resubmit_response)
      expect(client).to have_received(:post).with("/v1/convai/test-invocations/#{test_invocation_id}/resubmit", request_body)
    end
  end
end
