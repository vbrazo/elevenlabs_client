# Admin Service Accounts API

The Admin Service Accounts API provides functionality for managing and monitoring service accounts within your ElevenLabs workspace. This endpoint allows administrators to retrieve comprehensive information about all service accounts, their associated API keys, permissions, and usage metrics.

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

The Service Accounts API is designed for administrative oversight and management of service accounts within your workspace. It provides detailed information about each service account, including their API keys, permissions, usage statistics, and security status.

### Key Features

- **Complete Service Account Listing**: Retrieve all service accounts in your workspace
- **API Key Management**: View all API keys associated with each service account
- **Permission Auditing**: Monitor permissions granted to each API key
- **Usage Monitoring**: Track character usage and limits for each API key
- **Security Status**: Check enabled/disabled status of API keys

### Use Cases

- **Security Auditing**: Monitor service account permissions and API key status
- **Usage Analytics**: Track character consumption across service accounts
- **Access Management**: Review and audit service account access patterns
- **Compliance Reporting**: Generate reports on service account usage and permissions
- **Cost Management**: Monitor usage against character limits and budgets

## Authentication

All Admin Service Accounts API requests require authentication using your ElevenLabs API key:

```ruby
client = ElevenlabsClient::Client.new(api_key: "your_api_key_here")
service_accounts = client.service_accounts
```

## Available Methods

The Service Accounts endpoint provides the following methods:

| Method | Description | Aliases |
|--------|-------------|---------|
| `get_service_accounts` | Retrieve all service accounts in the workspace | `list`, `all`, `service_accounts` |

## Method Details

### get_service_accounts

Retrieves all service accounts in the workspace with their associated API keys and usage information.

```ruby
result = client.service_accounts.get_service_accounts
```

#### Parameters

This method takes no parameters.

#### Returns

Returns a hash containing all service accounts and their details:

```ruby
{
  "service-accounts" => [
    {
      "service_account_user_id" => "sa_abc123",
      "name" => "Production Service Account",
      "api-keys" => [
        {
          "name" => "Production API Key",
          "hint" => "sk_abc...xyz",
          "key_id" => "key_123",
          "service_account_user_id" => "sa_abc123",
          "created_at_unix" => 1609459200,
          "is_disabled" => false,
          "permissions" => ["text_to_speech", "speech_to_text"],
          "character_limit" => 50000,
          "character_count" => 12500
        }
      ],
      "created_at_unix" => 1609459200
    }
  ]
}
```

#### Example

```ruby
# Get all service accounts
result = client.service_accounts.get_service_accounts

puts "Total service accounts: #{result['service-accounts'].length}"

result['service-accounts'].each do |account|
  puts "Account: #{account['name']} (#{account['service_account_user_id']})"
  puts "  API Keys: #{account['api-keys'].length}"
  
  account['api-keys'].each do |api_key|
    status = api_key['is_disabled'] ? 'Disabled' : 'Active'
    usage = "#{api_key['character_count']}/#{api_key['character_limit']}"
    puts "    #{api_key['name']}: #{status} - Usage: #{usage}"
  end
end
```

## Response Structures

### Service Accounts Response

```ruby
{
  "service-accounts" => [
    {
      "service_account_user_id" => "string",
      "name" => "string", 
      "api-keys" => [
        {
          "name" => "string",
          "hint" => "string",
          "key_id" => "string",
          "service_account_user_id" => "string",
          "created_at_unix" => integer,
          "is_disabled" => boolean,
          "permissions" => ["string"],
          "character_limit" => integer,
          "character_count" => integer
        }
      ],
      "created_at_unix" => integer
    }
  ]
}
```

**Service Account Fields:**
- `service_account_user_id` (String): Unique identifier for the service account
- `name` (String): Human-readable name of the service account
- `api-keys` (Array): List of API keys associated with this service account
- `created_at_unix` (Integer): Unix timestamp when the service account was created

