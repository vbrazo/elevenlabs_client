# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Tests do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:tests) { described_class.new(client) }

  describe "#list" do
    let(:list_response) do
      {
        "tests" => [
          {
            "id" => "test123",
            "name" => "Customer Service Greeting Test",
            "created_at_unix_secs" => 1716153600,
            "last_updated_at_unix_secs" => 1716240000,
            "type" => "llm",
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "John Doe",
              "creator_email" => "john@example.com",
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
        allow(client).to receive(:get).with("/v1/convai/agent-testing")
                                     .and_return(list_response)
      end

      it "lists tests successfully" do
        result = tests.list
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/agent-testing")
      end
    end

    context "with parameters" do
      let(:params) do
        {
          page_size: 10,
          search: "greeting",
          cursor: "cursor123"
        }
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/agent-testing?page_size=10&search=greeting&cursor=cursor123")
                                     .and_return(list_response)
      end

      it "lists tests with query parameters" do
        result = tests.list(**params)
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/agent-testing?page_size=10&search=greeting&cursor=cursor123")
      end
    end
  end

  describe "#get" do
    let(:test_id) { "test123" }
    let(:test_response) do
      {
        "chat_history" => [
          {
            "role" => "user",
            "time_in_call_secs" => 0,
            "message" => "Hello, I need help",
            "tool_calls" => [],
            "tool_results" => [],
            "feedback" => nil,
            "llm_override" => nil,
            "conversation_turn_metrics" => { "metrics" => {} },
            "rag_retrieval_info" => nil,
            "llm_usage" => { "model_usage" => {} },
            "interrupted" => false,
            "original_message" => "Hello, I need help",
            "source_medium" => "audio"
          }
        ],
        "success_condition" => "The agent responds politely and offers help",
        "success_examples" => [
          {
            "response" => "Hello! How can I help you today?",
            "type" => "polite_greeting"
          }
        ],
        "failure_examples" => [
          {
            "response" => "What do you want?",
            "type" => "rude_response"
          }
        ],
        "id" => test_id,
        "name" => "Customer Service Greeting Test",
        "tool_call_parameters" => nil,
        "dynamic_variables" => {},
        "type" => "llm"
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/agent-testing/#{test_id}")
                                   .and_return(test_response)
    end

    it "retrieves test details successfully" do
      result = tests.get(test_id)
      expect(result).to eq(test_response)
      expect(client).to have_received(:get).with("/v1/convai/agent-testing/#{test_id}")
    end
  end

  describe "#create" do
    let(:test_params) do
      {
        name: "Customer Greeting Test",
        chat_history: [
          {
            role: "user",
            time_in_call_secs: 0,
            message: "Hello"
          }
        ],
        success_condition: "Agent responds politely",
        success_examples: [
          {
            response: "Hello! How can I help?",
            type: "polite"
          }
        ],
        failure_examples: [
          {
            response: "What?",
            type: "rude"
          }
        ]
      }
    end

    let(:create_response) do
      {
        "id" => "test456"
      }
    end

    context "basic test creation" do
      before do
        allow(client).to receive(:post).with("/v1/convai/agent-testing/create", test_params)
                                      .and_return(create_response)
      end

      it "creates test successfully" do
        result = tests.create(**test_params)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/agent-testing/create", test_params)
      end
    end

    context "with optional parameters" do
      let(:extended_params) do
        test_params.merge(
          type: "tool",
          tool_call_parameters: {
            referenced_tool: { id: "tool123", type: "system" },
            parameters: [{ path: "$.param", eval: { type: "exact_match", description: "test" } }],
            verify_absence: false
          },
          dynamic_variables: { "var1" => "value1" }
        )
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/agent-testing/create", extended_params)
                                      .and_return(create_response)
      end

      it "creates test with optional parameters" do
        result = tests.create(**extended_params)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/agent-testing/create", extended_params)
      end
    end
  end

  describe "#update" do
    let(:test_id) { "test123" }
    let(:update_params) do
      {
        name: "Updated Customer Greeting Test",
        chat_history: [
          {
            role: "user",
            time_in_call_secs: 0,
            message: "Hi there"
          }
        ],
        success_condition: "Agent responds professionally",
        success_examples: [
          {
            response: "Hi! How may I assist you?",
            type: "professional"
          }
        ],
        failure_examples: [
          {
            response: "Yeah?",
            type: "unprofessional"
          }
        ]
      }
    end

    let(:update_response) do
      {
        "id" => test_id,
        "name" => "Updated Customer Greeting Test",
        "chat_history" => update_params[:chat_history],
        "success_condition" => update_params[:success_condition],
        "success_examples" => update_params[:success_examples],
        "failure_examples" => update_params[:failure_examples],
        "type" => "llm"
      }
    end

    before do
      allow(client).to receive(:patch).with("/v1/convai/agent-testing/#{test_id}", update_params)
                                   .and_return(update_response)
    end

    it "updates test successfully" do
      result = tests.update(test_id, **update_params)
      expect(result).to eq(update_response)
      expect(client).to have_received(:patch).with("/v1/convai/agent-testing/#{test_id}", update_params)
    end
  end

  describe "#delete" do
    let(:test_id) { "test123" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/agent-testing/#{test_id}")
                                      .and_return(delete_response)
    end

    it "deletes test successfully" do
      result = tests.delete(test_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/agent-testing/#{test_id}")
    end
  end

  describe "#get_summaries" do
    let(:test_ids) { ["test1", "test2", "test3"] }
    let(:summaries_response) do
      {
        "tests" => {
          "test1" => {
            "id" => "test1",
            "name" => "Greeting Test",
            "created_at_unix_secs" => 1716153600,
            "last_updated_at_unix_secs" => 1716240000,
            "type" => "llm",
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "John Doe",
              "creator_email" => "john@example.com",
              "role" => "admin"
            }
          },
          "test2" => {
            "id" => "test2",
            "name" => "Order Lookup Test",
            "created_at_unix_secs" => 1716153600,
            "last_updated_at_unix_secs" => 1716240000,
            "type" => "tool",
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "Jane Smith",
              "creator_email" => "jane@example.com",
              "role" => "admin"
            }
          }
        }
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agent-testing/summaries", { test_ids: test_ids })
                                    .and_return(summaries_response)
    end

    it "gets test summaries successfully" do
      result = tests.get_summaries(test_ids)
      expect(result).to eq(summaries_response)
      expect(client).to have_received(:post).with("/v1/convai/agent-testing/summaries", { test_ids: test_ids })
    end
  end

  describe "#run_on_agent" do
    let(:agent_id) { "agent123" }
    let(:test_list) do
      [
        { test_id: "test1" },
        { test_id: "test2" }
      ]
    end

    let(:run_response) do
      {
        "id" => "run456",
        "test_runs" => [
          {
            "test_run_id" => "run_test1",
            "test_invocation_id" => "invocation123",
            "agent_id" => agent_id,
            "status" => "completed",
            "test_id" => "test1",
            "workflow_node_id" => "node123",
            "agent_responses" => [
              {
                "role" => "assistant",
                "time_in_call_secs" => 2,
                "message" => "Hello! How can I help you?",
                "tool_calls" => [],
                "tool_results" => [],
                "feedback" => nil,
                "interrupted" => false,
                "source_medium" => "audio"
              }
            ],
            "test_name" => "Greeting Test",
            "condition_result" => {
              "result" => "success",
              "rationale" => {
                "messages" => ["Agent responded politely"],
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

    context "without configuration override" do
      before do
        allow(client).to receive(:post).with("/v1/convai/agents/#{agent_id}/run-tests", { tests: test_list })
                                      .and_return(run_response)
      end

      it "runs tests on agent successfully" do
        result = tests.run_on_agent(agent_id, tests: test_list)
        expect(result).to eq(run_response)
        expect(client).to have_received(:post).with("/v1/convai/agents/#{agent_id}/run-tests", { tests: test_list })
      end
    end

    context "with configuration override" do
      let(:config_override) do
        {
          conversation_config: {
            agent: {
              prompt: { prompt: "You are helpful", llm: "gpt-4o-mini" },
              first_message: "Hello!"
            }
          }
        }
      end

      let(:request_body) do
        {
          tests: test_list,
          agent_config_override: config_override
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/agents/#{agent_id}/run-tests", request_body)
                                      .and_return(run_response)
      end

      it "runs tests with configuration override" do
        result = tests.run_on_agent(agent_id, tests: test_list, agent_config_override: config_override)
        expect(result).to eq(run_response)
        expect(client).to have_received(:post).with("/v1/convai/agents/#{agent_id}/run-tests", request_body)
      end
    end
  end

  describe "error handling" do
    let(:test_id) { "nonexistent_test" }

    context "when test is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/agent-testing/#{test_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Test not found")
      end

      it "raises NotFoundError" do
        expect { tests.get(test_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Test not found")
      end
    end

    context "when validation fails" do
      let(:invalid_params) do
        {
          name: "",
          chat_history: [],
          success_condition: "",
          success_examples: [],
          failure_examples: []
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/agent-testing/create", invalid_params)
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Validation failed")
      end

      it "raises UnprocessableEntityError" do
        expect { tests.create(**invalid_params) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Validation failed")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/agent-testing")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { tests.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "parameter handling" do
    describe "#list" do
      context "with nil parameters" do
        let(:params) { { page_size: 10, search: nil, cursor: "cursor123" } }
        let(:expected_query) { "page_size=10&cursor=cursor123" }

        before do
          allow(client).to receive(:get).with("/v1/convai/agent-testing?#{expected_query}")
                                       .and_return({ "tests" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          tests.list(**params)
          expect(client).to have_received(:get).with("/v1/convai/agent-testing?#{expected_query}")
        end
      end
    end
  end

  describe "complex test configurations" do
    describe "tool call test creation" do
      let(:tool_test_params) do
        {
          name: "Order Lookup Tool Test",
          chat_history: [
            {
              role: "user",
              time_in_call_secs: 0,
              message: "Check order #12345"
            }
          ],
          success_condition: "Agent uses order lookup tool with correct parameters",
          success_examples: [
            {
              response: "Let me check order #12345 for you",
              type: "tool_usage"
            }
          ],
          failure_examples: [
            {
              response: "I can't check orders",
              type: "no_tool_usage"
            }
          ],
          type: "tool",
          tool_call_parameters: {
            referenced_tool: {
              id: "order_lookup_tool",
              type: "system"
            },
            parameters: [
              {
                path: "$.order_number",
                eval: {
                  type: "exact_match",
                  description: "Order number should be 12345"
                }
              }
            ],
            verify_absence: false
          }
        }
      end

      let(:create_response) { { "id" => "tool_test_123" } }

      before do
        allow(client).to receive(:post).with("/v1/convai/agent-testing/create", tool_test_params)
                                      .and_return(create_response)
      end

      it "creates tool test with complex parameters successfully" do
        result = tests.create(**tool_test_params)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/agent-testing/create", tool_test_params)
      end
    end

    describe "test with dynamic variables" do
      let(:dynamic_test_params) do
        {
          name: "Dynamic Variable Test",
          chat_history: [
            {
              role: "user",
              time_in_call_secs: 0,
              message: "What's my budget for electronics?"
            }
          ],
          success_condition: "Agent references the dynamic budget variable correctly",
          success_examples: [
            {
              response: "Your budget for electronics is $1000",
              type: "variable_usage"
            }
          ],
          failure_examples: [
            {
              response: "I don't know your budget",
              type: "no_variable_usage"
            }
          ],
          dynamic_variables: {
            "customer_budget" => 1000,
            "category" => "electronics",
            "premium_customer" => true
          }
        }
      end

      let(:create_response) { { "id" => "dynamic_test_123" } }

      before do
        allow(client).to receive(:post).with("/v1/convai/agent-testing/create", dynamic_test_params)
                                      .and_return(create_response)
      end

      it "creates test with dynamic variables successfully" do
        result = tests.create(**dynamic_test_params)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/agent-testing/create", dynamic_test_params)
      end
    end
  end

  describe "test run result analysis" do
    let(:agent_id) { "agent123" }
    let(:complex_run_response) do
      {
        "id" => "run789",
        "test_runs" => [
          {
            "test_run_id" => "run1",
            "agent_id" => agent_id,
            "status" => "completed",
            "test_id" => "test1",
            "test_name" => "Greeting Test",
            "condition_result" => {
              "result" => "success",
              "rationale" => {
                "messages" => ["Response was polite and helpful"],
                "summary" => "Test passed successfully"
              }
            },
            "agent_responses" => [
              {
                "role" => "assistant",
                "message" => "Hello! How can I help you today?",
                "time_in_call_secs" => 1
              }
            ]
          },
          {
            "test_run_id" => "run2",
            "agent_id" => agent_id,
            "status" => "completed",
            "test_id" => "test2",
            "test_name" => "Order Lookup Test",
            "condition_result" => {
              "result" => "failure",
              "rationale" => {
                "messages" => ["Tool was not called correctly"],
                "summary" => "Agent failed to use the order lookup tool"
              }
            },
            "agent_responses" => [
              {
                "role" => "assistant",
                "message" => "I can't help with order status",
                "time_in_call_secs" => 2
              }
            ]
          }
        ],
        "created_at" => 1716153600
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/agents/#{agent_id}/run-tests", { tests: [{ test_id: "test1" }, { test_id: "test2" }] })
                                    .and_return(complex_run_response)
    end

    it "handles complex test run responses with mixed results" do
      result = tests.run_on_agent(agent_id, tests: [{ test_id: "test1" }, { test_id: "test2" }])
      expect(result).to eq(complex_run_response)
      
      # Verify the response structure
      expect(result["test_runs"].length).to eq(2)
      expect(result["test_runs"][0]["condition_result"]["result"]).to eq("success")
      expect(result["test_runs"][1]["condition_result"]["result"]).to eq("failure")
    end
  end
end
