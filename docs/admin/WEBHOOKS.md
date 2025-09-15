# Admin Webhooks API

The Admin Webhooks API provides functionality for managing and monitoring workspace webhooks within the ElevenLabs platform. This endpoint allows administrators to retrieve comprehensive information about all configured webhooks, their status, usage, and failure history.

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

The Webhooks API is designed for administrative oversight and management of webhook configurations within your workspace. It provides detailed information about webhook endpoints, their authentication methods, usage patterns, and failure history.

### Key Features

- **Complete Webhook Listing**: Retrieve all webhooks configured in your workspace
- **Status Monitoring**: Track enabled, disabled, and auto-disabled webhook states
- **Usage Analytics**: Monitor webhook usage across different services
- **Failure Tracking**: Access recent failure information and error codes
- **Authentication Auditing**: Review authentication methods used by webhooks

### Use Cases

- **Webhook Health Monitoring**: Track webhook availability and failure rates
- **Integration Management**: Monitor which services are using webhooks
- **Security Auditing**: Review webhook authentication configurations
- **Troubleshooting**: Identify and diagnose webhook failures
- **Compliance Reporting**: Generate reports on webhook usage and status

## Authentication

All Admin Webhooks API requests require authentication using your ElevenLabs API key:

```ruby
client = ElevenlabsClient::Client.new(api_key: "your_api_key_here")
webhooks = client.webhooks
```

## Available Methods

The Webhooks endpoint provides the following methods:

| Method | Description | Aliases |
|--------|-------------|---------|
| `list_webhooks` | Retrieve all workspace webhooks | `get_webhooks`, `all`, `webhooks` |

## Method Details

### list_webhooks

Retrieves all webhooks configured in the workspace with their status, usage, and failure information.

```ruby
result = client.webhooks.list_webhooks(include_usages: true)
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `include_usages` | Boolean | No | Whether to include active usages of the webhook. Defaults to false. Only usable by admins. |

#### Returns

Returns a hash containing all webhooks and their details:

```ruby
{
  "webhooks" => [
    {
      "name" => "My Webhook",
      "webhook_id" => "webhook_123",
      "webhook_url" => "https://example.com/webhook",
      "is_disabled" => false,
      "is_auto_disabled" => false,
      "created_at_unix" => 1609459200,
      "auth_type" => "hmac",
      "usage" => [
        {
          "usage_type" => "ConvAI Settings"
        }
      ],
      "most_recent_failure_error_code" => 404,
      "most_recent_failure_timestamp" => 1609459799
    }
  ]
}
```

#### Example

```ruby
# Get all webhooks without usage details
result = client.webhooks.list_webhooks
puts "Total webhooks: #{result['webhooks'].length}"

# Get all webhooks with detailed usage information
result = client.webhooks.list_webhooks(include_usages: true)

result['webhooks'].each do |webhook|
  puts "Webhook: #{webhook['name']}"
  puts "  Status: #{webhook['is_disabled'] ? 'Disabled' : 'Active'}"
  puts "  Auth Type: #{webhook['auth_type']}"
  puts "  Usage Types: #{webhook['usage'].map { |u| u['usage_type'] }.join(', ')}"
  
  if webhook['most_recent_failure_error_code']
    puts "  Recent Failure: HTTP #{webhook['most_recent_failure_error_code']}"
  end
end
```

## Response Structures

### Webhooks Response

```ruby
{
  "webhooks" => [
    {
      "name" => "string",
      "webhook_id" => "string",
      "webhook_url" => "string",
      "is_disabled" => boolean,
      "is_auto_disabled" => boolean,
      "created_at_unix" => integer,
      "auth_type" => "string",
      "usage" => [
        {
          "usage_type" => "string"
        }
      ],
      "most_recent_failure_error_code" => integer,
      "most_recent_failure_timestamp" => integer
    }
  ]
}
```

**Webhook Fields:**
- `name` (String): Human-readable name of the webhook
- `webhook_id` (String): Unique identifier for the webhook
- `webhook_url` (String): The endpoint URL where webhook events are sent
- `is_disabled` (Boolean): Whether the webhook is manually disabled
- `is_auto_disabled` (Boolean): Whether the webhook was automatically disabled due to failures
- `created_at_unix` (Integer): Unix timestamp when the webhook was created
- `auth_type` (String): Authentication method used ("hmac", "bearer", "none")
- `usage` (Array): List of services or features using this webhook
- `most_recent_failure_error_code` (Integer): HTTP status code of the most recent failure (null if no failures)
- `most_recent_failure_timestamp` (Integer): Unix timestamp of the most recent failure (null if no failures)

**Usage Object Fields:**
- `usage_type` (String): Type of service using the webhook (e.g., "ConvAI Settings")

### Empty Response

When no webhooks are configured:

```ruby
{
  "webhooks" => []
}
```

## Error Handling

The Webhooks API handles various error scenarios with specific exception types:

### Common Errors

#### AuthenticationError (401)
Raised when the API key is invalid or missing:

```ruby
begin
  invalid_client = ElevenlabsClient::Client.new(api_key: "invalid_key")
  invalid_client.webhooks.list_webhooks
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

