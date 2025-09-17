# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::User do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:user) { described_class.new(client) }

  describe "#get_user" do
    let(:user_response) do
      {
        "user_id" => "1234567890",
        "subscription" => {
          "tier" => "trial",
          "character_count" => 17231,
          "character_limit" => 100000,
          "max_character_limit_extension" => 10000,
          "can_extend_character_limit" => false,
          "allowed_to_extend_character_limit" => false,
          "voice_slots_used" => 1,
          "professional_voice_slots_used" => 0,
          "voice_limit" => 120,
          "voice_add_edit_counter" => 212,
          "professional_voice_limit" => 1,
          "can_extend_voice_limit" => false,
          "can_use_instant_voice_cloning" => true,
          "can_use_professional_voice_cloning" => true,
          "status" => "free",
          "next_character_count_reset_unix" => 1738356858,
          "max_voice_add_edits" => 230,
          "currency" => "usd",
          "billing_period" => "monthly_period",
          "character_refresh_period" => "monthly_period"
        },
        "is_onboarding_completed" => true,
        "is_onboarding_checklist_completed" => true,
        "created_at" => 1753999199,
        "is_new_user" => false,
        "can_use_delayed_payment_methods" => false,
        "subscription_extras" => {
          "concurrency" => 10,
          "convai_concurrency" => 10,
          "force_logging_disabled" => false,
          "can_request_manual_pro_voice_verification" => true,
          "can_bypass_voice_captcha" => true,
          "moderation" => {
            "is_in_probation" => false,
            "enterprise_check_nogo_voice" => false,
            "enterprise_check_block_nogo_voice" => false,
            "never_live_moderate" => false,
            "nogo_voice_similar_voice_upload_count" => 0,
            "enterprise_background_moderation_enabled" => false,
            "on_watchlist" => false
          },
          "unused_characters_rolled_over_from_previous_period" => 1000,
          "overused_characters_rolled_over_from_previous_period" => 1000,
          "usage" => {
            "rollover_credits_quota" => 1000,
            "subscription_cycle_credits_quota" => 1000,
            "manually_gifted_credits_quota" => 1000,
            "rollover_credits_used" => 1000,
            "subscription_cycle_credits_used" => 1000,
            "manually_gifted_credits_used" => 1000,
            "paid_usage_based_credits_used" => 1000,
            "actual_reported_credits" => 1000
          }
        },
        "xi_api_key" => "8so27l7327189x0h939ekx293380l920",
        "first_name" => "John",
        "is_api_key_hashed" => false
      }
    end

    it "makes a GET request to /v1/user" do
      stub_request(:get, "https://api.elevenlabs.io/v1/user")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(
          status: 200,
          body: user_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = user.get_user

      expect(result).to eq(user_response)
    end

    context "when API returns an error" do
      it "raises AuthenticationError for 401 status" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          user.get_user
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end

      it "raises UnprocessableEntityError for 422 status" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 422,
            body: { "detail" => "User not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          user.get_user
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with subscription details" do
      it "returns subscription information" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = user.get_user

        expect(result["subscription"]).to include(
          "tier" => "trial",
          "character_count" => 17231,
          "character_limit" => 100000,
          "status" => "free"
        )
      end
    end

    context "with subscription extras" do
      it "returns subscription extras information" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = user.get_user

        expect(result["subscription_extras"]).to include(
          "concurrency" => 10,
          "convai_concurrency" => 10
        )
        expect(result["subscription_extras"]["moderation"]).to include(
          "is_in_probation" => false,
          "on_watchlist" => false
        )
        expect(result["subscription_extras"]["usage"]).to include(
          "rollover_credits_quota" => 1000,
          "subscription_cycle_credits_quota" => 1000
        )
      end
    end
  end

  describe "aliases" do
    it "has user alias for get_user" do
      expect(user.method(:user)).to eq(user.method(:get_user))
    end

    it "has info alias for get_user" do
      expect(user.method(:info)).to eq(user.method(:get_user))
    end
  end

  describe "#get_subscription" do
    let(:subscription_response) do
      {
        "tier" => "starter",
        "character_count" => 1000,
        "character_limit" => 10000,
        "max_character_limit_extension" => 10000,
        "can_extend_character_limit" => true,
        "allowed_to_extend_character_limit" => true,
        "voice_slots_used" => 1,
        "professional_voice_slots_used" => 0,
        "voice_limit" => 10,
        "voice_add_edit_counter" => 0,
        "professional_voice_limit" => 1,
        "can_extend_voice_limit" => true,
        "can_use_instant_voice_cloning" => true,
        "can_use_professional_voice_cloning" => true,
        "status" => "active",
        "open_invoices" => [],
        "has_open_invoices" => false,
        "next_character_count_reset_unix" => 1738356858,
        "currency" => "usd",
        "billing_period" => "monthly_period",
        "character_refresh_period" => "monthly_period",
        "next_invoice" => nil
      }
    end

    it "makes a GET request to /v1/user/subscription" do
      stub_request(:get, "https://api.elevenlabs.io/v1/user/subscription")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(status: 200, body: subscription_response.to_json, headers: { "Content-Type" => "application/json" })

      result = user.get_subscription
      expect(result).to include("tier" => "starter", "status" => "active")
      expect(result["character_limit"]).to eq(10000)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, "https://api.elevenlabs.io/v1/user/subscription")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(status: 401, body: { detail: "Invalid API key" }.to_json, headers: { "Content-Type" => "application/json" })

      expect { user.get_subscription }.to raise_error(ElevenlabsClient::AuthenticationError)
    end

    it "raises UnprocessableEntityError on 422" do
      stub_request(:get, "https://api.elevenlabs.io/v1/user/subscription")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(status: 422, body: { detail: "Invalid request" }.to_json, headers: { "Content-Type" => "application/json" })

      expect { user.get_subscription }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
    end
  end

  describe "private methods" do
    it "has client as a private attr_reader" do
      expect(user.send(:client)).to eq(client)
    end
  end
end
