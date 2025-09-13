# ElevenlabsClient

A Ruby client library for interacting with ElevenLabs APIs, including dubbing and voice synthesis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elevenlabs_client', path: 'lib/elevenlabs_client'
```

And then execute:

    $ bundle install

## Usage

### Configuration

#### Rails Initializer (Recommended for Rails apps)

Create `config/initializers/elevenlabs_client.rb`:

```ruby
ElevenlabsClient::Settings.configure do |config|
  config.properties = {
    elevenlabs_base_uri: ENV["ELEVENLABS_BASE_URL"],
    elevenlabs_api_key: ENV["ELEVENLABS_API_KEY"],
  }
end
```

Once configured this way, you can create clients without passing any parameters:

```ruby
client = ElevenlabsClient.new
# Uses the configured settings automatically
```

#### Alternative Configuration Syntax

You can also use the module-level configure method:

```ruby
ElevenlabsClient.configure do |config|
  config.properties = {
    elevenlabs_base_uri: "https://api.elevenlabs.io",
    elevenlabs_api_key: "your_api_key_here"
  }
end
```

#### Configuration Precedence

The client uses the following precedence order for configuration:

1. **Explicit parameters** passed to `Client.new` (highest priority)
2. **Settings.properties** configured via initializer
3. **Environment variables** (lowest priority)

This allows you to set defaults in your initializer while still being able to override them when needed.

### Client Initialization

There are several ways to create a client:

```ruby
# Using environment variables (default behavior)
client = ElevenlabsClient.new

# Passing API key directly
client = ElevenlabsClient::Client.new(api_key: "your_api_key_here")

# Custom base URL
client = ElevenlabsClient::Client.new(
  api_key: "your_api_key_here",
  base_url: "https://custom-api.elevenlabs.io"
)

# Custom environment variable names
client = ElevenlabsClient::Client.new(
  api_key_env: "MY_CUSTOM_API_KEY_VAR",
  base_url_env: "MY_CUSTOM_BASE_URL_VAR"
)
```

### Basic Usage

```ruby
require 'elevenlabs_client'

# Create a client
client = ElevenlabsClient.new

# Create a dubbing job
File.open("video.mp4", "rb") do |file|
  result = client.dubs.create(
    file_io: file,
    filename: "video.mp4",
    target_languages: ["es", "pt", "fr"],
    name: "My Video Dub",
    drop_background_audio: true,
    use_profanity_filter: false
  )
  
  puts "Dubbing job created: #{result['dubbing_id']}"
end

# Check dubbing status
dub_details = client.dubs.get("dubbing_id_here")
puts "Status: #{dub_details['status']}"

# List all dubbing jobs
dubs = client.dubs.list(dubbing_status: "dubbed")
puts "Completed dubs: #{dubs['dubs'].length}"

# Get dubbing resources (for editing)
resources = client.dubs.resources("dubbing_id_here")
puts "Audio files: #{resources['resources']['audio_files']}"
```

### Available Dubbing Methods

The client provides access to all dubbing endpoints through the `client.dubs` interface:

- `client.dubs.create(file_io:, filename:, target_languages:, **options)` - Create a new dubbing job
- `client.dubs.get(dubbing_id)` - Get dubbing job details
- `client.dubs.list(params = {})` - List dubbing jobs with optional filters
- `client.dubs.resources(dubbing_id)` - Get dubbing resources for editing

## Supported Language Codes

Common target languages include:
- `es` - Spanish
- `pt` - Portuguese
- `fr` - French
- `de` - German
- `it` - Italian
- `pl` - Polish
- `ja` - Japanese
- `ko` - Korean
- `zh` - Chinese
- `hi` - Hindi

## Error Handling

The client raises specific exceptions for different error conditions:

```ruby
begin
  client.create_dub(...)
rescue ElevenlabsClient::AuthenticationError => e
  puts "Invalid API key: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::ValidationError => e
  puts "Validation error: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
