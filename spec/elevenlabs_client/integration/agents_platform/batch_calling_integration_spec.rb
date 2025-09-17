# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Batch Calling Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:agent_id) { "agent_test_123" }
  let(:agent_phone_number_id) { "phone_test_456" }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "Batch Call Job Management" do
    describe "POST /v1/convai/batch-calling/submit" do
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/submit" }
      let(:call_name) { "Customer Survey Campaign" }
      let(:scheduled_time_unix) { Time.now.to_i + 3600 }
      let(:recipients) do
        [
          { phone_number: "+1234567890" },
          { phone_number: "+1987654321" },
          { phone_number: "+1555123456" }
        ]
      end

      context "successful batch job submission" do
        let(:request_body) do
          {
            call_name: call_name,
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: recipients
          }
        end

        let(:success_response) do
          {
            id: "batch_abc123def456",
            phone_number_id: agent_phone_number_id,
            name: call_name,
            agent_id: agent_id,
            created_at_unix: Time.now.to_i,
            scheduled_time_unix: scheduled_time_unix,
            total_calls_dispatched: 0,
            total_calls_scheduled: 3,
            last_updated_at_unix: Time.now.to_i,
            status: "pending",
            agent_name: "Customer Service Agent",
            phone_provider: "twilio"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: success_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "submits batch call job successfully" do
          result = client.batch_calling.submit(
            call_name: call_name,
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: recipients
          )

          expect(result["id"]).to eq("batch_abc123def456")
          expect(result["name"]).to eq(call_name)
          expect(result["total_calls_scheduled"]).to eq(3)
          expect(result["status"]).to eq("pending")
          expect(result["agent_name"]).to eq("Customer Service Agent")
          expect(result["phone_provider"]).to eq("twilio")
        end

        it "sends correct request format" do
          client.batch_calling.submit(
            call_name: call_name,
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: recipients
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "batch job with complex recipient configuration" do
        let(:complex_recipients) do
          [
            {
              phone_number: "+1234567890",
              conversation_initiation_client_data: {
                conversation_config_override: {
                  agent: {
                    first_message: "Hello John! This is a personalized survey call.",
                    language: "en",
                    prompt: {
                      prompt: "You are conducting a customer satisfaction survey for John.",
                      native_mcp_server_ids: ["survey_server_1"]
                    }
                  },
                  tts: {
                    voice_id: "survey_voice_001",
                    stability: 0.8,
                    speed: 1.0
                  }
                },
                user_id: "customer_john_001",
                source_info: {
                  source: "customer_survey",
                  version: "1.0"
                },
                dynamic_variables: {
                  customer_name: "John Doe",
                  last_purchase: "Premium Package",
                  satisfaction_score: "8/10"
                }
              }
            },
            {
              phone_number: "+1987654321",
              conversation_initiation_client_data: {
                conversation_config_override: {
                  agent: {
                    first_message: "Hello Jane! We'd love your feedback on our service.",
                    language: "en"
                  }
                },
                user_id: "customer_jane_002",
                dynamic_variables: {
                  customer_name: "Jane Smith",
                  last_purchase: "Basic Service",
                  satisfaction_score: "9/10"
                }
              }
            }
          ]
        end

        let(:complex_request_body) do
          {
            call_name: "Personalized Customer Survey",
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: complex_recipients
          }
        end

        let(:complex_response) do
          {
            id: "batch_complex_789",
            phone_number_id: agent_phone_number_id,
            name: "Personalized Customer Survey",
            agent_id: agent_id,
            created_at_unix: Time.now.to_i,
            scheduled_time_unix: scheduled_time_unix,
            total_calls_dispatched: 0,
            total_calls_scheduled: 2,
            last_updated_at_unix: Time.now.to_i,
            status: "pending",
            agent_name: "Survey Agent",
            phone_provider: "twilio"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: complex_request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: complex_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "submits batch job with complex recipient configuration" do
          result = client.batch_calling.submit(
            call_name: "Personalized Customer Survey",
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: complex_recipients
          )

          expect(result["id"]).to eq("batch_complex_789")
          expect(result["name"]).to eq("Personalized Customer Survey")
          expect(result["total_calls_scheduled"]).to eq(2)
        end

        it "includes comprehensive recipient data in request" do
          client.batch_calling.submit(
            call_name: "Personalized Customer Survey",
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: complex_recipients
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(body: complex_request_body.to_json)
        end
      end

      context "batch job submission error scenarios" do
        let(:invalid_request_body) do
          {
            call_name: call_name,
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            scheduled_time_unix: scheduled_time_unix,
            recipients: []
          }
        end

        context "when recipients list is empty" do
          before do
            stub_request(:post, endpoint)
              .with(body: invalid_request_body.to_json)
              .to_return(
                status: 422,
                body: { detail: "Recipients list cannot be empty" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises UnprocessableEntityError for empty recipients" do
            expect {
              client.batch_calling.submit(
                call_name: call_name,
                agent_id: agent_id,
                agent_phone_number_id: agent_phone_number_id,
                scheduled_time_unix: scheduled_time_unix,
                recipients: []
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when agent not found" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 404,
                body: { detail: "Agent not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises NotFoundError for invalid agent" do
            expect {
              client.batch_calling.submit(
                call_name: call_name,
                agent_id: "invalid_agent",
                agent_phone_number_id: agent_phone_number_id,
                scheduled_time_unix: scheduled_time_unix,
                recipients: recipients
              )
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end
      end
    end

    describe "GET /v1/convai/batch-calling/workspace" do
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/workspace" }

      context "successful batch jobs listing" do
        let(:list_response) do
          {
            batch_calls: [
              {
                id: "batch_001",
                phone_number_id: "phone_001",
                name: "Customer Survey Campaign - Q1",
                agent_id: "agent_001",
                created_at_unix: Time.now.to_i - 7200,
                scheduled_time_unix: Time.now.to_i - 3600,
                total_calls_dispatched: 45,
                total_calls_scheduled: 50,
                last_updated_at_unix: Time.now.to_i - 300,
                status: "in_progress",
                agent_name: "Survey Agent",
                phone_provider: "twilio"
              },
              {
                id: "batch_002",
                phone_number_id: "phone_002",
                name: "Appointment Reminders - Jan 15",
                agent_id: "agent_002",
                created_at_unix: Time.now.to_i - 86400,
                scheduled_time_unix: Time.now.to_i - 82800,
                total_calls_dispatched: 25,
                total_calls_scheduled: 25,
                last_updated_at_unix: Time.now.to_i - 82800,
                status: "completed",
                agent_name: "Reminder Agent",
                phone_provider: "sip_trunk"
              },
              {
                id: "batch_003",
                phone_number_id: "phone_003",
                name: "Product Launch Announcement",
                agent_id: "agent_003",
                created_at_unix: Time.now.to_i,
                scheduled_time_unix: Time.now.to_i + 3600,
                total_calls_dispatched: 0,
                total_calls_scheduled: 100,
                last_updated_at_unix: Time.now.to_i,
                status: "pending",
                agent_name: "Marketing Agent",
                phone_provider: "twilio"
              }
            ],
            next_doc: "next_page_token_456",
            has_more: true
          }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: list_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists batch call jobs successfully" do
          result = client.batch_calling.list

          expect(result["batch_calls"].size).to eq(3)
          expect(result["batch_calls"][0]["id"]).to eq("batch_001")
          expect(result["batch_calls"][0]["status"]).to eq("in_progress")
          expect(result["batch_calls"][1]["status"]).to eq("completed")
          expect(result["batch_calls"][2]["status"]).to eq("pending")
          expect(result["has_more"]).to be true
          expect(result["next_doc"]).to eq("next_page_token_456")
        end

        it "includes comprehensive job information" do
          result = client.batch_calling.list
          first_job = result["batch_calls"][0]

          expect(first_job["name"]).to eq("Customer Survey Campaign - Q1")
          expect(first_job["agent_name"]).to eq("Survey Agent")
          expect(first_job["phone_provider"]).to eq("twilio")
          expect(first_job["total_calls_dispatched"]).to eq(45)
          expect(first_job["total_calls_scheduled"]).to eq(50)
        end
      end

      context "with pagination parameters" do
        let(:paginated_endpoint) { "#{endpoint}?limit=10&last_doc=previous_token_123" }

        let(:paginated_response) do
          {
            batch_calls: [
              {
                id: "batch_004",
                name: "Follow-up Campaign",
                status: "completed",
                agent_name: "Follow-up Agent"
              }
            ],
            next_doc: nil,
            has_more: false
          }
        end

        before do
          stub_request(:get, paginated_endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: paginated_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles pagination parameters correctly" do
          result = client.batch_calling.list(limit: 10, last_doc: "previous_token_123")

          expect(result["batch_calls"].size).to eq(1)
          expect(result["batch_calls"][0]["id"]).to eq("batch_004")
          expect(result["has_more"]).to be false
          expect(result["next_doc"]).to be_nil
        end

        it "sends correct paginated request" do
          client.batch_calling.list(limit: 10, last_doc: "previous_token_123")

          expect(WebMock).to have_requested(:get, paginated_endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end
    end

    describe "GET /v1/convai/batch-calling/{batch_id}" do
      let(:batch_id) { "batch_detail_123" }
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/#{batch_id}" }

      context "successful batch job details retrieval" do
        let(:detail_response) do
          {
            id: batch_id,
            phone_number_id: "phone_001",
            name: "Customer Survey Campaign - Detailed",
            agent_id: "agent_001",
            created_at_unix: Time.now.to_i - 7200,
            scheduled_time_unix: Time.now.to_i - 3600,
            total_calls_dispatched: 8,
            total_calls_scheduled: 10,
            last_updated_at_unix: Time.now.to_i - 300,
            status: "in_progress",
            agent_name: "Survey Agent",
            recipients: [
              {
                id: "rec_001",
                phone_number: "+1234567890",
                status: "completed",
                created_at_unix: Time.now.to_i - 7200,
                updated_at_unix: Time.now.to_i - 3600,
                conversation_id: "conv_001",
                conversation_initiation_client_data: {
                  user_id: "user_001",
                  source_info: { source: "survey_campaign" },
                  dynamic_variables: { customer_name: "John Doe" }
                }
              },
              {
                id: "rec_002",
                phone_number: "+1987654321",
                status: "failed",
                created_at_unix: Time.now.to_i - 7200,
                updated_at_unix: Time.now.to_i - 3600,
                conversation_id: nil
              },
              {
                id: "rec_003",
                phone_number: "+1555123456",
                status: "completed",
                created_at_unix: Time.now.to_i - 7200,
                updated_at_unix: Time.now.to_i - 1800,
                conversation_id: "conv_003"
              },
              {
                id: "rec_004",
                phone_number: "+1555987654",
                status: "pending",
                created_at_unix: Time.now.to_i - 7200,
                updated_at_unix: Time.now.to_i - 7200,
                conversation_id: nil
              },
              {
                id: "rec_005",
                phone_number: "+1555444333",
                status: "no_response",
                created_at_unix: Time.now.to_i - 7200,
                updated_at_unix: Time.now.to_i - 2400,
                conversation_id: nil
              }
            ],
            phone_provider: "twilio"
          }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: detail_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves comprehensive batch job details" do
          result = client.batch_calling.get(batch_id)

          expect(result["id"]).to eq(batch_id)
          expect(result["name"]).to eq("Customer Survey Campaign - Detailed")
          expect(result["status"]).to eq("in_progress")
          expect(result["total_calls_dispatched"]).to eq(8)
          expect(result["total_calls_scheduled"]).to eq(10)
          expect(result["recipients"].size).to eq(5)
        end

        it "includes detailed recipient information with various statuses" do
          result = client.batch_calling.get(batch_id)
          recipients = result["recipients"]

          # Completed recipient with conversation
          completed_recipient = recipients.find { |r| r["id"] == "rec_001" }
          expect(completed_recipient["status"]).to eq("completed")
          expect(completed_recipient["conversation_id"]).to eq("conv_001")
          expect(completed_recipient["conversation_initiation_client_data"]["user_id"]).to eq("user_001")

          # Failed recipient
          failed_recipient = recipients.find { |r| r["id"] == "rec_002" }
          expect(failed_recipient["status"]).to eq("failed")
          expect(failed_recipient["conversation_id"]).to be_nil

          # Pending recipient
          pending_recipient = recipients.find { |r| r["id"] == "rec_004" }
          expect(pending_recipient["status"]).to eq("pending")

          # No response recipient
          no_response_recipient = recipients.find { |r| r["id"] == "rec_005" }
          expect(no_response_recipient["status"]).to eq("no_response")
        end
      end

      context "when batch job not found" do
        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 404,
              body: { detail: "Batch job not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises NotFoundError for non-existent batch job" do
          expect {
            client.batch_calling.get(batch_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end
    end

    describe "POST /v1/convai/batch-calling/{batch_id}/cancel" do
      let(:batch_id) { "batch_cancel_123" }
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/#{batch_id}/cancel" }

      context "successful batch job cancellation" do
        let(:cancel_response) do
          {
            id: batch_id,
            phone_number_id: "phone_001",
            name: "Cancelled Marketing Campaign",
            agent_id: "agent_001",
            created_at_unix: Time.now.to_i - 3600,
            scheduled_time_unix: Time.now.to_i - 1800,
            total_calls_dispatched: 25,
            total_calls_scheduled: 100,
            last_updated_at_unix: Time.now.to_i,
            status: "cancelled",
            agent_name: "Marketing Agent",
            phone_provider: "twilio"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: "{}",
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: cancel_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "cancels batch job successfully" do
          result = client.batch_calling.cancel(batch_id)

          expect(result["id"]).to eq(batch_id)
          expect(result["status"]).to eq("cancelled")
          expect(result["total_calls_dispatched"]).to eq(25)
          expect(result["total_calls_scheduled"]).to eq(100)
        end

        it "sends correct cancellation request" do
          client.batch_calling.cancel(batch_id)

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: "{}",
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "when batch job cannot be cancelled" do
        before do
          stub_request(:post, endpoint)
            .to_return(
              status: 422,
              body: { detail: "Cannot cancel completed batch job" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError for non-cancellable jobs" do
          expect {
            client.batch_calling.cancel(batch_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end

    describe "POST /v1/convai/batch-calling/{batch_id}/retry" do
      let(:batch_id) { "batch_retry_123" }
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/#{batch_id}/retry" }

      context "successful batch job retry" do
        let(:retry_response) do
          {
            id: batch_id,
            phone_number_id: "phone_001",
            name: "Retried Survey Campaign",
            agent_id: "agent_001",
            created_at_unix: Time.now.to_i - 7200,
            scheduled_time_unix: Time.now.to_i - 3600,
            total_calls_dispatched: 15,
            total_calls_scheduled: 50,
            last_updated_at_unix: Time.now.to_i,
            status: "in_progress",
            agent_name: "Survey Agent",
            phone_provider: "twilio"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: "{}",
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: retry_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retries batch job successfully" do
          result = client.batch_calling.retry(batch_id)

          expect(result["id"]).to eq(batch_id)
          expect(result["status"]).to eq("in_progress")
          expect(result["total_calls_dispatched"]).to eq(15)
          expect(result["total_calls_scheduled"]).to eq(50)
        end

        it "sends correct retry request" do
          client.batch_calling.retry(batch_id)

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: "{}",
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "when no failed calls to retry" do
        before do
          stub_request(:post, endpoint)
            .to_return(
              status: 422,
              body: { detail: "No failed or no-response calls to retry" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError when no calls to retry" do
          expect {
            client.batch_calling.retry(batch_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "Complete Batch Calling Workflow" do
    let(:submit_endpoint) { "#{base_url}/v1/convai/batch-calling/submit" }
    let(:list_endpoint) { "#{base_url}/v1/convai/batch-calling/workspace" }
    let(:batch_id) { "batch_workflow_123" }
    let(:detail_endpoint) { "#{base_url}/v1/convai/batch-calling/#{batch_id}" }
    let(:retry_endpoint) { "#{base_url}/v1/convai/batch-calling/#{batch_id}/retry" }

    context "end-to-end batch calling campaign" do
      let(:campaign_recipients) do
        [
          { phone_number: "+1555001001" },
          { phone_number: "+1555001002" },
          { phone_number: "+1555001003" },
          { phone_number: "+1555001004" },
          { phone_number: "+1555001005" }
        ]
      end

      let(:submit_response) do
        {
          id: batch_id,
          phone_number_id: agent_phone_number_id,
          name: "End-to-End Campaign",
          agent_id: agent_id,
          created_at_unix: Time.now.to_i,
          scheduled_time_unix: Time.now.to_i + 1800,
          total_calls_dispatched: 0,
          total_calls_scheduled: 5,
          last_updated_at_unix: Time.now.to_i,
          status: "pending",
          agent_name: "Campaign Agent",
          phone_provider: "twilio"
        }
      end

      let(:in_progress_details) do
        {
          id: batch_id,
          status: "in_progress",
          total_calls_dispatched: 3,
          total_calls_scheduled: 5,
          recipients: [
            { id: "rec_001", phone_number: "+1555001001", status: "completed", conversation_id: "conv_001" },
            { id: "rec_002", phone_number: "+1555001002", status: "completed", conversation_id: "conv_002" },
            { id: "rec_003", phone_number: "+1555001003", status: "failed", conversation_id: nil },
            { id: "rec_004", phone_number: "+1555001004", status: "pending", conversation_id: nil },
            { id: "rec_005", phone_number: "+1555001005", status: "pending", conversation_id: nil }
          ]
        }
      end

      let(:completed_details) do
        {
          id: batch_id,
          status: "completed",
          total_calls_dispatched: 5,
          total_calls_scheduled: 5,
          recipients: [
            { id: "rec_001", phone_number: "+1555001001", status: "completed", conversation_id: "conv_001" },
            { id: "rec_002", phone_number: "+1555001002", status: "completed", conversation_id: "conv_002" },
            { id: "rec_003", phone_number: "+1555001003", status: "failed", conversation_id: nil },
            { id: "rec_004", phone_number: "+1555001004", status: "no_response", conversation_id: nil },
            { id: "rec_005", phone_number: "+1555001005", status: "completed", conversation_id: "conv_005" }
          ]
        }
      end

      let(:retry_response) do
        {
          id: batch_id,
          status: "in_progress",
          total_calls_dispatched: 3,
          total_calls_scheduled: 5
        }
      end

      before do
        # Step 1: Submit batch job
        stub_request(:post, submit_endpoint)
          .to_return(
            status: 200,
            body: submit_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 2: Monitor progress (in-progress state)
        stub_request(:get, detail_endpoint)
          .to_return(
            status: 200,
            body: in_progress_details.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: completed_details.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: completed_details.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 3: Retry failed calls
        stub_request(:post, retry_endpoint)
          .to_return(
            status: 200,
            body: retry_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "completes full batch calling workflow" do
        # Step 1: Submit campaign
        submit_result = client.batch_calling.submit(
          call_name: "End-to-End Campaign",
          agent_id: agent_id,
          agent_phone_number_id: agent_phone_number_id,
          scheduled_time_unix: Time.now.to_i + 1800,
          recipients: campaign_recipients
        )

        expect(submit_result["id"]).to eq(batch_id)
        expect(submit_result["status"]).to eq("pending")
        expect(submit_result["total_calls_scheduled"]).to eq(5)

        # Step 2: Monitor progress
        progress_result = client.batch_calling.get(batch_id)
        expect(progress_result["status"]).to eq("in_progress")
        expect(progress_result["total_calls_dispatched"]).to eq(3)

        # Check completion
        final_result = client.batch_calling.get(batch_id)
        expect(final_result["status"]).to eq("completed")
        expect(final_result["total_calls_dispatched"]).to eq(5)

        # Analyze results
        recipients = final_result["recipients"]
        completed_calls = recipients.count { |r| r["status"] == "completed" }
        failed_calls = recipients.count { |r| r["status"] == "failed" }
        no_response_calls = recipients.count { |r| r["status"] == "no_response" }

        expect(completed_calls).to eq(3)
        expect(failed_calls).to eq(1)
        expect(no_response_calls).to eq(1)

        # Step 3: Retry failed and no-response calls
        retry_result = client.batch_calling.retry(batch_id)
        expect(retry_result["status"]).to eq("in_progress")

        # Verify all requests were made
        expect(WebMock).to have_requested(:post, submit_endpoint).once
        expect(WebMock).to have_requested(:get, detail_endpoint).times(2)
        expect(WebMock).to have_requested(:post, retry_endpoint).once
      end
    end
  end

  describe "Error Handling and Edge Cases" do
    context "network and service errors" do
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/workspace" }

      context "when service is temporarily unavailable" do
        before do
          stub_request(:get, endpoint)
            .to_return(status: 503, body: { detail: "Service temporarily unavailable" }.to_json)
        end

        it "handles service unavailability gracefully" do
          expect {
            client.batch_calling.list
          }.to raise_error(ElevenlabsClient::ServiceUnavailableError)
        end
      end

      context "when rate limited" do
        before do
          stub_request(:get, endpoint)
            .to_return(
              status: 429,
              body: { detail: "Rate limit exceeded" }.to_json,
              headers: { "Retry-After" => "120" }
            )
        end

        it "handles rate limiting appropriately" do
          expect {
            client.batch_calling.list
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end

      context "when response is malformed" do
        before do
          stub_request(:get, endpoint)
            .to_return(
              status: 200,
              body: "Invalid JSON content",
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles malformed JSON gracefully" do
          expect {
            client.batch_calling.list
          }.to raise_error(Faraday::ParsingError)
        end
      end
    end

    context "authentication and authorization errors" do
      let(:endpoint) { "#{base_url}/v1/convai/batch-calling/submit" }

      context "when API key is invalid" do
        before do
          stub_request(:post, endpoint)
            .to_return(
              status: 401,
              body: { detail: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises AuthenticationError for invalid API key" do
          expect {
            client.batch_calling.submit(
              call_name: "Test",
              agent_id: agent_id,
              agent_phone_number_id: agent_phone_number_id,
              scheduled_time_unix: Time.now.to_i,
              recipients: [{ phone_number: "+1234567890" }]
            )
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "when user lacks permissions" do
        before do
          stub_request(:post, endpoint)
            .to_return(
              status: 403,
              body: { detail: "Insufficient permissions for batch calling" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises ForbiddenError for insufficient permissions" do
          expect {
            client.batch_calling.submit(
              call_name: "Test",
              agent_id: agent_id,
              agent_phone_number_id: agent_phone_number_id,
              scheduled_time_unix: Time.now.to_i,
              recipients: [{ phone_number: "+1234567890" }]
            )
          }.to raise_error(ElevenlabsClient::ForbiddenError)
        end
      end
    end
  end
end
