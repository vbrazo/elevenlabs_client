# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Secrets do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:secrets) { described_class.new(client) }

  describe "#list" do
    let(:list_response) do
      {
        "secrets" => [
          {
            "id" => "secret123",
            "name" => "API_KEY",
            "created_at_unix_secs" => 1716153600,
            "last_updated_at_unix_secs" => 1716240000,
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "John Doe",
              "creator_email" => "john@example.com",
              "role" => "admin"
            }
          },
          {
            "id" => "secret456",
            "name" => "DATABASE_URL",
            "created_at_unix_secs" => 1716153600,
            "last_updated_at_unix_secs" => 1716240000,
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "Jane Smith",
              "creator_email" => "jane@example.com",
              "role" => "admin"
            }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/secrets")
                                   .and_return(list_response)
    end

    it "lists secrets successfully" do
      result = secrets.list
      expect(result).to eq(list_response)
      expect(client).to have_received(:get).with("/v1/convai/secrets")
    end
  end

  describe "#create" do
    let(:name) { "API_KEY" }
    let(:value) { "sk-1234567890abcdef" }
    let(:create_response) do
      {
        "id" => "secret789",
        "name" => name,
        "created_at_unix_secs" => 1716153600,
        "last_updated_at_unix_secs" => 1716153600,
        "access_info" => {
          "is_creator" => true,
          "creator_name" => "John Doe",
          "creator_email" => "john@example.com",
          "role" => "admin"
        }
      }
    end

    context "with default type" do
      let(:expected_body) do
        {
          type: "new",
          name: name,
          value: value
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/secrets", expected_body)
                                      .and_return(create_response)
      end

      it "creates secret successfully with default type" do
        result = secrets.create(name: name, value: value)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/secrets", expected_body)
      end
    end

    context "with custom type" do
      let(:type) { "update" }
      let(:expected_body) do
        {
          type: type,
          name: name,
          value: value
        }
      end

      before do
        allow(client).to receive(:post).with("/v1/convai/secrets", expected_body)
                                      .and_return(create_response)
      end

      it "creates secret successfully with custom type" do
        result = secrets.create(name: name, value: value, type: type)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/secrets", expected_body)
      end
    end

    context "with different secret types" do
      it "handles new secret type" do
        expected_body = { type: "new", name: name, value: value }
        allow(client).to receive(:post).with("/v1/convai/secrets", expected_body)
                                      .and_return(create_response)

        result = secrets.create(name: name, value: value, type: "new")
        expect(result).to eq(create_response)
      end

      it "handles update secret type" do
        expected_body = { type: "update", name: name, value: value }
        allow(client).to receive(:post).with("/v1/convai/secrets", expected_body)
                                      .and_return(create_response)

        result = secrets.create(name: name, value: value, type: "update")
        expect(result).to eq(create_response)
      end
    end
  end

  describe "#delete" do
    let(:secret_id) { "secret123" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/secrets/#{secret_id}")
                                      .and_return(delete_response)
    end

    it "deletes secret successfully" do
      result = secrets.delete(secret_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/secrets/#{secret_id}")
    end
  end

  describe "error handling" do
    let(:secret_id) { "nonexistent_secret" }
    let(:name) { "API_KEY" }
    let(:value) { "sk-1234567890abcdef" }

    context "when secret is not found" do
      before do
        allow(client).to receive(:delete).with("/v1/convai/secrets/#{secret_id}")
                                        .and_raise(ElevenlabsClient::NotFoundError, "Secret not found")
      end

      it "raises NotFoundError" do
        expect { secrets.delete(secret_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Secret not found")
      end
    end

    context "when secret name already exists" do
      let(:existing_name) { "EXISTING_KEY" }

      before do
        allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(name: existing_name))
                                      .and_raise(ElevenlabsClient::BadRequestError, "A secret with the name '#{existing_name}' already exists.")
      end

      it "raises BadRequestError" do
        expect { secrets.create(name: existing_name, value: value) }
          .to raise_error(ElevenlabsClient::BadRequestError, /already exists/)
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(name: "", value: value))
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Secret name is required")
      end

      it "raises UnprocessableEntityError" do
        expect { secrets.create(name: "", value: value) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Secret name is required")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/secrets")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { secrets.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when forbidden access" do
      before do
        allow(client).to receive(:delete).with("/v1/convai/secrets/#{secret_id}")
                                        .and_raise(ElevenlabsClient::ForbiddenError, "Access forbidden")
      end

      it "raises ForbiddenError" do
        expect { secrets.delete(secret_id) }.to raise_error(ElevenlabsClient::ForbiddenError, "Access forbidden")
      end
    end
  end

  describe "parameter handling" do
    describe "#create" do
      let(:name) { "API_KEY" }
      let(:value) { "sk-1234567890abcdef" }

      context "with special characters in name" do
        let(:special_name) { "API_KEY_123" }

        before do
          allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(name: special_name))
                                        .and_return({ "id" => "secret123" })
        end

        it "handles special characters in secret name" do
          result = secrets.create(name: special_name, value: value)
          expect(result["id"]).to eq("secret123")
        end
      end

      context "with long secret value" do
        let(:long_value) { "sk-" + "a" * 1000 }

        before do
          allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(value: long_value))
                                        .and_return({ "id" => "secret123" })
        end

        it "handles long secret values" do
          result = secrets.create(name: name, value: long_value)
          expect(result["id"]).to eq("secret123")
        end
      end

      context "with empty value" do
        before do
          allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(value: ""))
                                        .and_raise(ElevenlabsClient::BadRequestError, "Secret value is required")
        end

        it "raises error for empty value" do
          expect { secrets.create(name: name, value: "") }
            .to raise_error(ElevenlabsClient::BadRequestError, "Secret value is required")
        end
      end
    end

    describe "#delete" do
      context "with different secret ID formats" do
        it "handles UUID format" do
          uuid = "550e8400-e29b-41d4-a716-446655440000"
          allow(client).to receive(:delete).with("/v1/convai/secrets/#{uuid}")
                                          .and_return({})

          result = secrets.delete(uuid)
          expect(result).to eq({})
          expect(client).to have_received(:delete).with("/v1/convai/secrets/#{uuid}")
        end

        it "handles alphanumeric format" do
          alphanumeric_id = "secret123abc"
          allow(client).to receive(:delete).with("/v1/convai/secrets/#{alphanumeric_id}")
                                          .and_return({})

          result = secrets.delete(alphanumeric_id)
          expect(result).to eq({})
          expect(client).to have_received(:delete).with("/v1/convai/secrets/#{alphanumeric_id}")
        end
      end
    end
  end

  describe "workflow scenarios" do
    let(:name) { "API_KEY" }
    let(:value) { "sk-1234567890abcdef" }
    let(:secret_id) { "secret123" }

    it "supports full CRUD workflow" do
      # Create
      create_response = { "id" => secret_id, "name" => name }
      allow(client).to receive(:post).with("/v1/convai/secrets", hash_including(name: name, value: value))
                                    .and_return(create_response)

      created = secrets.create(name: name, value: value)
      expect(created["id"]).to eq(secret_id)

      # List
      list_response = { "secrets" => [{ "id" => secret_id, "name" => name }] }
      allow(client).to receive(:get).with("/v1/convai/secrets")
                                    .and_return(list_response)

      listed = secrets.list
      expect(listed["secrets"].first["id"]).to eq(secret_id)

      # Delete
      allow(client).to receive(:delete).with("/v1/convai/secrets/#{secret_id}")
                                      .and_return({})

      deleted = secrets.delete(secret_id)
      expect(deleted).to eq({})
    end

    it "handles multiple secrets with same name pattern" do
      secrets_list = [
        { "id" => "secret1", "name" => "API_KEY_PROD" },
        { "id" => "secret2", "name" => "API_KEY_STAGING" },
        { "id" => "secret3", "name" => "API_KEY_DEV" }
      ]

      list_response = { "secrets" => secrets_list }
      allow(client).to receive(:get).with("/v1/convai/secrets")
                                    .and_return(list_response)

      result = secrets.list
      expect(result["secrets"].length).to eq(3)
      expect(result["secrets"].map { |s| s["name"] }).to all(start_with("API_KEY"))
    end
  end
end

