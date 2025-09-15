# Admin Samples API

The Admin Samples API provides functionality for managing voice samples within the ElevenLabs platform. This endpoint allows administrators to delete voice samples from specific voices, enabling efficient voice library management and content moderation.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Available Methods](#available-methods)
- [Method Details](#method-details)
- [Response Structures](#response-structures)
- [Error Handling](#error-handling)
- [Usage Examples](#usage-examples)
- [Rails Integration](#rails-integration)
- [Best Practices](#best-practices)

## Overview

The Samples API is designed for administrative control over voice samples. It provides secure deletion capabilities for managing voice content, supporting content moderation workflows, and maintaining voice library quality.

### Key Features

- **Sample Deletion**: Remove specific samples from voices
- **Secure Operations**: All operations require proper authentication
- **Error Handling**: Comprehensive error responses for different scenarios
- **Audit Support**: Detailed logging and response information for tracking changes

### Use Cases

- **Content Moderation**: Remove inappropriate or problematic voice samples
- **Voice Curation**: Clean up voice libraries by removing low-quality samples
- **Compliance Management**: Delete samples that violate content policies
- **Voice Optimization**: Remove samples that negatively impact voice quality

## Authentication

All Admin Samples API requests require authentication using your ElevenLabs API key:

```ruby
client = ElevenlabsClient::Client.new(api_key: "your_api_key_here")
samples = client.samples
```

## Available Methods

The Samples endpoint provides the following methods:

| Method | Description | Aliases |
|--------|-------------|---------|
| `delete_sample` | Delete a voice sample by ID | `delete_voice_sample`, `remove_sample` |

## Method Details

### delete_sample

Removes a sample by its ID from a specific voice.

```ruby
result = client.samples.delete_sample(
  voice_id: "voice_id",
  sample_id: "sample_id"
)
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `voice_id` | String | Yes | ID of the voice containing the sample |
| `sample_id` | String | Yes | ID of the sample to delete |

#### Returns

Returns a hash containing the deletion status:

```ruby
{
  "status" => "ok"
}
```

#### Example

```ruby
# Delete a specific voice sample
result = client.samples.delete_sample(
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  sample_id: "sample_123abc"
)

puts result["status"] # => "ok"
```

## Response Structures

### Successful Deletion Response

```ruby
{
  "status" => "ok"
}
```

**Fields:**
- `status` (String): Indicates the success of the deletion operation. Will be "ok" for successful deletions.

## Error Handling

The Samples API handles various error scenarios with specific exception types:

### Common Errors

#### NotFoundError (404)
Raised when the voice or sample is not found:

```ruby
begin
  client.samples.delete_sample(voice_id: "invalid_id", sample_id: "sample_id")
rescue ElevenlabsClient::NotFoundError => e
  puts "Voice or sample not found: #{e.message}"
end
```

#### UnprocessableEntityError (422)
Raised when the request parameters are invalid:

```ruby
begin
  client.samples.delete_sample(voice_id: "", sample_id: "sample_id")
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid parameters: #{e.message}"
end
```

#### AuthenticationError (401)
Raised when the API key is invalid or missing:

```ruby
begin
  invalid_client = ElevenlabsClient::Client.new(api_key: "invalid_key")
  invalid_client.samples.delete_sample(voice_id: "voice_id", sample_id: "sample_id")
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

#### RateLimitError (429)
Raised when the rate limit is exceeded:

```ruby
begin
  client.samples.delete_sample(voice_id: "voice_id", sample_id: "sample_id")
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
  # Implement retry logic with exponential backoff
end
```

## Usage Examples

### Basic Sample Deletion

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

# Delete a sample
begin
  result = client.samples.delete_sample(
    voice_id: "21m00Tcm4TlvDq8ikWAM",
    sample_id: "sample_123abc"
  )
  
  if result["status"] == "ok"
    puts "Sample deleted successfully"
  else
    puts "Unexpected response: #{result}"
  end
rescue ElevenlabsClient::NotFoundError
  puts "Voice or sample not found"
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded, please wait"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

### Batch Sample Deletion

```ruby
# Delete multiple samples from a voice
voice_id = "21m00Tcm4TlvDq8ikWAM"
sample_ids = ["sample_1", "sample_2", "sample_3"]

deleted_samples = []
failed_deletions = []

sample_ids.each do |sample_id|
  begin
    result = client.samples.delete_sample(
      voice_id: voice_id,
      sample_id: sample_id
    )
    
    if result["status"] == "ok"
      deleted_samples << sample_id
      puts "Successfully deleted sample: #{sample_id}"
    else
      failed_deletions << { sample_id: sample_id, reason: "Unexpected response" }
    end
  rescue ElevenlabsClient::NotFoundError
    failed_deletions << { sample_id: sample_id, reason: "Not found" }
    puts "Sample not found: #{sample_id}"
  rescue ElevenlabsClient::RateLimitError
    puts "Rate limit hit, pausing..."
    sleep(1)
    retry
  rescue ElevenlabsClient::APIError => e
    failed_deletions << { sample_id: sample_id, reason: e.message }
    puts "Failed to delete sample #{sample_id}: #{e.message}"
  end
end

puts "Deleted #{deleted_samples.count} samples successfully"
puts "Failed to delete #{failed_deletions.count} samples" if failed_deletions.any?
```

### Using Aliases

```ruby
# All these methods do the same thing
client.samples.delete_sample(voice_id: "voice_id", sample_id: "sample_id")
client.samples.delete_voice_sample(voice_id: "voice_id", sample_id: "sample_id")
client.samples.remove_sample(voice_id: "voice_id", sample_id: "sample_id")
```

### Content Moderation Workflow

```ruby
class VoiceModerationService
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
  end

  def moderate_voice_samples(voice_id, flagged_sample_ids)
    moderation_results = {
      deleted: [],
      failed: [],
      not_found: []
    }

    flagged_sample_ids.each do |sample_id|
      begin
        result = @client.samples.delete_sample(
          voice_id: voice_id,
          sample_id: sample_id
        )
        
        if result["status"] == "ok"
          moderation_results[:deleted] << sample_id
          log_moderation_action(voice_id, sample_id, "deleted")
        else
          moderation_results[:failed] << sample_id
          log_moderation_action(voice_id, sample_id, "failed", result)
        end
      rescue ElevenlabsClient::NotFoundError
        moderation_results[:not_found] << sample_id
        log_moderation_action(voice_id, sample_id, "not_found")
      rescue ElevenlabsClient::APIError => e
        moderation_results[:failed] << sample_id
        log_moderation_action(voice_id, sample_id, "error", e.message)
      end
    end

    moderation_results
  end

  private

  def log_moderation_action(voice_id, sample_id, status, details = nil)
    Rails.logger.info "Voice moderation: voice=#{voice_id} sample=#{sample_id} status=#{status} details=#{details}"
  end
end

# Usage
service = VoiceModerationService.new
results = service.moderate_voice_samples("voice_id", ["sample_1", "sample_2"])
puts "Moderation complete: #{results}"
```

## Rails Integration

### Controller Integration

```ruby
class Admin::SamplesController < ApplicationController
  before_action :authenticate_admin!

  def destroy
    @client = ElevenlabsClient::Client.new
    
    begin
      result = @client.samples.delete_sample(
        voice_id: params[:voice_id],
        sample_id: params[:id]
      )
      
      if result["status"] == "ok"
        flash[:notice] = "Sample deleted successfully"
        redirect_to admin_voice_path(params[:voice_id])
      else
        flash[:alert] = "Failed to delete sample"
        redirect_back(fallback_location: admin_voices_path)
      end
    rescue ElevenlabsClient::NotFoundError
      flash[:alert] = "Sample not found"
      redirect_back(fallback_location: admin_voices_path)
    rescue ElevenlabsClient::AuthenticationError
      flash[:alert] = "Authentication failed"
      redirect_to admin_root_path
    end
  end
end
```

### Background Job Integration

```ruby
class DeleteSampleJob < ApplicationJob
  queue_as :default
  retry_on ElevenlabsClient::RateLimitError, wait: :exponentially_longer

  def perform(voice_id, sample_id, user_id)
    client = ElevenlabsClient::Client.new
    
    result = client.samples.delete_sample(
      voice_id: voice_id,
      sample_id: sample_id
    )
    
    if result["status"] == "ok"
      # Log successful deletion
      AuditLog.create!(
        user_id: user_id,
        action: "sample_deleted",
        resource_type: "VoiceSample",
        resource_id: sample_id,
        metadata: { voice_id: voice_id }
      )
      
      # Notify user of successful deletion
      SampleDeletionMailer.success(user_id, voice_id, sample_id).deliver_now
    else
      # Handle unexpected response
      Rails.logger.error "Unexpected sample deletion response: #{result}"
      SampleDeletionMailer.failure(user_id, voice_id, sample_id, "Unexpected response").deliver_now
    end
  rescue ElevenlabsClient::NotFoundError
    # Sample or voice not found
    SampleDeletionMailer.failure(user_id, voice_id, sample_id, "Sample not found").deliver_now
  rescue ElevenlabsClient::APIError => e
    # API error occurred
    Rails.logger.error "Sample deletion API error: #{e.message}"
    SampleDeletionMailer.failure(user_id, voice_id, sample_id, e.message).deliver_now
    raise # Re-raise to trigger job retry
  end
end

# Usage
DeleteSampleJob.perform_later("voice_id", "sample_id", current_user.id)
```

### API Endpoint

```ruby
class Api::V1::Admin::SamplesController < Api::V1::BaseController
  before_action :authenticate_admin_api!

  def destroy
    begin
      result = elevenlabs_client.samples.delete_sample(
        voice_id: params[:voice_id],
        sample_id: params[:id]
      )
      
      render json: {
        success: true,
        message: "Sample deleted successfully",
        data: result
      }, status: :ok
    rescue ElevenlabsClient::NotFoundError
      render json: {
        success: false,
        error: "Sample not found"
      }, status: :not_found
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: {
        success: false,
        error: "Invalid parameters",
        details: e.message
      }, status: :unprocessable_entity
    rescue ElevenlabsClient::AuthenticationError
      render json: {
        success: false,
        error: "Authentication failed"
      }, status: :unauthorized
    rescue ElevenlabsClient::RateLimitError
      render json: {
        success: false,
        error: "Rate limit exceeded"
      }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: {
        success: false,
        error: "Service error",
        details: e.message
      }, status: :service_unavailable
    end
  end

  private

  def elevenlabs_client
    @elevenlabs_client ||= ElevenlabsClient::Client.new
  end
end
```

## Best Practices

### 1. Error Handling

Always implement comprehensive error handling for sample deletion operations:

```ruby
def delete_sample_safely(voice_id, sample_id)
  begin
    result = client.samples.delete_sample(
      voice_id: voice_id,
      sample_id: sample_id
    )
    
    { success: true, data: result }
  rescue ElevenlabsClient::NotFoundError
    { success: false, error: "Sample not found", retryable: false }
  rescue ElevenlabsClient::RateLimitError
    { success: false, error: "Rate limit exceeded", retryable: true }
  rescue ElevenlabsClient::APIError => e
    { success: false, error: e.message, retryable: true }
  end
end
```

### 2. Rate Limit Management

Implement proper rate limiting and retry logic:

```ruby
def delete_with_retry(voice_id, sample_id, max_retries: 3)
  retries = 0
  
  begin
    client.samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
  rescue ElevenlabsClient::RateLimitError => e
    retries += 1
    if retries <= max_retries
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise e
    end
  end
end
```

### 3. Logging and Auditing

Maintain detailed logs for all sample deletion operations:

```ruby
def delete_sample_with_audit(voice_id, sample_id, user_id, reason)
  begin
    result = client.samples.delete_sample(
      voice_id: voice_id,
      sample_id: sample_id
    )
    
    # Log successful deletion
    Rails.logger.info "Sample deleted: voice=#{voice_id} sample=#{sample_id} user=#{user_id} reason=#{reason}"
    
    # Create audit record
    create_audit_record(voice_id, sample_id, user_id, reason, "success")
    
    result
  rescue ElevenlabsClient::APIError => e
    # Log failed deletion
    Rails.logger.error "Sample deletion failed: voice=#{voice_id} sample=#{sample_id} error=#{e.message}"
    
    # Create audit record
    create_audit_record(voice_id, sample_id, user_id, reason, "failed", e.message)
    
    raise e
  end
end
```

### 4. Batch Operations

For multiple deletions, implement proper batching and error handling:

```ruby
def delete_samples_batch(voice_id, sample_ids, batch_size: 5)
  results = { success: [], failed: [] }
  
  sample_ids.each_slice(batch_size) do |batch|
    batch.each do |sample_id|
      begin
        result = client.samples.delete_sample(
          voice_id: voice_id,
          sample_id: sample_id
        )
        results[:success] << sample_id
      rescue ElevenlabsClient::APIError => e
        results[:failed] << { sample_id: sample_id, error: e.message }
      end
      
      # Rate limiting pause between requests
      sleep(0.1)
    end
    
    # Longer pause between batches
    sleep(1) unless batch == sample_ids.last(batch_size)
  end
  
  results
end
```

### 5. Validation

Always validate parameters before making API calls:

```ruby
def validate_and_delete_sample(voice_id, sample_id)
  # Validate parameters
  raise ArgumentError, "Voice ID cannot be blank" if voice_id.blank?
  raise ArgumentError, "Sample ID cannot be blank" if sample_id.blank?
  raise ArgumentError, "Invalid voice ID format" unless valid_voice_id?(voice_id)
  raise ArgumentError, "Invalid sample ID format" unless valid_sample_id?(sample_id)
  
  # Perform deletion
  client.samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
end

private

def valid_voice_id?(voice_id)
  voice_id.match?(/\A[a-zA-Z0-9]{20}\z/)
end

def valid_sample_id?(sample_id)
  sample_id.match?(/\A[a-zA-Z0-9_-]+\z/)
end
```

### 6. Configuration Management

Use environment-specific configurations:

```ruby
class SamplesService
  def initialize
    @client = ElevenlabsClient::Client.new(
      api_key: Rails.application.credentials.elevenlabs_api_key,
      base_url: Rails.application.config.elevenlabs_base_url
    )
  end

  def delete_sample(voice_id, sample_id)
    # Add request timeout for production
    Timeout::timeout(30) do
      @client.samples.delete_sample(
        voice_id: voice_id,
        sample_id: sample_id
      )
    end
  rescue Timeout::Error
    raise ElevenlabsClient::APIError, "Request timeout"
  end
end
```

These best practices ensure reliable, maintainable, and secure integration of the Admin Samples API into your application.