**API Key Fields:**
- `name` (String): Name of the API key
- `hint` (String): Partial display of the API key for identification
- `key_id` (String): Unique identifier for the API key
- `service_account_user_id` (String): ID of the associated service account
- `created_at_unix` (Integer): Unix timestamp when the API key was created
- `is_disabled` (Boolean): Whether the API key is currently disabled
- `permissions` (Array): List of permissions granted to this API key
- `character_limit` (Integer): Maximum characters this API key can use
- `character_count` (Integer): Current character usage for this API key

### Empty Response

When no service accounts exist:

```ruby
{
  "service-accounts" => []
}
```

## Error Handling

The Service Accounts API handles various error scenarios with specific exception types:

### Common Errors

#### AuthenticationError (401)
Raised when the API key is invalid or missing:

```ruby
begin
  invalid_client = ElevenlabsClient::Client.new(api_key: "invalid_key")
  invalid_client.service_accounts.get_service_accounts
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

#### UnprocessableEntityError (422)
Raised when the request parameters are invalid:

```ruby
begin
  client.service_accounts.get_service_accounts
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid request: #{e.message}"
end
```

#### RateLimitError (429)
Raised when the rate limit is exceeded:

```ruby
begin
  client.service_accounts.get_service_accounts
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
  # Implement retry logic with exponential backoff
end
```

#### APIError (500)
Raised when there's a server error:

```ruby
begin
  client.service_accounts.get_service_accounts
rescue ElevenlabsClient::APIError => e
  puts "Server error: #{e.message}"
end
```

## Usage Examples

### Basic Service Account Retrieval

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

# Get all service accounts
begin
  result = client.service_accounts.get_service_accounts
  
  service_accounts = result["service-accounts"]
  puts "Found #{service_accounts.length} service accounts"
  
  service_accounts.each do |account|
    puts "\nService Account: #{account['name']}"
    puts "  ID: #{account['service_account_user_id']}"
    puts "  Created: #{Time.at(account['created_at_unix'])}"
    puts "  API Keys: #{account['api-keys'].length}"
  end
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

### Detailed API Key Analysis

```ruby
# Analyze API keys across all service accounts
result = client.service_accounts.get_service_accounts

total_keys = 0
active_keys = 0
total_usage = 0
total_limit = 0

result["service-accounts"].each do |account|
  account["api-keys"].each do |api_key|
    total_keys += 1
    active_keys += 1 unless api_key["is_disabled"]
    total_usage += api_key["character_count"]
    total_limit += api_key["character_limit"]
    
    puts "#{account['name']} - #{api_key['name']}:"
    puts "  Status: #{api_key['is_disabled'] ? 'Disabled' : 'Active'}"
    puts "  Permissions: #{api_key['permissions'].join(', ')}"
    puts "  Usage: #{api_key['character_count']} / #{api_key['character_limit']} characters"
    puts "  Hint: #{api_key['hint']}"
    puts
  end
end

puts "Summary:"
puts "  Total API Keys: #{total_keys}"
puts "  Active API Keys: #{active_keys}"
puts "  Total Usage: #{total_usage} / #{total_limit} characters"
puts "  Overall Usage: #{(total_usage.to_f / total_limit * 100).round(2)}%" if total_limit > 0
```

### Permission Audit

```ruby
# Audit permissions across all service accounts
result = client.service_accounts.get_service_accounts

permissions_summary = Hash.new(0)
accounts_by_permission = Hash.new { |h, k| h[k] = [] }

result["service-accounts"].each do |account|
  account["api-keys"].each do |api_key|
    next if api_key["is_disabled"]
    
    api_key["permissions"].each do |permission|
      permissions_summary[permission] += 1
      accounts_by_permission[permission] << {
        account_name: account["name"],
        api_key_name: api_key["name"],
        key_id: api_key["key_id"]
      }
    end
  end
end

puts "Permission Usage Summary:"
permissions_summary.sort_by { |_, count| -count }.each do |permission, count|
  puts "  #{permission}: #{count} active API keys"
end