#### UnprocessableEntityError (422)
Raised when the request parameters are invalid:

```ruby
begin
  client.webhooks.list_webhooks(include_usages: "invalid_value")
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid request: #{e.message}"
end
```

#### RateLimitError (429)
Raised when the rate limit is exceeded:

```ruby
begin
  client.webhooks.list_webhooks
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
  # Implement retry logic with exponential backoff
end
```

#### APIError (500)
Raised when there's a server error:

```ruby
begin
  client.webhooks.list_webhooks
rescue ElevenlabsClient::APIError => e
  puts "Server error: #{e.message}"
end
```

## Usage Examples

### Basic Webhook Retrieval

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

# Get all webhooks
begin
  result = client.webhooks.list_webhooks
  
  webhooks = result["webhooks"]
  puts "Found #{webhooks.length} webhooks"
  
  webhooks.each do |webhook|
    status = if webhook['is_auto_disabled']
               'Auto-disabled'
             elsif webhook['is_disabled']
               'Disabled'
             else
               'Active'
             end
    
    puts "\nWebhook: #{webhook['name']}"
    puts "  ID: #{webhook['webhook_id']}"
    puts "  URL: #{webhook['webhook_url']}"
    puts "  Status: #{status}"
    puts "  Auth Type: #{webhook['auth_type']}"
    puts "  Created: #{Time.at(webhook['created_at_unix'])}"
  end
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

### Detailed Webhook Analysis with Usage Information

```ruby
# Get webhooks with detailed usage information
result = client.webhooks.list_webhooks(include_usages: true)

webhooks = result["webhooks"]

puts "Webhook Analysis Report"
puts "=" * 50

# Overall statistics
active_count = webhooks.count { |w| !w['is_disabled'] && !w['is_auto_disabled'] }
disabled_count = webhooks.count { |w| w['is_disabled'] }
auto_disabled_count = webhooks.count { |w| w['is_auto_disabled'] }
failed_count = webhooks.count { |w| w['most_recent_failure_error_code'] }

puts "Total Webhooks: #{webhooks.length}"
puts "Active: #{active_count}"
puts "Manually Disabled: #{disabled_count}"
puts "Auto-disabled: #{auto_disabled_count}"
puts "With Recent Failures: #{failed_count}"
puts

# Authentication method distribution
auth_types = webhooks.group_by { |w| w['auth_type'] }.transform_values(&:count)
puts "Authentication Methods:"
auth_types.each { |type, count| puts "  #{type}: #{count}" }
puts

# Usage type distribution
usage_types = webhooks.flat_map { |w| w['usage'] || [] }
                     .group_by { |u| u['usage_type'] }
                     .transform_values(&:count)

puts "Usage Types:"
usage_types.each { |type, count| puts "  #{type}: #{count}" }
puts

# Detailed webhook information
webhooks.each do |webhook|
  puts "#{webhook['name']} (#{webhook['webhook_id']})"
  puts "  URL: #{webhook['webhook_url']}"
  puts "  Status: #{webhook['is_disabled'] ? 'Disabled' : 'Active'}"
  puts "  Auto-disabled: #{webhook['is_auto_disabled']}"
  puts "  Auth: #{webhook['auth_type']}"
  
  if webhook['usage'] && !webhook['usage'].empty?
    puts "  Used by: #{webhook['usage'].map { |u| u['usage_type'] }.join(', ')}"
  end
  
  if webhook['most_recent_failure_error_code']
    failure_time = Time.at(webhook['most_recent_failure_timestamp'])
    puts "  Recent failure: HTTP #{webhook['most_recent_failure_error_code']} at #{failure_time}"
  end
  
  puts
end
```

### Webhook Health Monitoring

