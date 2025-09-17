# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::PhoneNumbers do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:phone_numbers) { described_class.new(client) }

  describe "#import" do
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
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", twilio_params)
                                      .and_return(import_response)
      end

      it "imports Twilio phone number successfully" do
        result = phone_numbers.import(**twilio_params)
        expect(result).to eq(import_response)
        expect(client).to have_received(:post).with("/v1/convai/phone-numbers", twilio_params)
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
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", sip_params)
                                      .and_return(import_response)
      end

      it "imports SIP trunk phone number successfully" do
        result = phone_numbers.import(**sip_params)
        expect(result).to eq(import_response)
        expect(client).to have_received(:post).with("/v1/convai/phone-numbers", sip_params)
      end
    end
  end

  describe "#list" do
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
      allow(client).to receive(:get).with("/v1/convai/phone-numbers")
                                   .and_return(list_response)
    end

    it "lists phone numbers successfully" do
      result = phone_numbers.list
      expect(result).to eq(list_response)
      expect(client).to have_received(:get).with("/v1/convai/phone-numbers")
    end
  end

  describe "#get" do
    let(:phone_number_id) { "phone123" }
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
      allow(client).to receive(:get).with("/v1/convai/phone-numbers/#{phone_number_id}")
                                   .and_return(phone_response)
    end

    it "retrieves phone number details successfully" do
      result = phone_numbers.get(phone_number_id)
      expect(result).to eq(phone_response)
      expect(client).to have_received(:get).with("/v1/convai/phone-numbers/#{phone_number_id}")
    end
  end

  describe "#update" do
    let(:phone_number_id) { "phone123" }

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
        allow(client).to receive(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
                                       .and_return(update_response)
      end

      it "updates phone number with agent assignment" do
        result = phone_numbers.update(phone_number_id, **update_params)
        expect(result).to eq(update_response)
        expect(client).to have_received(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
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
          "inbound_trunk_config" => update_params[:inbound_trunk_config],
          "outbound_trunk_config" => update_params[:outbound_trunk_config],
          "livekit_stack" => "static"
        }
      end

      before do
        allow(client).to receive(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
                                       .and_return(update_response)
      end

      it "updates SIP trunk configuration successfully" do
        result = phone_numbers.update(phone_number_id, **update_params)
        expect(result).to eq(update_response)
        expect(client).to have_received(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
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
        allow(client).to receive(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
                                       .and_return(update_response)
      end

      it "removes agent assignment successfully" do
        result = phone_numbers.update(phone_number_id, **update_params)
        expect(result).to eq(update_response)
        expect(client).to have_received(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", update_params)
      end
    end
  end

  describe "#delete" do
    let(:phone_number_id) { "phone123" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/phone-numbers/#{phone_number_id}")
                                      .and_return(delete_response)
    end

    it "deletes phone number successfully" do
      result = phone_numbers.delete(phone_number_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/phone-numbers/#{phone_number_id}")
    end
  end

  describe "error handling" do
    let(:phone_number_id) { "nonexistent_phone" }

    context "when phone number is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/phone-numbers/#{phone_number_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Phone number not found")
      end

      it "raises NotFoundError" do
        expect { phone_numbers.get(phone_number_id) }
          .to raise_error(ElevenlabsClient::NotFoundError, "Phone number not found")
      end
    end

    context "when validation fails on import" do
      let(:invalid_params) do
        {
          phone_number: "",
          label: "",
          sid: "",
          token: ""
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", invalid_params)
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid phone number format")
      end

      it "raises UnprocessableEntityError" do
        expect { phone_numbers.import(**invalid_params) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid phone number format")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/phone-numbers")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { phone_numbers.list }
          .to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "parameter handling" do
    describe "#import" do
      context "with minimal Twilio parameters" do
        let(:minimal_params) do
          {
            phone_number: "+1234567890",
            label: "Test Line"
          }
        end

        let(:import_response) do
          {
            "phone_number_id" => "phone123"
          }
        end

        before do
          allow(client).to receive(:post).with("/v1/convai/phone-numbers", minimal_params)
                                        .and_return(import_response)
        end

        it "handles minimal parameters correctly" do
          result = phone_numbers.import(**minimal_params)
          expect(result).to eq(import_response)
          expect(client).to have_received(:post).with("/v1/convai/phone-numbers", minimal_params)
        end
      end
    end

    describe "#update" do
      let(:phone_number_id) { "phone123" }

      context "with empty update parameters" do
        let(:empty_params) { {} }
        let(:update_response) do
          {
            "phone_number_id" => phone_number_id,
            "message" => "No changes made"
          }
        end

        before do
          allow(client).to receive(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", empty_params)
                                         .and_return(update_response)
        end

        it "handles empty parameters" do
          result = phone_numbers.update(phone_number_id, **empty_params)
          expect(result).to eq(update_response)
          expect(client).to have_received(:patch).with("/v1/convai/phone-numbers/#{phone_number_id}", empty_params)
        end
      end
    end
  end

  describe "complex phone configurations" do
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
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", enterprise_sip_params)
                                      .and_return(import_response)
      end

      it "imports enterprise SIP trunk configuration successfully" do
        result = phone_numbers.import(**enterprise_sip_params)
        expect(result).to eq(import_response)
        expect(client).to have_received(:post).with("/v1/convai/phone-numbers", enterprise_sip_params)
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
            }
          },
          {
            "phone_number" => "+44123456789",
            "label" => "UK Support",
            "phone_number_id" => "phone_uk",
            "provider" => "sip_trunk",
            "assigned_agent" => {
              "agent_id" => "agent_uk",
              "agent_name" => "UK Support Agent"
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
            }
          }
        ]
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/phone-numbers")
                                     .and_return(multi_region_response)
      end

      it "handles multi-region phone number configuration" do
        result = phone_numbers.list
        expect(result).to eq(multi_region_response)
        
        # Verify structure
        expect(result.length).to eq(3)
        expect(result.map { |phone| phone["provider"] }).to match_array(["twilio", "sip_trunk", "sip_trunk"])
        expect(result.all? { |phone| phone["assigned_agent"] }).to be true
      end
    end
  end

  describe "bulk operations handling" do
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
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", phone1_params)
                                      .and_return(response1)
        allow(client).to receive(:post).with("/v1/convai/phone-numbers", phone2_params)
                                      .and_return(response2)
      end

      it "handles multiple phone imports correctly" do
        result1 = phone_numbers.import(**phone1_params)
        result2 = phone_numbers.import(**phone2_params)
        
        expect(result1).to eq(response1)
        expect(result2).to eq(response2)
        expect(client).to have_received(:post).with("/v1/convai/phone-numbers", phone1_params)
        expect(client).to have_received(:post).with("/v1/convai/phone-numbers", phone2_params)
      end
    end
  end
end