puts "\nDetailed Permission Breakdown:"
accounts_by_permission.each do |permission, keys|
  puts "\n#{permission}:"
  keys.each do |key_info|
    puts "  - #{key_info[:account_name]} / #{key_info[:api_key_name]} (#{key_info[:key_id]})"
  end
end
```

### Usage Monitoring

```ruby
# Monitor usage and identify accounts approaching limits
result = client.service_accounts.get_service_accounts

high_usage_accounts = []

result["service-accounts"].each do |account|
  account["api-keys"].each do |api_key|
    next if api_key["is_disabled"] || api_key["character_limit"] == 0
    
    usage_percentage = (api_key["character_count"].to_f / api_key["character_limit"] * 100)
    
    if usage_percentage > 80
      high_usage_accounts << {
        account_name: account["name"],
        api_key_name: api_key["name"],
        usage_percentage: usage_percentage.round(2),
        character_count: api_key["character_count"],
        character_limit: api_key["character_limit"]
      }
    end
  end
end

if high_usage_accounts.any?
  puts "⚠️  High Usage Alerts (>80%):"
  high_usage_accounts.sort_by { |a| -a[:usage_percentage] }.each do |account|
    puts "  #{account[:account_name]} / #{account[:api_key_name]}: #{account[:usage_percentage]}%"
    puts "    Usage: #{account[:character_count]} / #{account[:character_limit]} characters"
  end
else
  puts "✅ All API keys are within normal usage limits"
end
```

### Using Aliases

```ruby
# All these methods do the same thing
client.service_accounts.get_service_accounts
client.service_accounts.list
client.service_accounts.all
client.service_accounts.service_accounts
```

### Security Audit Service

```ruby
class ServiceAccountAuditService
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])
  end

  def generate_security_report
    result = @client.service_accounts.get_service_accounts
    
    report = {
      total_service_accounts: result["service-accounts"].length,
      total_api_keys: 0,
      active_api_keys: 0,
      disabled_api_keys: 0,
      permissions_distribution: Hash.new(0),
      high_usage_keys: [],
      old_api_keys: [],
      security_issues: []
    }

    result["service-accounts"].each do |account|
      account["api-keys"].each do |api_key|
        report[:total_api_keys] += 1
        
        if api_key["is_disabled"]
          report[:disabled_api_keys] += 1
        else
          report[:active_api_keys] += 1
        end

        # Track permissions
        api_key["permissions"].each do |permission|
          report[:permissions_distribution][permission] += 1
        end

        # Check for high usage
        if api_key["character_limit"] > 0
          usage_percentage = (api_key["character_count"].to_f / api_key["character_limit"] * 100)
          if usage_percentage > 90
            report[:high_usage_keys] << {
              account: account["name"],
              key: api_key["name"],
              usage: usage_percentage.round(2)
            }
          end
        end

        # Check for old API keys (older than 1 year)
        key_age_days = (Time.now.to_i - api_key["created_at_unix"]) / 86400
        if key_age_days > 365
          report[:old_api_keys] << {
            account: account["name"],
            key: api_key["name"],
            age_days: key_age_days
          }
        end

        # Security issue: API key with too many permissions
        if api_key["permissions"].length > 5
          report[:security_issues] << {
            type: "excessive_permissions",
            account: account["name"],
            key: api_key["name"],
            permissions_count: api_key["permissions"].length
          }
        end
      end
    end

    report
  end

  def print_security_report(report)
    puts "🔒 Service Account Security Report"
    puts "=" * 50
    puts "Service Accounts: #{report[:total_service_accounts]}"
    puts "Total API Keys: #{report[:total_api_keys]}"
    puts "Active API Keys: #{report[:active_api_keys]}"
    puts "Disabled API Keys: #{report[:disabled_api_keys]}"
    puts

    if report[:security_issues].any?
      puts "⚠️  Security Issues:"
      report[:security_issues].each do |issue|
        puts "  - #{issue[:account]} / #{issue[:key]}: #{issue[:type]} (#{issue[:permissions_count]} permissions)"
      end
      puts
    end

    if report[:high_usage_keys].any?
      puts "📊 High Usage Keys (>90%):"
      report[:high_usage_keys].each do |key|
        puts "  - #{key[:account]} / #{key[:key]}: #{key[:usage]}%"
      end
      puts
    end

    if report[:old_api_keys].any?
      puts "📅 Old API Keys (>1 year):"
      report[:old_api_keys].each do |key|
        puts "  - #{key[:account]} / #{key[:key]}: #{key[:age_days]} days old"
      end
      puts
    end

    puts "🔑 Permission Distribution:"
    report[:permissions_distribution].sort_by { |_, count| -count }.each do |permission, count|
      puts "  #{permission}: #{count} keys"
    end
  end