```ruby
# Monitor webhook health and identify issues
result = client.webhooks.list_webhooks(include_usages: true)
webhooks = result["webhooks"]

health_issues = []
recommendations = []

webhooks.each do |webhook|
  webhook_name = webhook['name']
  
  # Check for auto-disabled webhooks
  if webhook['is_auto_disabled']
    health_issues << {
      severity: 'critical',
      webhook: webhook_name,
      issue: 'Webhook is auto-disabled due to repeated failures'
    }
    recommendations << "Investigate and fix webhook: #{webhook_name}"
  end
  
  # Check for recent failures
  if webhook['most_recent_failure_error_code'] && !webhook['is_auto_disabled']
    error_code = webhook['most_recent_failure_error_code']
    failure_time = Time.at(webhook['most_recent_failure_timestamp'])
    
    health_issues << {
      severity: 'warning',
      webhook: webhook_name,
      issue: "Recent failure: HTTP #{error_code} at #{failure_time}"
    }
    
    case error_code
    when 404
      recommendations << "Check if webhook URL is correct: #{webhook_name}"
    when 401, 403
      recommendations << "Verify webhook authentication: #{webhook_name}"
    when 500..599
      recommendations << "Check webhook endpoint server: #{webhook_name}"
    else
      recommendations << "Investigate webhook failure: #{webhook_name} (HTTP #{error_code})"
    end
  end
  
  # Check for unused webhooks
  if webhook['usage'].empty? && !webhook['is_disabled']
    webhook_age_days = (Time.current.to_i - webhook['created_at_unix']) / 86400
    if webhook_age_days > 30
      health_issues << {
        severity: 'info',
        webhook: webhook_name,
        issue: "Webhook has no active usage and is #{webhook_age_days} days old"
      }
      recommendations << "Consider removing unused webhook: #{webhook_name}"
    end
  end
end

# Report health issues
if health_issues.any?
  puts "Webhook Health Issues:"
  health_issues.group_by { |issue| issue[:severity] }.each do |severity, issues|
    puts "\n#{severity.upcase}:"
    issues.each { |issue| puts "  - #{issue[:webhook]}: #{issue[:issue]}" }
  end
else
  puts "✅ All webhooks are healthy!"
end

# Show recommendations
if recommendations.any?
  puts "\nRecommendations:"
  recommendations.each { |rec| puts "  - #{rec}" }
end
```

### Webhook Security Audit

```ruby
# Perform security audit of webhook configurations
result = client.webhooks.list_webhooks(include_usages: true)
webhooks = result["webhooks"]

security_findings = []

webhooks.each do |webhook|
  webhook_name = webhook['name']
  webhook_url = webhook['webhook_url']
  auth_type = webhook['auth_type']
  
  # Check for insecure authentication
  if auth_type == 'none'
    security_findings << {
      severity: 'high',
      webhook: webhook_name,
      finding: 'Webhook uses no authentication',
      recommendation: 'Enable HMAC or Bearer token authentication'
    }
  end
  
  # Check for non-HTTPS URLs
  unless webhook_url.start_with?('https://')
    security_findings << {
      severity: 'critical',
      webhook: webhook_name,
      finding: 'Webhook uses insecure HTTP protocol',
      recommendation: 'Use HTTPS for webhook URL'
    }
  end
  
  # Check for localhost or private IP addresses in production
  if webhook_url.match?(/localhost|127\.0\.0\.1|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\./)
    security_findings << {
      severity: 'medium',
      webhook: webhook_name,
      finding: 'Webhook points to local/private network',
      recommendation: 'Ensure this is intentional for development/testing'
    }
  end
end

# Report security findings
if security_findings.any?
  puts "Webhook Security Audit Results:"
  security_findings.group_by { |finding| finding[:severity] }.each do |severity, findings|
    puts "\n#{severity.upcase} SECURITY ISSUES:"
    findings.each do |finding|
      puts "  Webhook: #{finding[:webhook]}"
      puts "    Issue: #{finding[:finding]}"
      puts "    Recommendation: #{finding[:recommendation]}"
      puts
    end
  end
else
  puts "✅ No security issues found in webhook configurations!"
end

# Summary statistics
puts "Security Summary:"
puts "  Total webhooks: #{webhooks.length}"
puts "  HTTPS webhooks: #{webhooks.count { |w| w['webhook_url'].start_with?('https://') }}"
puts "  Authenticated webhooks: #{webhooks.count { |w| w['auth_type'] != 'none' }}"

auth_distribution = webhooks.group_by { |w| w['auth_type'] }.transform_values(&:count)
puts "  Authentication methods: #{auth_distribution}"
```

