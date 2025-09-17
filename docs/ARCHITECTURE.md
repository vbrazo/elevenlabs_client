# ElevenLabs Client Architecture

This document describes the refactored architecture of the ElevenLabs Ruby client, designed for better maintainability, code cleanliness, and extensibility.

## Architecture Overview

The client has been refactored with the following key improvements:

### 1. Separation of Concerns

- **Client Class**: Manages endpoint initialization and provides a clean API
- **HttpClient Class**: Handles all HTTP communication and error handling
- **Configuration Class**: Manages client configuration and validation
- **Endpoint Classes**: Focus solely on business logic and API endpoints

### 2. Improved Error Handling

All HTTP errors are now handled consistently in the `HttpClient` class with proper error types:

- `400` → `BadRequestError`
- `401` → `AuthenticationError` 
- `402` → `PaymentRequiredError`
- `403` → `ForbiddenError`
- `404` → `NotFoundError`
- `408` → `TimeoutError`
- `422` → `UnprocessableEntityError`
- `429` → `RateLimitError`
- `503` → `ServiceUnavailableError`

### 3. Clean Configuration Management

```ruby
# Global configuration
ElevenlabsClient.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "https://custom.api.url"
  config.timeout = 30
  config.retry_count = 3
end

# Per-instance configuration
client = ElevenlabsClient.new(
  api_key: "specific-key",
  timeout: 60
)
```

### 4. Consistent Endpoint Patterns

All endpoints now follow consistent patterns:

- Parameter validation using `validate_required!`
- Proper error handling
- Clear documentation
- Consistent method naming

## File Structure

```
lib/elevenlabs_client/
├── client.rb                    # Main client class
├── http_client.rb              # HTTP communication layer
├── configuration.rb            # Configuration management
├── errors.rb                   # Error class definitions
├── settings.rb                 # Legacy settings support
├── version.rb                  # Version information
└── endpoints/
    ├── admin/                  # Admin API endpoints
    │   ├── models.rb
    │   ├── history.rb
    │   └── ...
    ├── agents_platform/        # Agents Platform endpoints
    │   ├── agents.rb
    │   ├── conversations.rb
    │   ├── llm_usage.rb
    │   ├── mcp_servers.rb
    │   └── ...
    ├── text_to_speech.rb      # Core TTS endpoints
    ├── voices.rb              # Voice management
    └── ...
```

## Key Components

### Client Class

The main entry point that:
- Manages configuration and HTTP client initialization
- Provides access to all endpoint classes
- Delegates HTTP methods for backward compatibility
- Offers health checking and debugging capabilities

```ruby
client = ElevenlabsClient.new(api_key: "your-key")

# Access endpoints
client.text_to_speech.convert("voice_id", "Hello world")
client.agents.create(conversation_config: {...})
client.llm_usage.calculate(prompt_length: 800, number_of_pages: 25, rag_enabled: true)

# Health check
status = client.health_check
puts status[:status]  # :ok or :error
```

### HttpClient Class

Handles all HTTP communication:
- Faraday connection management
- Request/response handling
- Error mapping and extraction
- Support for various content types (JSON, binary, multipart, streaming)

### Configuration Class

Manages all client configuration:
- API key resolution (explicit > Settings > ENV)
- Base URL configuration
- Timeout and retry settings
- Validation and error checking

```ruby
config = ElevenlabsClient::Configuration.new
config.api_key = "your-key"
config.timeout = 30
config.retry_count = 3
config.validate!  # Raises if invalid
```

### Endpoint Classes

Each endpoint class:
- Focuses on a specific API area
- Uses consistent parameter validation
- Provides clear method documentation
- Handles business logic without HTTP concerns

## Benefits of the New Architecture

### 1. Maintainability

- **Single Responsibility**: Each class has a clear, focused purpose
- **Consistent Patterns**: All endpoints follow the same structure
- **Easy Testing**: Components can be tested in isolation
- **Clear Dependencies**: Explicit separation between HTTP and business logic

### 2. Extensibility

- **Easy to Add Endpoints**: Follow established patterns
- **Configuration Flexibility**: Add new configuration options easily
- **Error Handling**: Centralized and consistent across all endpoints
- **HTTP Methods**: Easy to add new HTTP patterns

### 3. Performance