end

# Usage
audit_service = ServiceAccountAuditService.new
report = audit_service.generate_security_report
audit_service.print_security_report(report)
```

## Rails Integration

### Controller Integration

```ruby
class Admin::ServiceAccountsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @client = ElevenlabsClient::Client.new
    
    begin
      result = @client.service_accounts.get_service_accounts
      @service_accounts = result["service-accounts"]
      @statistics = calculate_statistics(@service_accounts)
      
      respond_to do |format|
        format.html
        format.json { render json: { success: true, data: result } }
        format.csv { send_data generate_csv(@service_accounts), filename: "service_accounts_#{Date.current}.csv" }
      end
    rescue ElevenlabsClient::AuthenticationError
      flash[:alert] = "Authentication failed"
      redirect_to admin_root_path
    rescue ElevenlabsClient::APIError => e
      flash[:alert] = "Service temporarily unavailable: #{e.message}"
      @service_accounts = []
      @statistics = default_statistics
    end
  end

  private

  def calculate_statistics(service_accounts)
    total_api_keys = service_accounts.sum { |account| account["api-keys"]&.count || 0 }
    active_api_keys = service_accounts.sum do |account|
      (account["api-keys"] || []).count { |key| !key["is_disabled"] }
    end
    
    {
      total_service_accounts: service_accounts.count,
      total_api_keys: total_api_keys,
      active_api_keys: active_api_keys,
      disabled_api_keys: total_api_keys - active_api_keys
    }
  end

  def generate_csv(service_accounts)
    CSV.generate do |csv|
      csv << ["Account Name", "Account ID", "API Key Name", "Key ID", "Status", "Permissions", "Character Usage", "Character Limit", "Created At"]
      
      service_accounts.each do |account|
        account["api-keys"].each do |api_key|
          csv << [
            account["name"],
            account["service_account_user_id"],
            api_key["name"],
            api_key["key_id"],
            api_key["is_disabled"] ? "Disabled" : "Active",
            api_key["permissions"].join("; "),
            api_key["character_count"],
            api_key["character_limit"],
            Time.at(api_key["created_at_unix"]).strftime("%Y-%m-%d %H:%M:%S")
          ]
        end
      end
    end
  end
end
```

### Background Job Integration

```ruby
class ServiceAccountAuditJob < ApplicationJob
  queue_as :default

  def perform
    client = ElevenlabsClient::Client.new
    
    result = client.service_accounts.get_service_accounts
    service_accounts = result["service-accounts"]
    
    # Generate audit report
    audit_report = generate_audit_report(service_accounts)
    
    # Store audit results
    ServiceAccountAudit.create!(
      audit_date: Date.current,
      total_service_accounts: audit_report[:total_service_accounts],
      total_api_keys: audit_report[:total_api_keys],
      active_api_keys: audit_report[:active_api_keys],
      security_issues_count: audit_report[:security_issues].count,
      high_usage_keys_count: audit_report[:high_usage_keys].count,
      raw_data: service_accounts
    )
    
    # Send alerts if needed
    if audit_report[:security_issues].any? || audit_report[:high_usage_keys].any?
      ServiceAccountAlertMailer.security_alert(audit_report).deliver_now
    end
  rescue ElevenlabsClient::APIError => e
    Rails.logger.error "Service account audit failed: #{e.message}"
    raise # Re-raise to trigger job retry
  end

  private

  def generate_audit_report(service_accounts)
    # Implementation similar to the ServiceAccountAuditService example above
  end