### Using Aliases

```ruby
# All these methods do the same thing
client.webhooks.list_webhooks
client.webhooks.get_webhooks
client.webhooks.all
client.webhooks.webhooks

# With parameters
client.webhooks.list_webhooks(include_usages: true)
client.webhooks.get_webhooks(include_usages: true)
client.webhooks.all(include_usages: true)
client.webhooks.webhooks(include_usages: true)
```

### Webhook Monitoring Service

```ruby
class WebhookMonitoringService
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
  end

  def generate_monitoring_report
    result = @client.webhooks.list_webhooks(include_usages: true)
    webhooks = result["webhooks"]
    
    report = {
      timestamp: Time.current.iso8601,
      summary: generate_summary(webhooks),
      health_status: analyze_health(webhooks),
      security_status: analyze_security(webhooks),
      recommendations: generate_recommendations(webhooks)
    }
    
    report
  end

  def check_webhook_health
    result = @client.webhooks.list_webhooks
    webhooks = result["webhooks"]
    
    critical_issues = []
    warning_issues = []
    
    webhooks.each do |webhook|
      if webhook['is_auto_disabled']
        critical_issues << {
          webhook: webhook['name'],
          issue: 'Auto-disabled due to failures',
          url: webhook['webhook_url']
        }
      elsif webhook['most_recent_failure_error_code']
        warning_issues << {
          webhook: webhook['name'],
          issue: "HTTP #{webhook['most_recent_failure_error_code']} failure",
          url: webhook['webhook_url'],
          timestamp: webhook['most_recent_failure_timestamp']
        }
      end
    end
    
    {
      status: critical_issues.any? ? 'critical' : warning_issues.any? ? 'warning' : 'healthy',
      critical_issues: critical_issues,
      warning_issues: warning_issues,
      total_webhooks: webhooks.length,
      healthy_webhooks: webhooks.count { |w| !w['is_disabled'] && !w['is_auto_disabled'] && !w['most_recent_failure_error_code'] }
    }
  end

  private

  def generate_summary(webhooks)
    {
      total_webhooks: webhooks.length,
      active_webhooks: webhooks.count { |w| !w['is_disabled'] && !w['is_auto_disabled'] },
      disabled_webhooks: webhooks.count { |w| w['is_disabled'] },
      auto_disabled_webhooks: webhooks.count { |w| w['is_auto_disabled'] },
      failed_webhooks: webhooks.count { |w| w['most_recent_failure_error_code'] },
      auth_types: webhooks.group_by { |w| w['auth_type'] }.transform_values(&:count)
    }
  end

  def analyze_health(webhooks)
    healthy = webhooks.count { |w| !w['is_disabled'] && !w['is_auto_disabled'] && !w['most_recent_failure_error_code'] }
    total = webhooks.length
    
    health_percentage = total > 0 ? (healthy.to_f / total * 100).round(2) : 0
    
    status = case health_percentage
             when 90..100 then 'excellent'
             when 70..89 then 'good'
             when 50..69 then 'fair'
             else 'poor'
             end
    
    {
      status: status,
      health_percentage: health_percentage,
      healthy_count: healthy,
      total_count: total
    }
  end

  def analyze_security(webhooks)
    secure_count = webhooks.count do |w|
      w['webhook_url'].start_with?('https://') && w['auth_type'] != 'none'
    end
    
    total = webhooks.length
    security_percentage = total > 0 ? (secure_count.to_f / total * 100).round(2) : 0
    
    {
      security_percentage: security_percentage,
      secure_webhooks: secure_count,
      insecure_webhooks: total - secure_count,
      https_webhooks: webhooks.count { |w| w['webhook_url'].start_with?('https://') },
      authenticated_webhooks: webhooks.count { |w| w['auth_type'] != 'none' }
    }
  end

  def generate_recommendations(webhooks)
    recommendations = []
    
    # Auto-disabled webhooks
    auto_disabled = webhooks.select { |w| w['is_auto_disabled'] }
    if auto_disabled.any?
      recommendations << "Fix and re-enable #{auto_disabled.length} auto-disabled webhooks"
    end
    
    # Insecure webhooks
    insecure_auth = webhooks.select { |w| w['auth_type'] == 'none' }
    if insecure_auth.any?
      recommendations << "Enable authentication for #{insecure_auth.length} webhooks"
    end
    
    # HTTP webhooks
    http_webhooks = webhooks.select { |w| !w['webhook_url'].start_with?('https://') }
    if http_webhooks.any?
      recommendations << "Upgrade #{http_webhooks.length} webhooks to HTTPS"
    end
    
    # Failed webhooks
    failed_webhooks = webhooks.select { |w| w['most_recent_failure_error_code'] && !w['is_auto_disabled'] }
    if failed_webhooks.any?
      recommendations << "Investigate #{failed_webhooks.length} webhooks with recent failures"
    end
    
    recommendations
  end
end

# Usage
monitoring_service = WebhookMonitoringService.new
report = monitoring_service.generate_monitoring_report
health_check = monitoring_service.check_webhook_health

puts "Webhook Monitoring Report"
puts "=" * 50
puts "Health Status: #{health_check[:status].upcase}"
puts "Healthy Webhooks: #{health_check[:healthy_webhooks]}/#{health_check[:total_webhooks]}"

if health_check[:critical_issues].any?
  puts "\nCritical Issues:"
  health_check[:critical_issues].each { |issue| puts "  - #{issue[:webhook]}: #{issue[:issue]}" }
end

if health_check[:warning_issues].any?
  puts "\nWarning Issues:"
  health_check[:warning_issues].each { |issue| puts "  - #{issue[:webhook]}: #{issue[:issue]}" }
end

if report[:recommendations].any?
  puts "\nRecommendations:"
  report[:recommendations].each { |rec| puts "  - #{rec}" }
end
```