- **Lazy Loading**: Endpoints are only initialized when needed
- **HTTP Connection Reuse**: Single Faraday connection per client
- **Efficient Error Handling**: Fast error detection and mapping

### 4. Developer Experience

- **Clear API**: Intuitive method names and parameter handling
- **Good Documentation**: Comprehensive inline documentation
- **Error Messages**: Descriptive error messages with context
- **Debugging**: Built-in health checks and inspection methods

## Usage Examples

### Basic Usage

```ruby
require 'elevenlabs_client'

# Simple client creation
client = ElevenlabsClient.new(api_key: "your-api-key")

# Use any endpoint
speech = client.text_to_speech.convert("voice_id", "Hello world")
agents = client.agents.list
usage = client.llm_usage.calculate(prompt_length: 500, number_of_pages: 10, rag_enabled: true)
```

### Advanced Configuration

```ruby
# Global configuration
ElevenlabsClient.configure do |config|
  config.api_key = ENV['ELEVENLABS_API_KEY']
  config.base_url = "https://api.elevenlabs.io"
  config.timeout = 60
  config.retry_count = 5
  config.retry_delay = 2
end

# Use globally configured client
client = ElevenlabsClient.client

# Or override specific settings
custom_client = ElevenlabsClient.new(
  timeout: 120,  # Override just timeout
  # Other settings inherited from global config
)
```

### Error Handling

```ruby
begin
  result = client.agents.create(conversation_config: invalid_config)
rescue ElevenlabsClient::ValidationError => e
  puts "Validation failed: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limited: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

### Health Monitoring

```ruby
# Check client health
health = client.health_check
if health[:status] == :ok
  puts "Client is healthy"
else
  puts "Client error: #{health[:message]}"
end

# Check library health
library_health = ElevenlabsClient.health_check
puts "Library status: #{library_health[:status]}"
puts "Version: #{library_health[:library_version]}"
```

### Configuration Debugging

```ruby
# Get configuration information
config = client.configuration
puts config.to_h

# Get version information
version_info = ElevenlabsClient.version_info
puts "Version: #{version_info[:version]}"
puts "Ruby: #{version_info[:ruby_version]}"
```

## Migration Guide

### From Old Architecture

The refactored client maintains backward compatibility, but here are the key changes:

#### Before (Old)
```ruby
client = ElevenlabsClient::Client.new(api_key: "key")
# Direct access to instance variables
# Limited configuration options
# Manual error handling in each endpoint
```

#### After (New)
```ruby
client = ElevenlabsClient.new(api_key: "key")
# Same endpoint access
# Enhanced configuration management
# Consistent error handling
# Better debugging capabilities
```

### Configuration Changes

#### Before
```ruby
# Limited configuration
client = ElevenlabsClient::Client.new(
  api_key: "key",
  base_url: "url"
)
```

#### After
```ruby
# Rich configuration options
ElevenlabsClient.configure do |config|
  config.api_key = "key"
  config.base_url = "url"
  config.timeout = 30
  config.retry_count = 3
end

client = ElevenlabsClient.new
```

## Best Practices

### 1. Configuration

- Use global configuration for application-wide settings
- Use per-instance configuration for specific use cases
- Always validate configuration before use
- Use environment variables for sensitive data

### 2. Error Handling

- Catch specific error types rather than generic exceptions
- Use the built-in error hierarchy
- Implement retry logic for transient errors
- Log errors appropriately

### 3. Performance

- Reuse client instances when possible
- Use health checks to verify connectivity
- Monitor configuration for optimal settings

### 4. Testing

- Mock the HttpClient for unit tests
- Use the health check method for integration tests
- Test configuration validation
- Test error handling scenarios

## Future Enhancements

The new architecture enables future improvements:

1. **Connection Pooling**: Easy to add HTTP connection pooling
2. **Caching**: Add response caching at the HTTP layer
3. **Metrics**: Add request/response metrics collection
4. **Middleware**: Add request/response middleware support
5. **Async Support**: Add async/await support for Ruby 3.1+

## Conclusion

The refactored architecture provides:
- **Better maintainability** through separation of concerns
- **Improved extensibility** with consistent patterns
- **Enhanced developer experience** with better error handling and configuration
- **Future-ready design** that can accommodate new features

All existing functionality remains available with the same API, ensuring smooth migration while providing the foundation for future improvements.
