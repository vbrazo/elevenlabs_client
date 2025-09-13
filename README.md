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

Set your ElevenLabs API key as an environment variable:

```bash
export ELEVENLABS_API_KEY="your_api_key_here"
```

Or pass it directly when creating a client:

```ruby
client = ElevenlabsClient::Client.new(api_key: "your_api_key_here")
```

### Basic Usage

```ruby
require 'elevenlabs_client'

# Create a client
client = ElevenlabsClient.new

# Create a dubbing job
File.open("video.mp4", "rb") do |file|
  result = client.create_dub(
    file_io: file,
    filename: "video.mp4",
    target_languages: ["es", "pt", "fr"],
    name: "My Video Dub",
    options: {
      drop_background_audio: true,
      use_profanity_filter: false
    }
  )
  
  puts "Dubbing job created: #{result['dubbing_id']}"
end

# Check dubbing status
dub_details = client.get_dub("dubbing_id_here")
puts "Status: #{dub_details['status']}"

# List all dubbing jobs
dubs = client.list_dubs(dubbing_status: "dubbed")
puts "Completed dubs: #{dubs.length}"
```

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