## Rails Integration

### Controller Integration

```ruby
class Admin::WebhooksController < ApplicationController
  before_action :authenticate_admin!

  def index
    @client = ElevenlabsClient::Client.new
    
    begin
      result = @client.webhooks.list_webhooks(include_usages: params[:include_usages])
      @webhooks = result["webhooks"]
      @statistics = calculate_statistics(@webhooks)
      
      # Apply filters
      @webhooks = apply_filters(@webhooks)
      
      respond_to do |format|
        format.html
        format.json { render json: { success: true, data: { webhooks: @webhooks, statistics: @statistics } } }
        format.csv { send_data generate_csv(@webhooks), filename: "webhooks_#{Date.current}.csv" }
      end
    rescue ElevenlabsClient::AuthenticationError
      flash[:alert] = "Authentication failed"
      redirect_to admin_root_path
    rescue ElevenlabsClient::APIError => e
      flash[:alert] = "Service temporarily unavailable: #{e.message}"
      @webhooks = []
      @statistics = default_statistics
    end
  end

  def health_check
    @client = ElevenlabsClient::Client.new
    
    begin
      result = @client.webhooks.list_webhooks(include_usages: true)
      webhooks = result["webhooks"]
      
      @health_report = generate_health_report(webhooks)
      
      respond_to do |format|
        format.json { render json: { success: true, health_report: @health_report } }
        format.html
      end
    rescue ElevenlabsClient::APIError => e
      respond_to do |format|
        format.json { render json: { success: false, error: e.message } }
        format.html do
          flash[:alert] = "Health check failed: #{e.message}"
          redirect_to admin_webhooks_path
        end
      end
    end
  end

  private

  def apply_filters(webhooks)
    filtered = webhooks.dup
    
    if params[:status].present?
      filtered = case params[:status].downcase
                when 'active'
                  filtered.select { |w| !w["is_disabled"] && !w["is_auto_disabled"] }
                when 'disabled'
                  filtered.select { |w| w["is_disabled"] }
                when 'auto_disabled'
                  filtered.select { |w| w["is_auto_disabled"] }
                when 'failed'
                  filtered.select { |w| w["most_recent_failure_error_code"] }
                else
                  filtered
                end
    end
    
    if params[:auth_type].present?
      filtered = filtered.select { |w| w["auth_type"] == params[:auth_type] }
    end
    
    filtered
  end

  def calculate_statistics(webhooks)
    return default_statistics if webhooks.empty?

    {
      total_webhooks: webhooks.count,
      active_webhooks: webhooks.count { |w| !w["is_disabled"] && !w["is_auto_disabled"] },
      disabled_webhooks: webhooks.count { |w| w["is_disabled"] },
      auto_disabled_webhooks: webhooks.count { |w| w["is_auto_disabled"] },
      failed_webhooks: webhooks.count { |w| w["most_recent_failure_error_code"] },
      auth_types: webhooks.group_by { |w| w["auth_type"] }.transform_values(&:count)
    }
  end

  def generate_health_report(webhooks)
    # Implementation similar to the WebhookMonitoringService example above
  end

  def generate_csv(webhooks)
    CSV.generate do |csv|
      csv << ["Name", "Webhook ID", "URL", "Status", "Auth Type", "Usage Types", "Created At", "Recent Failure", "Failure Time"]
      
      webhooks.each do |webhook|
        status = if webhook["is_auto_disabled"]
                  "Auto Disabled"
                elsif webhook["is_disabled"]
                  "Disabled"
                else
                  "Active"
                end
        
        usage_types = webhook["usage"]&.map { |u| u["usage_type"] }&.join("; ") || ""
        failure_time = webhook["most_recent_failure_timestamp"] ? 
          Time.at(webhook["most_recent_failure_timestamp"]).strftime("%Y-%m-%d %H:%M:%S") : ""
        
        csv << [
          webhook["name"],
          webhook["webhook_id"],
          webhook["webhook_url"],
          status,
          webhook["auth_type"],
          usage_types,
          Time.at(webhook["created_at_unix"]).strftime("%Y-%m-%d %H:%M:%S"),
          webhook["most_recent_failure_error_code"],
          failure_time
        ]
      end
    end
  end

  def default_statistics
    {
      total_webhooks: 0,
      active_webhooks: 0,
      disabled_webhooks: 0,
      auto_disabled_webhooks: 0,
      failed_webhooks: 0,
      auth_types: {}
    }
  end
end
```