end

# Schedule the job to run daily
# In config/schedule.rb (using whenever gem):
# every 1.day, at: '6:00 am' do
#   runner "ServiceAccountAuditJob.perform_later"
# end
```

### API Endpoint

```ruby
class Api::V1::Admin::ServiceAccountsController < Api::V1::BaseController
  before_action :authenticate_admin_api!

  def index
    begin
      result = elevenlabs_client.service_accounts.get_service_accounts
      
      render json: {
        success: true,
        data: result,
        statistics: calculate_statistics(result["service-accounts"]),
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

  private

  def elevenlabs_client
    @elevenlabs_client ||= ElevenlabsClient::Client.new
  end

  def calculate_statistics(service_accounts)
    # Implementation details...
  end
end
```

## Best Practices

### 1. Caching and Performance

Cache service account data to reduce API calls:

```ruby
class ServiceAccountService
  def self.get_cached_service_accounts
    Rails.cache.fetch("service_accounts", expires_in: 15.minutes) do
      client = ElevenlabsClient::Client.new
      result = client.service_accounts.get_service_accounts
      result["service-accounts"]
    end
  end

  def self.invalidate_cache
    Rails.cache.delete("service_accounts")
  end
end
```

### 2. Error Handling and Retry Logic

Implement robust error handling with retry mechanisms:

```ruby
def get_service_accounts_with_retry(max_retries: 3)
  retries = 0
  
  begin
    client.service_accounts.get_service_accounts
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

### 3. Data Processing and Analysis

Process service account data efficiently:

```ruby
class ServiceAccountAnalyzer
  def initialize(service_accounts_data)
    @service_accounts = service_accounts_data
  end

  def analyze
    {
      summary: generate_summary,
      usage_analysis: analyze_usage,
      permission_audit: audit_permissions,
      security_recommendations: security_recommendations
    }
  end

  private

  def generate_summary
    total_accounts = @service_accounts.length
    total_keys = @service_accounts.sum { |account| account["api-keys"].length }
    active_keys = @service_accounts.sum do |account|
      account["api-keys"].count { |key| !key["is_disabled"] }
    end

    {
      total_service_accounts: total_accounts,
      total_api_keys: total_keys,
      active_api_keys: active_keys,
      inactive_api_keys: total_keys - active_keys
    }
  end

  def analyze_usage
    usage_data = []
    
    @service_accounts.each do |account|
      account["api-keys"].each do |api_key|
        next if api_key["character_limit"] == 0
        
        usage_percentage = (api_key["character_count"].to_f / api_key["character_limit"] * 100)
        
        usage_data << {
          account_name: account["name"],
          api_key_name: api_key["name"],
          usage_percentage: usage_percentage.round(2),
          character_count: api_key["character_count"],
          character_limit: api_key["character_limit"],
          status: categorize_usage(usage_percentage)
        }
      end
    end
    
    usage_data.sort_by { |data| -data[:usage_percentage] }
  end

  def audit_permissions
    permissions_by_account = {}
    
    @service_accounts.each do |account|
      permissions_by_account[account["name"]] = account["api-keys"].flat_map do |api_key|
        next [] if api_key["is_disabled"]
        
        api_key["permissions"].map do |permission|
          {
            api_key_name: api_key["name"],
            permission: permission,
            key_id: api_key["key_id"]
          }
        end
      end.compact
    end
    
    permissions_by_account
  end

  def security_recommendations
    recommendations = []
    
    @service_accounts.each do |account|
      account["api-keys"].each do |api_key|
        # Check for excessive permissions
        if api_key["permissions"].length > 3
          recommendations << {
            type: "excessive_permissions",
            severity: "medium",
            account: account["name"],
            api_key: api_key["name"],
            description: "API key has #{api_key['permissions'].length} permissions. Consider principle of least privilege."
          }
        end
        
        # Check for old API keys
        key_age_days = (Time.now.to_i - api_key["created_at_unix"]) / 86400
        if key_age_days > 365
          recommendations << {
            type: "old_api_key",
            severity: "low",
            account: account["name"],
            api_key: api_key["name"],
            description: "API key is #{key_age_days} days old. Consider rotating for security."
          }
        end
        
        # Check for high usage without monitoring
        if api_key["character_limit"] > 0
          usage_percentage = (api_key["character_count"].to_f / api_key["character_limit"] * 100)
          if usage_percentage > 95
            recommendations << {
              type: "usage_limit_reached",
              severity: "high",
              account: account["name"],
              api_key: api_key["name"],
              description: "API key has reached #{usage_percentage.round(1)}% of character limit."
            }
          end
        end
      end
    end
    
    recommendations.sort_by { |rec| severity_order(rec[:severity]) }
  end

  def categorize_usage(percentage)
    case percentage
    when 0..50 then "low"
    when 51..80 then "medium"
    when 81..95 then "high"
    else "critical"
    end
  end

  def severity_order(severity)
    case severity
    when "high" then 1
    when "medium" then 2
    when "low" then 3
    else 4
    end
  end
end
```

### 4. Monitoring and Alerting

Set up monitoring for service account health:

```ruby
class ServiceAccountMonitor
  def self.check_health
    client = ElevenlabsClient::Client.new
    result = client.service_accounts.get_service_accounts
    
    alerts = []
    
    result["service-accounts"].each do |account|
      account["api-keys"].each do |api_key|
        next if api_key["is_disabled"]
        
        # Check usage thresholds
        if api_key["character_limit"] > 0
          usage_percentage = (api_key["character_count"].to_f / api_key["character_limit"] * 100)
          
          if usage_percentage > 90
            alerts << {
              type: "high_usage",
              severity: "warning",
              message: "#{account['name']}/#{api_key['name']} at #{usage_percentage.round(1)}% usage"
            }
          end
        end
      end
    end
    
    # Send alerts if any issues found
    if alerts.any?
      ServiceAccountAlertService.send_alerts(alerts)
    end
    
    alerts
  end
end

# Schedule regular health checks
# ServiceAccountMonitor.check_health
```

### 5. Data Export and Reporting

Generate comprehensive reports:

```ruby
class ServiceAccountReporter
  def initialize
    @client = ElevenlabsClient::Client.new
  end

  def generate_excel_report
    result = @client.service_accounts.get_service_accounts
    
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = "Service Accounts"
    
    # Headers
    headers = ["Account Name", "Account ID", "API Key", "Status", "Permissions", "Usage %", "Characters Used", "Character Limit", "Created"]
    headers.each_with_index do |header, index|
      worksheet.add_cell(0, index, header)
    end
    
    # Data
    row = 1
    result["service-accounts"].each do |account|
      account["api-keys"].each do |api_key|
        usage_percentage = api_key["character_limit"] > 0 ? 
          (api_key["character_count"].to_f / api_key["character_limit"] * 100).round(2) : 0
        
        worksheet.add_cell(row, 0, account["name"])
        worksheet.add_cell(row, 1, account["service_account_user_id"])
        worksheet.add_cell(row, 2, api_key["name"])
        worksheet.add_cell(row, 3, api_key["is_disabled"] ? "Disabled" : "Active")
        worksheet.add_cell(row, 4, api_key["permissions"].join(", "))
        worksheet.add_cell(row, 5, usage_percentage)
        worksheet.add_cell(row, 6, api_key["character_count"])
        worksheet.add_cell(row, 7, api_key["character_limit"])
        worksheet.add_cell(row, 8, Time.at(api_key["created_at_unix"]).strftime("%Y-%m-%d"))
        
        row += 1
      end
    end
    
    workbook.write("service_accounts_report_#{Date.current}.xlsx")
  end
end
```

These best practices ensure efficient, secure, and maintainable integration of the Admin Service Accounts API into your application.
