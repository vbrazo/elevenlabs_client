# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Settings Integration" do
  after do
    # Clean up after each test
    ElevenlabsClient::Settings.reset!
  end

  describe "Client initialization with Settings" do
    context "when Settings are configured" do
      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end
      end

      it "uses Settings for API key and base URL" do
        client = ElevenlabsClient::Client.new

        expect(client.api_key).to eq("configured_api_key")
        expect(client.base_url).to eq("https://configured.elevenlabs.io")
      end

      it "allows overriding Settings with explicit parameters" do
        client = ElevenlabsClient::Client.new(
          api_key: "override_api_key",
          base_url: "https://override.elevenlabs.io"
        )

        expect(client.api_key).to eq("override_api_key")
        expect(client.base_url).to eq("https://override.elevenlabs.io")
      end
    end

    context "when Settings are partially configured" do
      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_api_key: "configured_api_key"
            # elevenlabs_base_uri is not set
          }
        end
      end

      it "uses Settings for configured values and defaults for others" do
        client = ElevenlabsClient::Client.new

        expect(client.api_key).to eq("configured_api_key")
        expect(client.base_url).to eq("https://api.elevenlabs.io") # default
      end
    end

    context "when Settings are not configured" do
      before do
        allow(ENV).to receive(:fetch).with("ELEVENLABS_API_KEY").and_yield
        allow(ENV).to receive(:fetch).with("ELEVENLABS_BASE_URL", "https://api.elevenlabs.io").and_return("https://api.elevenlabs.io")
      end

      it "falls back to ENV variables and raises appropriate errors" do
        expect {
          ElevenlabsClient::Client.new
        }.to raise_error(ElevenlabsClient::AuthenticationError, /ELEVENLABS_API_KEY environment variable is required but not set and Settings.properties\[:elevenlabs_api_key\] is not configured/)
      end
    end

    context "when Settings override ENV variables" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ELEVENLABS_API_KEY").and_return("env_api_key")
        allow(ENV).to receive(:[]).with("ELEVENLABS_BASE_URL").and_return("https://env.elevenlabs.io")
        
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end
      end

      it "prioritizes Settings over ENV variables" do
        client = ElevenlabsClient::Client.new

        expect(client.api_key).to eq("configured_api_key")
        expect(client.base_url).to eq("https://configured.elevenlabs.io")
      end
    end
  end

  describe "module-level configure method" do
    it "delegates to Settings.configure" do
      expect(ElevenlabsClient::Settings).to receive(:configure)
      
      ElevenlabsClient.configure do |config|
        config.properties = { test: "value" }
      end
    end
  end

  describe "Rails initializer example" do
    it "can be configured like the example in the requirements" do
      # This simulates what would be in config/initializers/elevenlabs_client.rb
      ElevenlabsClient::Settings.configure do |config|
        config.properties = {
          elevenlabs_base_uri: ENV["ELEVENLABS_BASE_URL"],
          elevenlabs_api_key: ENV["ELEVENLABS_API_KEY"],
        }
      end

      # Simulate ENV variables being set
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ELEVENLABS_BASE_URL").and_return("https://myapp.elevenlabs.io")
      allow(ENV).to receive(:[]).with("ELEVENLABS_API_KEY").and_return("myapp_api_key")

      # Configure again to pick up the ENV values
      ElevenlabsClient::Settings.configure do |config|
        config.properties = {
          elevenlabs_base_uri: ENV["ELEVENLABS_BASE_URL"],
          elevenlabs_api_key: ENV["ELEVENLABS_API_KEY"],
        }
      end

      client = ElevenlabsClient.new

      expect(client.api_key).to eq("myapp_api_key")
      expect(client.base_url).to eq("https://myapp.elevenlabs.io")
    end
  end
end