### Background Job Integration

```ruby
class WebhookHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    client = ElevenlabsClient::Client.new
    
    result = client.webhooks.list_webhooks(include_usages: true)
    webhooks = result["webhooks"]
    
    # Analyze webhook health
    health_report = analyze_webhook_health(webhooks)
    
    # Store health check results
    WebhookHealthCheck.create!(
      check_date: Date.current,
      total_webhooks: health_report[:total_webhooks],
      healthy_webhooks: health_report[:healthy_webhooks],
      failed_webhooks: health_report[:failed_webhooks],
      auto_disabled_webhooks: health_report[:auto_disabled_webhooks],
      health_score: health_report[:health_score],
      raw_data: webhooks
    )
    
    # Send alerts if there are critical issues
    if health_report[:critical_issues].any?
      WebhookAlertMailer.critical_issues(health_report[:critical_issues]).deliver_now
    end
    
    # Send warnings for failed webhooks
    if health_report[:warning_issues].any?
      WebhookAlertMailer.warning_issues(health_report[:warning_issues]).deliver_now
    end
  rescue ElevenlabsClient::APIError => e
    Rails.logger.error "Webhook health check failed: #{e.message}"
    raise # Re-raise to trigger job retry
  end

  private

  def analyze_webhook_health(webhooks)
    # Implementation details...
  end
end

# Schedule the job to run every hour
# In config/schedule.rb (using whenever gem):
# every 1.hour do
#   runner "WebhookHealthCheckJob.perform_later"
# end
```

### API Endpoint

```ruby
class Api::V1::Admin::WebhooksController < Api::V1::BaseController
  before_action :authenticate_admin_api!

  def index
    begin
      include_usages = params[:include_usages] == 'true'
      result = elevenlabs_client.webhooks.list_webhooks(include_usages: include_usages)
      
      render json: {
        success: true,
        data: result,
        statistics: calculate_statistics(result["webhooks"]),
        timestamp: Time.current.iso8601
      }, status: :ok
    rescue ElevenlabsClient::AuthenticationError
      render json: {
        success: false,
        error: "Authentication failed"
      }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: {
        success: false,
        error: "Invalid request",
        details: e.message
      }, status: :unprocessable_entity
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

  def health_check
    begin
      result = elevenlabs_client.webhooks.list_webhooks(include_usages: true)
      health_report = generate_health_report(result["webhooks"])
      
      render json: {
        success: true,
        health_report: health_report,
        timestamp: Time.current.iso8601
      }, status: :ok
    rescue ElevenlabsClient::APIError => e
      render json: {
        success: false,
        error: "Health check failed",
        details: e.message
      }, status: :service_unavailable
    end
  end

  private

  def elevenlabs_client
    @elevenlabs_client ||= ElevenlabsClient::Client.new
  end

  def calculate_statistics(webhooks)
    # Implementation details...
  end

  def generate_health_report(webhooks)
    # Implementation details...
  end
end
```

## Best Practices

### 1. Caching and Performance

Cache webhook data to reduce API calls and improve performance:

```ruby
class WebhookService
  def self.get_cached_webhooks(include_usages: false)
    cache_key = "webhooks_#{include_usages ? 'with_usage' : 'basic'}"
    
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      client = ElevenlabsClient::Client.new
      result = client.webhooks.list_webhooks(include_usages: include_usages)
      result["webhooks"]
    end
  end

  def self.invalidate_cache
    Rails.cache.delete("webhooks_basic")
    Rails.cache.delete("webhooks_with_usage")
  end
end
```

### 2. Error Handling and Retry Logic

Implement robust error handling with retry mechanisms:

```ruby
def get_webhooks_with_retry(max_retries: 3, include_usages: false)
  retries = 0
  
  begin
    client.webhooks.list_webhooks(include_usages: include_usages)
  rescue ElevenlabsClient::RateLimitError => e
    retries += 1
    if retries <= max_retries
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise e
    end
  rescue ElevenlabsClient::APIError => e
    retries += 1
    if retries <= max_retries && e.message.include?("timeout")
      sleep(1)
      retry
    else
      raise e
    end
  end
end
```

### 3. Health Monitoring and Alerting

Set up continuous health monitoring for webhooks:

```ruby
class WebhookHealthMonitor
  def self.check_and_alert
    client = ElevenlabsClient::Client.new
    result = client.webhooks.list_webhooks
    
    critical_alerts = []
    warning_alerts = []
    
    result["webhooks"].each do |webhook|
      if webhook["is_auto_disabled"]
        critical_alerts << {
          type: "auto_disabled",
          webhook: webhook["name"],
          message: "Webhook #{webhook['name']} is auto-disabled"
        }
      elsif webhook["most_recent_failure_error_code"]
        warning_alerts << {
          type: "recent_failure",
          webhook: webhook["name"],
          message: "Webhook #{webhook['name']} has recent failure: HTTP #{webhook['most_recent_failure_error_code']}"
        }
      end
    end
    
    # Send alerts
    if critical_alerts.any?
      AlertService.send_critical_webhook_alerts(critical_alerts)
    end
    
    if warning_alerts.any?
      AlertService.send_warning_webhook_alerts(warning_alerts)
    end
    
    {
      status: critical_alerts.any? ? 'critical' : warning_alerts.any? ? 'warning' : 'healthy',
      critical_count: critical_alerts.count,
      warning_count: warning_alerts.count
    }
  end
end
```

### 4. Data Analysis and Reporting

Analyze webhook data for insights and reporting:

