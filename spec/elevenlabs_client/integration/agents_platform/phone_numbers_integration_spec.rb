# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Phone Numbers Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.phone_numbers accessor" do
    it "provides access to phone numbers endpoint" do
      expect(client.phone_numbers).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::PhoneNumbers)
    end
  end

  describe "phone number management functionality via client" do
    let(:phone_number_id) { "phone123" }

    describe "importing phone numbers" do
      context "Twilio phone number" do
        let(:twilio_params) do
          {
            phone_number: "+1234567890",
            label: "Customer Service Line",
            sid: "twilio_account_sid",
            token: "twilio_auth_token"
          }
        end

        let(:import_response) do
          {
            "phone_number_id" => "phone123"
          }
        end

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
            .with(
              body: twilio_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: import_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "imports Twilio phone number through client interface" do
          result = client.phone_numbers.import(**twilio_params)

          expect(result).to eq(import_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
            .with(
              body: twilio_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      context "SIP trunk phone number" do
        let(:sip_params) do
          {
            phone_number: "+1987654321",
            label: "SIP Support Line",
            provider_type: "sip_trunk",
            inbound_trunk_config: {
              sip_uri: "sip:inbound@example.com",
              username: "inbound_user",
              password: "inbound_pass",
              auth_username: "auth_user"
            },
            outbound_trunk_config: {
              sip_uri: "sip:outbound@example.com",
              username: "outbound_user",
              password: "outbound_pass",
              auth_username: "auth_user_out",
              caller_id: "+1987654321"
            },
            livekit_stack: "standard"
          }
        end

        let(:import_response) do
          {
            "phone_number_id" => "phone456"
          }
        end

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
            .with(
              body: sip_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: import_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "imports SIP trunk phone number through client interface" do
          result = client.phone_numbers.import(**sip_params)

          expect(result).to eq(import_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
            .with(
              body: sip_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end
    end

    describe "listing phone numbers" do
      let(:list_response) do
        [
          {
            "phone_number" => "+1234567890",
            "label" => "Customer Service Main",
            "supports_inbound" => true,
            "supports_outbound" => true,
            "phone_number_id" => "phone123",
            "assigned_agent" => {
              "agent_id" => "agent456",
              "agent_name" => "Customer Service Agent"
            },
            "provider" => "twilio"
          },
          {
            "phone_number" => "+1987654321",
            "label" => "SIP Support Line",
            "supports_inbound" => true,
            "supports_outbound" => false,
            "phone_number_id" => "phone789",
            "assigned_agent" => nil,
            "provider" => "sip_trunk",
            "inbound_trunk_config" => {
              "sip_uri" => "sip:inbound@example.com",
              "username" => "inbound_user",
              "auth_username" => "auth_user"
            },
            "outbound_trunk_config" => nil,
            "livekit_stack" => "standard"
          }
        ]
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: list_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "lists phone numbers through client interface" do
        result = client.phone_numbers.list

        expect(result).to eq(list_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting phone number details" do
      let(:phone_response) do
        {
          "phone_number" => "+1234567890",
          "label" => "Customer Service Main",
          "supports_inbound" => true,
          "supports_outbound" => true,
          "phone_number_id" => phone_number_id,
          "assigned_agent" => {
            "agent_id" => "agent456",
            "agent_name" => "Customer Service Agent"
          },
          "provider" => "twilio"
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: phone_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets phone number details through client interface" do
        result = client.phone_numbers.get(phone_number_id)

        expect(result).to eq(phone_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "updating phone numbers" do
      context "assigning agent" do
        let(:update_params) do
          {
            agent_id: "agent789"
          }
        end

        let(:update_response) do
          {
            "phone_number" => "+1234567890",
            "label" => "Customer Service Main",
            "supports_inbound" => true,
            "supports_outbound" => true,
            "phone_number_id" => phone_number_id,
            "assigned_agent" => {
              "agent_id" => "agent789",
              "agent_name" => "New Customer Service Agent"
            },
            "provider" => "twilio"
          }
        end

        before do
          stub_request(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
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

        it "updates phone number with agent assignment through client interface" do
          result = client.phone_numbers.update(phone_number_id, **update_params)

          expect(result).to eq(update_response)
          expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
            .with(
              body: update_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      context "updating SIP configuration" do
        let(:update_params) do
          {
            agent_id: "agent789",
            inbound_trunk_config: {
              sip_uri: "sip:new-inbound@example.com",
              username: "new_inbound_user",
              password: "new_inbound_pass",
              auth_username: "new_auth_user"
            },
            outbound_trunk_config: {
              sip_uri: "sip:new-outbound@example.com",
              username: "new_outbound_user",
              password: "new_outbound_pass",
              auth_username: "new_auth_user_out",
              caller_id: "+1987654321"
            },
            livekit_stack: "static"
          }
        end

        let(:update_response) do
          {
            "phone_number" => "+1987654321",
            "label" => "SIP Support Line",
            "supports_inbound" => true,
            "supports_outbound" => true,
            "phone_number_id" => phone_number_id,
            "assigned_agent" => {
              "agent_id" => "agent789",
              "agent_name" => "SIP Agent"
            },
            "provider" => "sip_trunk",
            "inbound_trunk_config" => {
              "sip_uri" => "sip:new-inbound@example.com",
              "username" => "new_inbound_user",
              "auth_username" => "new_auth_user"
            },
            "outbound_trunk_config" => {
              "sip_uri" => "sip:new-outbound@example.com",
              "username" => "new_outbound_user",
              "auth_username" => "new_auth_user_out",
              "caller_id" => "+1987654321"
            },
            "livekit_stack" => "static"
          }
        end

        before do
          stub_request(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
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

        it "updates SIP trunk configuration through client interface" do
          result = client.phone_numbers.update(phone_number_id, **update_params)

          expect(result).to eq(update_response)
          expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
            .with(
              body: update_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      context "removing agent assignment" do
        let(:update_params) do
          {
            agent_id: nil
          }
        end

        let(:update_response) do
          {
            "phone_number" => "+1234567890",
            "label" => "Customer Service Main",
            "supports_inbound" => true,
            "supports_outbound" => true,
            "phone_number_id" => phone_number_id,
            "assigned_agent" => nil,
            "provider" => "twilio"
          }
        end

        before do
          stub_request(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
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

        it "removes agent assignment through client interface" do
          result = client.phone_numbers.update(phone_number_id, **update_params)

          expect(result).to eq(update_response)
          expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
            .with(
              body: update_params.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end
    end

    describe "deleting phone numbers" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes phone number through client interface" do
        result = client.phone_numbers.delete(phone_number_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end
  end

  describe "error handling integration" do
    let(:phone_number_id) { "nonexistent_phone" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Phone number not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing phone number" do
        expect { client.phone_numbers.get(phone_number_id) }
          .to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.phone_numbers.list }
          .to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      let(:invalid_params) do
        {
          phone_number: "",
          label: "",
          sid: "",
          token: ""
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: invalid_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Invalid phone number format" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.phone_numbers.import(**invalid_params) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "complex phone configuration integration" do
    describe "enterprise SIP trunk setup" do
      let(:enterprise_sip_params) do
        {
          phone_number: "+1800ENTERPRISE",
          label: "Enterprise SIP Trunk",
          provider_type: "sip_trunk",
          inbound_trunk_config: {
            sip_uri: "sip:enterprise-inbound@company.com",
            username: "enterprise_in",
            password: "secure_password_123",
            auth_username: "auth_enterprise_in"
          },
          outbound_trunk_config: {
            sip_uri: "sip:enterprise-outbound@company.com", 
            username: "enterprise_out",
            password: "secure_password_456",
            auth_username: "auth_enterprise_out",
            caller_id: "+1800ENTERPRISE"
          },
          livekit_stack: "static"
        }
      end

      let(:import_response) do
        {
          "phone_number_id" => "enterprise_phone_123"
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: enterprise_sip_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: import_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "imports enterprise SIP trunk configuration through client interface" do
        result = client.phone_numbers.import(**enterprise_sip_params)

        expect(result).to eq(import_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: enterprise_sip_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "multi-region phone setup" do
      let(:multi_region_response) do
        [
          {
            "phone_number" => "+1234567890",
            "label" => "US East Coast",
            "phone_number_id" => "phone_us_east",
            "provider" => "twilio",
            "assigned_agent" => {
              "agent_id" => "agent_us",
              "agent_name" => "US Support Agent"
            },
            "supports_inbound" => true,
            "supports_outbound" => true
          },
          {
            "phone_number" => "+44123456789",
            "label" => "UK Support",
            "phone_number_id" => "phone_uk",
            "provider" => "sip_trunk",
            "assigned_agent" => {
              "agent_id" => "agent_uk",
              "agent_name" => "UK Support Agent"
            },
            "supports_inbound" => true,
            "supports_outbound" => false,
            "inbound_trunk_config" => {
              "sip_uri" => "sip:uk-inbound@company.com"
            }
          },
          {
            "phone_number" => "+81123456789",
            "label" => "Japan Support",
            "phone_number_id" => "phone_jp",
            "provider" => "sip_trunk",
            "assigned_agent" => {
              "agent_id" => "agent_jp",
              "agent_name" => "Japan Support Agent"
            },
            "supports_inbound" => true,
            "supports_outbound" => true,
            "inbound_trunk_config" => {
              "sip_uri" => "sip:jp-inbound@company.com"
            },
            "outbound_trunk_config" => {
              "sip_uri" => "sip:jp-outbound@company.com",
              "caller_id" => "+81123456789"
            }
          }
        ]
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: multi_region_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles multi-region phone number configuration through client interface" do
        result = client.phone_numbers.list

        expect(result).to eq(multi_region_response)
        
        # Verify structure
        expect(result.length).to eq(3)
        expect(result.map { |phone| phone["provider"] }).to match_array(["twilio", "sip_trunk", "sip_trunk"])
        expect(result.all? { |phone| phone["assigned_agent"] }).to be true
        
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(headers: { "xi-api-key" => api_key })
      end
    end
  end

  describe "full workflow integration" do
    let(:phone_number_id) { "phone123" }
    let(:agent_id) { "agent456" }

    it "supports complete phone number lifecycle" do
      # Import phone number
      import_params = {
        phone_number: "+1555TEST01",
        label: "Test Phone Line",
        sid: "test_twilio_sid",
        token: "test_twilio_token"
      }

      stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
        .to_return(
          status: 200,
          body: { "phone_number_id" => phone_number_id }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get phone details
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
        .to_return(
          status: 200,
          body: {
            "phone_number_id" => phone_number_id,
            "phone_number" => "+1555TEST01",
            "label" => "Test Phone Line",
            "provider" => "twilio",
            "assigned_agent" => nil
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Assign agent
      stub_request(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
        .to_return(
          status: 200,
          body: {
            "phone_number_id" => phone_number_id,
            "phone_number" => "+1555TEST01",
            "assigned_agent" => { "agent_id" => agent_id, "agent_name" => "Test Agent" }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # List all phones
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
        .to_return(
          status: 200,
          body: [
            {
              "phone_number_id" => phone_number_id,
              "phone_number" => "+1555TEST01",
              "assigned_agent" => { "agent_id" => agent_id, "agent_name" => "Test Agent" }
            }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Delete phone
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      import_result = client.phone_numbers.import(**import_params)
      expect(import_result["phone_number_id"]).to eq(phone_number_id)

      get_result = client.phone_numbers.get(phone_number_id)
      expect(get_result["phone_number_id"]).to eq(phone_number_id)

      update_result = client.phone_numbers.update(phone_number_id, agent_id: agent_id)
      expect(update_result["assigned_agent"]["agent_id"]).to eq(agent_id)

      list_result = client.phone_numbers.list
      expect(list_result.first["phone_number_id"]).to eq(phone_number_id)

      delete_result = client.phone_numbers.delete(phone_number_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/phone-numbers")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/phone-numbers/#{phone_number_id}")
    end
  end

  describe "bulk operations integration" do
    describe "multiple phone imports" do
      let(:phone1_params) do
        {
          phone_number: "+1111111111",
          label: "Phone 1",
          sid: "sid1",
          token: "token1"
        }
      end

      let(:phone2_params) do
        {
          phone_number: "+2222222222", 
          label: "Phone 2",
          sid: "sid2",
          token: "token2"
        }
      end

      let(:response1) { { "phone_number_id" => "phone1" } }
      let(:response2) { { "phone_number_id" => "phone2" } }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: phone1_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: response1.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        stub_request(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: phone2_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: response2.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles multiple phone imports correctly through client interface" do
        result1 = client.phone_numbers.import(**phone1_params)
        result2 = client.phone_numbers.import(**phone2_params)
        
        expect(result1).to eq(response1)
        expect(result2).to eq(response2)
        
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: phone1_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/phone-numbers")
          .with(
            body: phone2_params.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end
  end
end
