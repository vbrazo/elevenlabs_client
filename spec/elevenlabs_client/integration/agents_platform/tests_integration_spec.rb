# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Tests Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.tests accessor" do
    it "provides access to tests endpoint" do
      expect(client.tests).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::Tests)
    end
  end

  describe "test management functionality via client" do
    let(:test_id) { "test123" }

    describe "listing tests" do
      let(:tests_response) do
        {
          "tests" => [
            {
              "id" => test_id,
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

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: tests_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "lists tests through client interface" do
        result = client.tests.list

        expect(result).to eq(tests_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting test details" do
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
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: test_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets test details through client interface" do
        result = client.tests.get(test_id)

        expect(result).to eq(test_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "creating test" do
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

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: test_params.to_json,
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

      it "creates test through client interface" do
        result = client.tests.create(**test_params)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: test_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "updating test" do
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
          "chat_history" => [
            {
              "role" => "user",
              "time_in_call_secs" => 0,
              "message" => "Hi there"
            }
          ],
          "success_condition" => "Agent responds professionally",
          "success_examples" => [
            {
              "response" => "Hi! How may I assist you?",
              "type" => "professional"
            }
          ],
          "failure_examples" => [
            {
              "response" => "Yeah?",
              "type" => "unprofessional"
            }
          ],
          "type" => "llm"
        }
      end

      before do
        stub_request(:patch, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
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

      it "updates test through client interface" do
        result = client.tests.update(test_id, **update_params)

        expect(result).to eq(update_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(
            body: update_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "deleting test" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes test through client interface" do
        result = client.tests.delete(test_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting test summaries" do
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/summaries")
          .with(
            body: { test_ids: test_ids }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: summaries_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets test summaries through client interface" do
        result = client.tests.get_summaries(test_ids)

        expect(result).to eq(summaries_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/summaries")
          .with(
            body: { test_ids: test_ids }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "running tests on agent" do
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
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
            .with(
              body: { tests: test_list }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: run_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "runs tests on agent through client interface" do
          result = client.tests.run_on_agent(agent_id, tests: test_list)

          expect(result).to eq(run_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
            .with(
              body: { tests: test_list }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
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
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
            .with(
              body: request_body.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: run_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "runs tests with configuration override through client interface" do
          result = client.tests.run_on_agent(agent_id, tests: test_list, agent_config_override: config_override)

          expect(result).to eq(run_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
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
    let(:test_id) { "nonexistent_test" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing/#{test_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Test not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing test" do
        expect { client.tests.get(test_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.tests.list }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: invalid_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Validation failed: name cannot be empty" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.tests.create(**invalid_params) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "complex test creation integration" do
    describe "tool call test with full configuration" do
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: tool_test_params.to_json,
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

      it "creates complex tool test through client interface" do
        result = client.tests.create(**tool_test_params)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: tool_test_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
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
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: dynamic_test_params.to_json,
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

      it "creates test with dynamic variables through client interface" do
        result = client.tests.create(**dynamic_test_params)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
          .with(
            body: dynamic_test_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end
  end

  describe "full workflow integration" do
    let(:test_id) { "test123" }
    let(:new_test_id) { "test456" }
    let(:agent_id) { "agent789" }

    it "supports complete test lifecycle" do
      # List tests
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing")
        .to_return(
          status: 200,
          body: { "tests" => [{ "id" => test_id, "name" => "Existing Test" }], "has_more" => false }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Create test
      test_params = {
        name: "New Greeting Test",
        chat_history: [{ role: "user", time_in_call_secs: 0, message: "Hello" }],
        success_condition: "Agent responds politely",
        success_examples: [{ response: "Hi! How can I help?", type: "polite" }],
        failure_examples: [{ response: "What?", type: "rude" }]
      }

      stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
        .to_return(
          status: 200,
          body: { "id" => new_test_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get test details
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
        .to_return(
          status: 200,
          body: { "id" => new_test_id, "name" => "New Greeting Test", "type" => "llm" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Update test
      updated_params = test_params.merge(name: "Updated Greeting Test")
      stub_request(:patch, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
        .to_return(
          status: 200,
          body: { "id" => new_test_id, "name" => "Updated Greeting Test" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get test summaries
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/summaries")
        .to_return(
          status: 200,
          body: { "tests" => { new_test_id => { "id" => new_test_id, "name" => "Updated Greeting Test" } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Run tests on agent
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
        .to_return(
          status: 200,
          body: { "id" => "run123", "test_runs" => [{ "test_id" => new_test_id, "status" => "completed" }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Delete test
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      list_result = client.tests.list
      expect(list_result["tests"].first["id"]).to eq(test_id)

      create_result = client.tests.create(**test_params)
      expect(create_result["id"]).to eq(new_test_id)

      get_result = client.tests.get(new_test_id)
      expect(get_result["id"]).to eq(new_test_id)

      update_result = client.tests.update(new_test_id, **updated_params)
      expect(update_result["name"]).to eq("Updated Greeting Test")

      summaries_result = client.tests.get_summaries([new_test_id])
      expect(summaries_result["tests"][new_test_id]["name"]).to eq("Updated Greeting Test")

      run_result = client.tests.run_on_agent(agent_id, tests: [{ test_id: new_test_id }])
      expect(run_result["id"]).to eq("run123")

      delete_result = client.tests.delete(new_test_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/create")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agent-testing/summaries")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/agents/#{agent_id}/run-tests")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/agent-testing/#{new_test_id}")
    end
  end

  describe "query parameter encoding" do
    context "list with special characters in search" do
      let(:search_term) { "greeting & welcome tests" }
      let(:encoded_search) { "page_size=20&search=greeting+%26+welcome+tests" }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing?#{encoded_search}")
          .to_return(
            status: 200,
            body: { "tests" => [], "has_more" => false }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly encodes query parameters" do
        client.tests.list(page_size: 20, search: search_term)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing?#{encoded_search}")
      end
    end

    context "list with cursor containing special characters" do
      let(:cursor) { "cursor_with_special+chars=" }
      let(:encoded_cursor) { "cursor=cursor_with_special%2Bchars%3D" }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent-testing?#{encoded_cursor}")
          .to_return(
            status: 200,
            body: { "tests" => [], "has_more" => false }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly encodes cursor parameter" do
        client.tests.list(cursor: cursor)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent-testing?#{encoded_cursor}")
      end
    end
  end
end