```ruby
class WebhookAnalyzer
  def initialize(webhooks_data)
    @webhooks = webhooks_data
  end

  def generate_comprehensive_report
    {
      summary: generate_summary,
      health_analysis: analyze_health,
      security_analysis: analyze_security,
      usage_analysis: analyze_usage,
      failure_analysis: analyze_failures,
      recommendations: generate_recommendations
    }
  end

  private

  def generate_summary
    {
      total_webhooks: @webhooks.length,
      active_webhooks: @webhooks.count { |w| !w["is_disabled"] && !w["is_auto_disabled"] },
      disabled_webhooks: @webhooks.count { |w| w["is_disabled"] },
      auto_disabled_webhooks: @webhooks.count { |w| w["is_auto_disabled"] },
      webhooks_with_failures: @webhooks.count { |w| w["most_recent_failure_error_code"] }
    }
  end

  def analyze_health
    total = @webhooks.length
    return { status: 'no_data', health_score: 0 } if total == 0

    healthy = @webhooks.count { |w| !w["is_disabled"] && !w["is_auto_disabled"] && !w["most_recent_failure_error_code"] }
    health_score = (healthy.to_f / total * 100).round(2)
    
    status = case health_score
             when 95..100 then 'excellent'
             when 85..94 then 'good'
             when 70..84 then 'fair'
             when 50..69 then 'poor'
             else 'critical'
             end

    {
      status: status,
      health_score: health_score,
      healthy_count: healthy,
      total_count: total
    }
  end

  def analyze_security
    total = @webhooks.length
    return { security_score: 0, issues: [] } if total == 0

    security_issues = []
    secure_count = 0

    @webhooks.each do |webhook|
      is_secure = true
      
      # Check HTTPS
      unless webhook["webhook_url"].start_with?('https://')
        security_issues << {
          webhook: webhook["name"],
          issue: "Uses HTTP instead of HTTPS",
          severity: "high"
        }
        is_secure = false
      end
      
      # Check authentication
      if webhook["auth_type"] == "none"
        security_issues << {
          webhook: webhook["name"],
          issue: "No authentication configured",
          severity: "medium"
        }
        is_secure = false
      end
      
      secure_count += 1 if is_secure
    end

    security_score = (secure_count.to_f / total * 100).round(2)

    {
      security_score: security_score,
      secure_webhooks: secure_count,
      total_webhooks: total,
      issues: security_issues
    }
  end

  def analyze_usage
    usage_distribution = @webhooks.flat_map { |w| w["usage"] || [] }
                                 .group_by { |u| u["usage_type"] }
                                 .transform_values(&:count)
    
    unused_webhooks = @webhooks.select { |w| w["usage"].empty? }
    
    {
      usage_distribution: usage_distribution,
      unused_webhooks_count: unused_webhooks.count,
      unused_webhooks: unused_webhooks.map { |w| { name: w["name"], id: w["webhook_id"] } }
    }
  end

  def analyze_failures
    failed_webhooks = @webhooks.select { |w| w["most_recent_failure_error_code"] }
    
    failure_codes = failed_webhooks.group_by { |w| w["most_recent_failure_error_code"] }
                                  .transform_values(&:count)
    
    recent_failures = failed_webhooks.select do |w|
      w["most_recent_failure_timestamp"] && 
      Time.at(w["most_recent_failure_timestamp"]) > 24.hours.ago
    end

    {
      total_failed_webhooks: failed_webhooks.count,
      failure_codes_distribution: failure_codes,
      recent_failures_count: recent_failures.count,
      failure_rate: @webhooks.length > 0 ? (failed_webhooks.count.to_f / @webhooks.length * 100).round(2) : 0
    }
  end

  def generate_recommendations
    recommendations = []
    
    # Auto-disabled webhooks
    auto_disabled = @webhooks.select { |w| w["is_auto_disabled"] }
    if auto_disabled.any?
      recommendations << {
        priority: "high",
        action: "Fix and re-enable auto-disabled webhooks",
        count: auto_disabled.length,
        webhooks: auto_disabled.map { |w| w["name"] }
      }
    end
    
    # Security improvements
    insecure = @webhooks.select { |w| !w["webhook_url"].start_with?('https://') || w["auth_type"] == "none" }
    if insecure.any?
      recommendations << {
        priority: "medium",
        action: "Improve webhook security (HTTPS + authentication)",
        count: insecure.length,
        webhooks: insecure.map { |w| w["name"] }
      }
    end
    
    # Unused webhooks cleanup
    unused = @webhooks.select { |w| w["usage"].empty? && !w["is_disabled"] }
    if unused.any?
      recommendations << {
        priority: "low",
        action: "Review and possibly remove unused webhooks",
        count: unused.length,
        webhooks: unused.map { |w| w["name"] }
      }
    end
    
    recommendations
  end
end
```

### 5. Configuration Management

Use environment-specific configurations and validation:

```ruby
class WebhookConfiguration
  def self.validate_webhook_health
    client = ElevenlabsClient::Client.new
    
    begin
      result = client.webhooks.list_webhooks
      webhooks = result["webhooks"]
      
      validation_results = {
        total_webhooks: webhooks.length,
        validations: []
      }
      
      webhooks.each do |webhook|
        webhook_validation = validate_single_webhook(webhook)
        validation_results[:validations] << webhook_validation
      end
      
      validation_results
    rescue ElevenlabsClient::APIError => e
      { error: "Failed to retrieve webhooks: #{e.message}" }
    end
  end

  def self.validate_single_webhook(webhook)
    issues = []
    
    # Validate URL format
    begin
      uri = URI.parse(webhook["webhook_url"])
      issues << "Invalid URL format" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      issues << "Should use HTTPS" if uri.scheme == 'http'
    rescue URI::InvalidURIError
      issues << "Malformed URL"
    end
    
    # Validate authentication
    issues << "No authentication configured" if webhook["auth_type"] == "none"
    
    # Check status
    issues << "Webhook is auto-disabled" if webhook["is_auto_disabled"]
    issues << "Recent failure detected" if webhook["most_recent_failure_error_code"]
    
    {
      webhook_name: webhook["name"],
      webhook_id: webhook["webhook_id"],
      status: issues.empty? ? "valid" : "issues_found",
      issues: issues
    }
  end
end
```

These best practices ensure reliable, secure, and maintainable integration of the Admin Webhooks API into your application, providing comprehensive monitoring and management capabilities for your webhook infrastructure.
