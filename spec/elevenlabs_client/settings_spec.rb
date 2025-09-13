# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Settings do
  after do
    # Clean up after each test
    described_class.reset!
  end

  describe ".configure" do
    it "allows setting properties via block" do
      described_class.configure do |config|
        config.properties = {
          elevenlabs_base_uri: "https://custom.elevenlabs.io",
          elevenlabs_api_key: "custom_api_key"
        }
      end

      expect(described_class.properties[:elevenlabs_base_uri]).to eq("https://custom.elevenlabs.io")
      expect(described_class.properties[:elevenlabs_api_key]).to eq("custom_api_key")
    end

    it "initializes properties as empty hash if not set" do
      described_class.configure
      expect(described_class.properties).to eq({})
    end
  end

  describe ".elevenlabs_base_uri" do
    context "when properties are set" do
      before do
        described_class.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io"
          }
        end
      end

      it "returns the configured base URI" do
        expect(described_class.elevenlabs_base_uri).to eq("https://configured.elevenlabs.io")
      end
    end

    context "when properties are not set but ENV is" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_BASE_URL").and_return("https://env.elevenlabs.io")
      end

      it "returns the environment variable value" do
        expect(described_class.elevenlabs_base_uri).to eq("https://env.elevenlabs.io")
      end
    end

    context "when neither properties nor ENV are set" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_BASE_URL").and_return(nil)
      end

      it "returns the default base URL" do
        expect(described_class.elevenlabs_base_uri).to eq("https://api.elevenlabs.io")
      end
    end

    context "when both properties and ENV are set" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_BASE_URL").and_return("https://env.elevenlabs.io")
        described_class.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io"
          }
        end
      end

      it "prioritizes the configured properties over ENV" do
        expect(described_class.elevenlabs_base_uri).to eq("https://configured.elevenlabs.io")
      end
    end
  end

  describe ".elevenlabs_api_key" do
    context "when properties are set" do
      before do
        described_class.configure do |config|
          config.properties = {
            elevenlabs_api_key: "configured_api_key"
          }
        end
      end

      it "returns the configured API key" do
        expect(described_class.elevenlabs_api_key).to eq("configured_api_key")
      end
    end

    context "when properties are not set but ENV is" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_API_KEY").and_return("env_api_key")
      end

      it "returns the environment variable value" do
        expect(described_class.elevenlabs_api_key).to eq("env_api_key")
      end
    end

    context "when neither properties nor ENV are set" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_API_KEY").and_return(nil)
      end

      it "returns nil" do
        expect(described_class.elevenlabs_api_key).to be_nil
      end
    end

    context "when both properties and ENV are set" do
      before do
        allow(ENV).to receive(:[]).with("ELEVENLABS_API_KEY").and_return("env_api_key")
        described_class.configure do |config|
          config.properties = {
            elevenlabs_api_key: "configured_api_key"
          }
        end
      end

      it "prioritizes the configured properties over ENV" do
        expect(described_class.elevenlabs_api_key).to eq("configured_api_key")
      end
    end
  end

  describe ".reset!" do
    it "clears all properties" do
      described_class.configure do |config|
        config.properties = {
          elevenlabs_base_uri: "https://custom.elevenlabs.io",
          elevenlabs_api_key: "custom_api_key"
        }
      end

      described_class.reset!

      expect(described_class.properties).to eq({})
    end
  end
end
