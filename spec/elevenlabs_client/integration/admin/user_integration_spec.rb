# frozen_string_literal: true

RSpec.describe "ElevenlabsClient User Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.user accessor" do
    it "provides access to user endpoint" do
      expect(client.user).to be_an_instance_of(ElevenlabsClient::Admin::User)
    end
  end

  describe "user information functionality via client" do
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

    context "basic user information retrieval" do
      it "successfully retrieves user information" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.user.get_user

        expect(result).to eq(user_response)
        expect(result["user_id"]).to eq("1234567890")
        expect(result["first_name"]).to eq("John")
      end
    end

    context "subscription information validation" do
      it "returns complete subscription details" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.user.get_user

        subscription = result["subscription"]
        expect(subscription).to include(
          "tier" => "trial",
          "character_count" => 17231,
          "character_limit" => 100000,
          "voice_slots_used" => 1,
          "voice_limit" => 120,
          "status" => "free",
          "currency" => "usd",
          "billing_period" => "monthly_period"
        )

        expect(subscription["can_use_instant_voice_cloning"]).to be true
        expect(subscription["can_use_professional_voice_cloning"]).to be true
        expect(subscription["can_extend_character_limit"]).to be false
      end
    end

    context "subscription extras validation" do
      it "returns complete subscription extras" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.user.get_user

        extras = result["subscription_extras"]
        expect(extras).to include(
          "concurrency" => 10,
          "convai_concurrency" => 10,
          "force_logging_disabled" => false,
          "can_request_manual_pro_voice_verification" => true,
          "can_bypass_voice_captcha" => true
        )

        moderation = extras["moderation"]
        expect(moderation).to include(
          "is_in_probation" => false,
          "enterprise_check_nogo_voice" => false,
          "enterprise_check_block_nogo_voice" => false,
          "never_live_moderate" => false,
          "nogo_voice_similar_voice_upload_count" => 0,
          "enterprise_background_moderation_enabled" => false,
          "on_watchlist" => false
        )

        usage = extras["usage"]
        expect(usage).to include(
          "rollover_credits_quota" => 1000,
          "subscription_cycle_credits_quota" => 1000,
          "manually_gifted_credits_quota" => 1000,
          "rollover_credits_used" => 1000,
          "subscription_cycle_credits_used" => 1000,
          "manually_gifted_credits_used" => 1000,
          "paid_usage_based_credits_used" => 1000,
          "actual_reported_credits" => 1000
        )
      end
    end

    context "API key information" do
      it "includes API key information when available" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.user.get_user

        expect(result["xi_api_key"]).to eq("8so27l7327189x0h939ekx293380l920")
        expect(result["is_api_key_hashed"]).to be false
      end
    end

    context "onboarding status" do
      it "includes onboarding completion status" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: user_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.user.get_user

        expect(result["is_onboarding_completed"]).to be true
        expect(result["is_onboarding_checklist_completed"]).to be true
        expect(result["created_at"]).to eq(1753999199)
        expect(result["is_new_user"]).to be false
      end
    end

    context "error handling" do
      it "handles authentication errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.user.get_user
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end

      it "handles validation errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/user")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 422,
            body: { "detail" => "User not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.user.get_user
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "user method aliases" do
    it "provides user alias" do
      expect(client.user.method(:user)).to eq(client.user.method(:get_user))
    end

    it "provides info alias" do
      expect(client.user.method(:info)).to eq(client.user.method(:get_user))
    end
  end
end
