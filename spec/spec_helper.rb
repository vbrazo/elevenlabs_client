# frozen_string_literal: true

require "elevenlabs_client"
require "webmock/rspec"
require "tempfile"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure WebMock
  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # Helper methods
  config.include Module.new {
    def fixture_file(filename)
      File.join(File.dirname(__FILE__), "fixtures", filename)
    end

    def create_temp_video_file(content = "fake video content")
      file = Tempfile.new(["test_video", ".mp4"])
      file.write(content)
      file.rewind
      file
    end

    def stub_elevenlabs_api(endpoint:, method: :post, status: 200, response_body: {})
      stub_request(method, "https://api.elevenlabs.io#{endpoint}")
        .to_return(
          status: status,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  }
end
