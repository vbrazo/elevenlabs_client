# frozen_string_literal: true

RSpec.describe "Admin::ServiceAccounts Integration", :integration do
  let(:client) { ElevenlabsClient::Client.new }
  let(:service_accounts) { client.service_accounts }

  describe "#get_service_accounts" do
    context "when retrieving service accounts", :vcr do
      it "successfully retrieves service accounts" do
        result = service_accounts.get_service_accounts
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("service-accounts")
        expect(result["service-accounts"]).to be_an(Array)
      end

      it "returns service accounts with expected structure" do
        result = service_accounts.get_service_accounts
        
        service_accounts_list = result["service-accounts"]
        
        if service_accounts_list.any?
          service_account = service_accounts_list.first
          
          expect(service_account).to have_key("service_account_user_id")
          expect(service_account).to have_key("name")
          expect(service_account).to have_key("api-keys")
          expect(service_account).to have_key("created_at_unix")
          
          expect(service_account["service_account_user_id"]).to be_a(String)
          expect(service_account["name"]).to be_a(String)
          expect(service_account["api-keys"]).to be_an(Array)
          expect(service_account["created_at_unix"]).to be_a(Integer)
          
          if service_account["api-keys"].any?
            api_key = service_account["api-keys"].first
            
            expect(api_key).to have_key("name")
            expect(api_key).to have_key("hint")
            expect(api_key).to have_key("key_id")
            expect(api_key).to have_key("service_account_user_id")
            expect(api_key).to have_key("created_at_unix")
            expect(api_key).to have_key("is_disabled")
            expect(api_key).to have_key("permissions")
            expect(api_key).to have_key("character_limit")
            expect(api_key).to have_key("character_count")
            
            expect(api_key["name"]).to be_a(String)
            expect(api_key["hint"]).to be_a(String)
            expect(api_key["key_id"]).to be_a(String)
            expect(api_key["service_account_user_id"]).to be_a(String)
            expect(api_key["created_at_unix"]).to be_a(Integer)
            expect(api_key["is_disabled"]).to be_in([true, false])
            expect(api_key["permissions"]).to be_an(Array)
            expect(api_key["character_limit"]).to be_a(Integer)
            expect(api_key["character_count"]).to be_a(Integer)
          end
        end
      end
    end

    context "when authentication fails", :vcr do
      let(:client_with_invalid_key) { ElevenlabsClient::Client.new(api_key: "invalid_key") }
      let(:service_accounts_with_invalid_key) { client_with_invalid_key.service_accounts }

      it "raises an AuthenticationError" do
        expect {
          service_accounts_with_invalid_key.get_service_accounts
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end
  end

  describe "aliases" do
    context "when using list alias", :vcr do
      it "successfully retrieves service accounts" do
        result = service_accounts.list
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("service-accounts")
        expect(result["service-accounts"]).to be_an(Array)
      end
    end

    context "when using all alias", :vcr do
      it "successfully retrieves service accounts" do
        result = service_accounts.all
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("service-accounts")
        expect(result["service-accounts"]).to be_an(Array)
      end
    end

    context "when using service_accounts alias", :vcr do
      it "successfully retrieves service accounts" do
        result = service_accounts.service_accounts
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("service-accounts")
        expect(result["service-accounts"]).to be_an(Array)
      end
    end
  end

  describe "response structure validation" do
    context "when service accounts exist", :vcr do
      it "validates complete response structure" do
        result = service_accounts.get_service_accounts
        
        expect(result).to be_a(Hash)
        expect(result.keys).to include("service-accounts")
        
        service_accounts_array = result["service-accounts"]
        expect(service_accounts_array).to be_an(Array)
        
        # If service accounts exist, validate their structure
        service_accounts_array.each do |service_account|
          expect(service_account).to be_a(Hash)
          
          # Required fields
          expect(service_account).to have_key("service_account_user_id")
          expect(service_account).to have_key("name")
          expect(service_account).to have_key("api-keys")
          expect(service_account).to have_key("created_at_unix")
          
          # Field types
          expect(service_account["service_account_user_id"]).to be_a(String)
          expect(service_account["name"]).to be_a(String)
          expect(service_account["api-keys"]).to be_an(Array)
          expect(service_account["created_at_unix"]).to be_a(Integer)
          
          # Validate API keys structure
          service_account["api-keys"].each do |api_key|
            expect(api_key).to be_a(Hash)
            
            # Required API key fields
            expect(api_key).to have_key("name")
            expect(api_key).to have_key("hint")
            expect(api_key).to have_key("key_id")
            expect(api_key).to have_key("service_account_user_id")
            expect(api_key).to have_key("created_at_unix")
            expect(api_key).to have_key("is_disabled")
            expect(api_key).to have_key("permissions")
            expect(api_key).to have_key("character_limit")
            expect(api_key).to have_key("character_count")
            
            # API key field types
            expect(api_key["name"]).to be_a(String)
            expect(api_key["hint"]).to be_a(String)
            expect(api_key["key_id"]).to be_a(String)
            expect(api_key["service_account_user_id"]).to be_a(String)
            expect(api_key["created_at_unix"]).to be_a(Integer)
            expect(api_key["is_disabled"]).to be_in([true, false])
            expect(api_key["permissions"]).to be_an(Array)
            expect(api_key["character_limit"]).to be_a(Integer)
            expect(api_key["character_count"]).to be_a(Integer)
            
            # Validate permissions array contains valid permission strings
            api_key["permissions"].each do |permission|
              expect(permission).to be_a(String)
              expect(permission).to match(/\A[a-z_]+\z/) # Basic validation for permission format
            end
            
            # Validate character counts are non-negative
            expect(api_key["character_limit"]).to be >= 0
            expect(api_key["character_count"]).to be >= 0
          end
        end
      end
    end
  end

  describe "error handling" do
    context "when there are no service accounts", :vcr do
      it "returns empty array without errors" do
        result = service_accounts.get_service_accounts
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("service-accounts")
        
        # Should be an array, even if empty
        expect(result["service-accounts"]).to be_an(Array)
      end
    end
  end
end
