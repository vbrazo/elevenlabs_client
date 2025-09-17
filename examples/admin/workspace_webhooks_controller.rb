# frozen_string_literal: true

require_relative "../../lib/elevenlabs_client"

class WorkspaceWebhooksController
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV["ELEVENLABS_API_KEY"])
  end

  def run_examples
    puts "🔗 Workspace Webhooks Examples"
    puts "=" * 35

    example_list_webhooks
    example_list_webhooks_with_usage
    example_webhook_health_monitoring
    example_webhook_configuration_audit
    example_webhook_performance_analysis
  end

  private

  def example_list_webhooks
    puts "\n1️⃣ List Workspace Webhooks"
    puts "-" * 30

    begin
      webhooks = @client.workspace_webhooks.list

      if webhooks["webhooks"].empty?
        puts "No webhooks configured for this workspace."
        return
      end

      puts "✅ Found #{webhooks['webhooks'].length} webhook(s):"
      
      webhooks["webhooks"].each_with_index do |webhook, index|
        puts "\n#{index + 1}. #{webhook['name']}"
        puts "   ID: #{webhook['webhook_id']}"
        puts "   URL: #{webhook['webhook_url']}"
        puts "   Status: #{webhook['is_disabled'] ? '❌ Disabled' : '✅ Enabled'}"
        puts "   Auto-disabled: #{webhook['is_auto_disabled'] ? 'Yes' : 'No'}"
        puts "   Auth Type: #{webhook['auth_type']}"
        puts "   Created: #{Time.at(webhook['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        
        if webhook['usage']&.any?
          puts "   Usage Types:"
          webhook['usage'].each do |usage|
            puts "     - #{usage['usage_type']}"
          end
        end
        
        if webhook['most_recent_failure_error_code']
          failure_time = Time.at(webhook['most_recent_failure_timestamp'])
          puts "   ⚠️ Last Failure: #{webhook['most_recent_failure_error_code']} at #{failure_time.strftime('%Y-%m-%d %H:%M:%S')}"
        else
          puts "   ✅ No recent failures"
        end
      end

    rescue ElevenlabsClient::AuthenticationError => e
      puts "❌ Authentication failed: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_list_webhooks_with_usage
    puts "\n2️⃣ List Webhooks with Usage Information (Admin Only)"
    puts "-" * 55

    begin
      webhooks_with_usage = @client.workspace_webhooks.list(include_usages: true)

      puts "✅ Retrieved webhooks with usage information:"
      
      webhooks_with_usage["webhooks"].each do |webhook|
        puts "\n🔗 #{webhook['name']}"
        puts "   Status: #{webhook['is_disabled'] ? 'Disabled' : 'Enabled'}"
        
        if webhook['usage']&.any?
          puts "   Active Usages (#{webhook['usage'].length}):"
          webhook['usage'].each do |usage|
            puts "     • #{usage['usage_type']}"
          end
        else
          puts "   No active usages"
        end
        
        # Analyze webhook health
        if webhook['is_auto_disabled']
          puts "   🔴 Health: Auto-disabled due to failures"
        elsif webhook['most_recent_failure_error_code']
          puts "   🟡 Health: Has recent failures"
        else
          puts "   🟢 Health: Healthy"
        end
      end

    rescue ElevenlabsClient::ForbiddenError => e
      puts "❌ Access denied (admin required): #{e.message}"
      puts "💡 Trying without usage information..."
      
      # Fallback to basic listing
      basic_webhooks = @client.workspace_webhooks.list
      puts "Retrieved #{basic_webhooks['webhooks'].length} webhooks (usage info not available)"
      
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_webhook_health_monitoring
    puts "\n3️⃣ Webhook Health Monitoring"
    puts "-" * 35

    begin
      webhooks = @client.workspace_webhooks.list

      if webhooks["webhooks"].empty?
        puts "No webhooks to monitor."
        return
      end

      puts "🔍 Analyzing webhook health..."
      
      health_stats = {
        healthy: 0,
        with_failures: 0,
        auto_disabled: 0,
        manually_disabled: 0
      }
      
      webhook_issues = []
      
      webhooks["webhooks"].each do |webhook|
        name = webhook['name']
        
        if webhook['is_disabled']
          puts "🔴 #{name}: MANUALLY DISABLED"
          health_stats[:manually_disabled] += 1
        elsif webhook['is_auto_disabled']
          puts "🔴 #{name}: AUTO-DISABLED (due to failures)"
          health_stats[:auto_disabled] += 1
          webhook_issues << "#{name}: Auto-disabled - investigate webhook endpoint"
        elsif webhook['most_recent_failure_error_code']
          failure_time = Time.at(webhook['most_recent_failure_timestamp'])
          days_since_failure = (Time.now - failure_time) / (60 * 60 * 24)
          puts "🟡 #{name}: HAS RECENT FAILURES (#{webhook['most_recent_failure_error_code']}, #{days_since_failure.round(1)} days ago)"
          health_stats[:with_failures] += 1
          webhook_issues << "#{name}: Recent failure #{webhook['most_recent_failure_error_code']}"
        else
          puts "🟢 #{name}: HEALTHY"
          health_stats[:healthy] += 1
        end
        
        # Security check
        if webhook['webhook_url'].start_with?('http://')
          webhook_issues << "#{name}: Using insecure HTTP protocol"
        end
      end
      
      # Summary
      total = webhooks["webhooks"].length
      puts "\n📊 Health Summary:"
      puts "Total Webhooks: #{total}"
      puts "Healthy: #{health_stats[:healthy]} (#{(health_stats[:healthy].to_f / total * 100).round(1)}%)"
      puts "With Failures: #{health_stats[:with_failures]} (#{(health_stats[:with_failures].to_f / total * 100).round(1)}%)"
      puts "Auto-disabled: #{health_stats[:auto_disabled]} (#{(health_stats[:auto_disabled].to_f / total * 100).round(1)}%)"
      puts "Manually Disabled: #{health_stats[:manually_disabled]} (#{(health_stats[:manually_disabled].to_f / total * 100).round(1)}%)"
      
      # Issues and recommendations
      if webhook_issues.any?
        puts "\n⚠️ Issues Found:"
        webhook_issues.each do |issue|
          puts "  • #{issue}"
        end
        
        puts "\n💡 Recommendations:"
        puts "  • Fix webhook endpoints that are failing"
        puts "  • Migrate HTTP webhooks to HTTPS"
        puts "  • Test webhook endpoints manually"
        puts "  • Review webhook authentication setup"
      else
        puts "\n✅ All webhooks are healthy!"
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Health monitoring failed: #{e.message}"
    end
  end

  def example_webhook_configuration_audit
    puts "\n4️⃣ Webhook Configuration Audit"
    puts "-" * 35

    begin
      # Try to get usage information first
      begin
        webhooks = @client.workspace_webhooks.list(include_usages: true)
        admin_access = true
      rescue ElevenlabsClient::ForbiddenError
        puts "⚠️ Admin access not available - limited audit information"
        webhooks = @client.workspace_webhooks.list
        admin_access = false
      end

      if webhooks["webhooks"].empty?
        puts "No webhooks to audit."
        return
      end

      puts "📋 Webhook Configuration Audit"
      puts "Admin Access: #{admin_access ? 'Yes' : 'No'}"
      puts
      
      audit_findings = {
        security_issues: [],
        reliability_issues: [],
        configuration_issues: []
      }
      
      webhooks["webhooks"].each_with_index do |webhook, index|
        puts "#{index + 1}. #{webhook['name']}"
        puts "   URL: #{webhook['webhook_url']}"
        puts "   Authentication: #{webhook['auth_type']}"
        puts "   Status: #{webhook['is_disabled'] ? 'Disabled' : 'Enabled'}"
        
        # Security audit
        if webhook['webhook_url'].start_with?('http://')
          puts "   🔒 SECURITY: Using HTTP instead of HTTPS"
          audit_findings[:security_issues] << "#{webhook['name']}: Insecure HTTP connection"
        else
          puts "   🔒 Security: ✅ Using HTTPS"
        end
        
        # Authentication audit
        if webhook['auth_type'] == 'none'
          puts "   🔐 AUTH: ⚠️ No authentication configured"
          audit_findings[:security_issues] << "#{webhook['name']}: No authentication"
        else
          puts "   🔐 Authentication: ✅ #{webhook['auth_type']}"
        end
        
        # Reliability audit
        if webhook['is_auto_disabled']
          puts "   📊 RELIABILITY: ❌ Auto-disabled due to failures"
          audit_findings[:reliability_issues] << "#{webhook['name']}: Auto-disabled"
        elsif webhook['most_recent_failure_error_code']
          failure_time = Time.at(webhook['most_recent_failure_timestamp'])
          days_since_failure = (Time.now - failure_time) / (60 * 60 * 24)
          puts "   📊 Reliability: ⚠️ Last failure #{days_since_failure.round(1)} days ago (#{webhook['most_recent_failure_error_code']})"
          
          if days_since_failure < 7
            audit_findings[:reliability_issues] << "#{webhook['name']}: Recent failures"
          end
        else
          puts "   📊 Reliability: ✅ No recent failures"
        end
        
        # Usage audit (if admin access)
        if admin_access && webhook['usage']
          if webhook['usage'].any?
            puts "   🎯 Usage: ✅ #{webhook['usage'].length} active usage(s)"
            webhook['usage'].each do |usage|
              puts "      - #{usage['usage_type']}"
            end
          else
            puts "   🎯 Usage: ⚠️ No active usages"
            audit_findings[:configuration_issues] << "#{webhook['name']}: No active usages"
          end
        end
        
        # Age audit
        created_time = Time.at(webhook['created_at_unix'])
        days_old = (Time.now - created_time) / (60 * 60 * 24)
        
        if days_old > 365
          puts "   📅 Age: ⚠️ #{days_old.round} days (very old)"
        elsif days_old > 180
          puts "   📅 Age: #{days_old.round} days"
        else
          puts "   📅 Age: ✅ #{days_old.round} days"
        end
        
        puts
      end
      
      # Audit summary
      puts "🔍 Audit Summary:"
      total_issues = audit_findings.values.map(&:length).sum
      puts "Total Issues Found: #{total_issues}"
      
      if audit_findings[:security_issues].any?
        puts "\n🔒 Security Issues (#{audit_findings[:security_issues].length}):"
        audit_findings[:security_issues].each { |issue| puts "  • #{issue}" }
      end
      
      if audit_findings[:reliability_issues].any?
        puts "\n📊 Reliability Issues (#{audit_findings[:reliability_issues].length}):"
        audit_findings[:reliability_issues].each { |issue| puts "  • #{issue}" }
      end
      
      if audit_findings[:configuration_issues].any?
        puts "\n⚙️ Configuration Issues (#{audit_findings[:configuration_issues].length}):"
        audit_findings[:configuration_issues].each { |issue| puts "  • #{issue}" }
      end
      
      if total_issues == 0
        puts "✅ No issues found - all webhooks are properly configured!"
      else
        puts "\n💡 Recommendations:"
        puts "  • Address security issues immediately"
        puts "  • Test and fix failing webhook endpoints"
        puts "  • Review webhook configurations regularly"
        puts "  • Consider consolidating unused webhooks"
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Configuration audit failed: #{e.message}"
    end
  end

  def example_webhook_performance_analysis
    puts "\n5️⃣ Webhook Performance Analysis"
    puts "-" * 40

    begin
      webhooks = @client.workspace_webhooks.list

      if webhooks["webhooks"].empty?
        puts "No webhooks to analyze."
        return
      end

      puts "📈 Analyzing webhook performance..."
      
      # Categorize webhooks
      categories = {
        active_healthy: [],
        active_with_issues: [],
        auto_disabled: [],
        manually_disabled: []
      }
      
      webhooks["webhooks"].each do |webhook|
        if webhook['is_disabled']
          categories[:manually_disabled] << webhook
        elsif webhook['is_auto_disabled']
          categories[:auto_disabled] << webhook
        elsif webhook['most_recent_failure_error_code']
          categories[:active_with_issues] << webhook
        else
          categories[:active_healthy] << webhook
        end
      end
      
      total = webhooks["webhooks"].length
      
      # Performance metrics
      puts "\n📊 Performance Overview:"
      puts "Active & Healthy: #{categories[:active_healthy].length} (#{(categories[:active_healthy].length.to_f / total * 100).round(1)}%)"
      puts "Active with Issues: #{categories[:active_with_issues].length} (#{(categories[:active_with_issues].length.to_f / total * 100).round(1)}%)"
      puts "Auto-disabled: #{categories[:auto_disabled].length} (#{(categories[:auto_disabled].length.to_f / total * 100).round(1)}%)"
      puts "Manually Disabled: #{categories[:manually_disabled].length} (#{(categories[:manually_disabled].length.to_f / total * 100).round(1)}%)"
      
      # Calculate health score
      health_score = (categories[:active_healthy].length.to_f / total * 100).round(1)
      
      puts "\n🏥 Overall Health Score: #{health_score}%"
      case health_score
      when 90..100
        puts "   🟢 EXCELLENT - Webhooks are performing very well"
      when 75..89
        puts "   🟡 GOOD - Minor issues that should be addressed"
      when 50..74
        puts "   🟠 FAIR - Significant issues requiring attention"
      else
        puts "   🔴 POOR - Critical issues requiring immediate action"
      end
      
      # Authentication analysis
      puts "\n🔐 Authentication Methods:"
      auth_types = webhooks["webhooks"].group_by { |w| w['auth_type'] }
      auth_types.each do |auth_type, hooks|
        puts "  #{auth_type}: #{hooks.length}"
      end
      
      # Protocol analysis
      puts "\n🔒 Protocol Analysis:"
      https_count = webhooks["webhooks"].count { |w| w['webhook_url'].start_with?('https://') }
      http_count = webhooks["webhooks"].count { |w| w['webhook_url'].start_with?('http://') }
      puts "  HTTPS: #{https_count} (#{(https_count.to_f / total * 100).round(1)}%)"
      puts "  HTTP: #{http_count} (#{(http_count.to_f / total * 100).round(1)}%)"
      
      # Age distribution
      puts "\n📅 Age Distribution:"
      now = Time.now
      age_buckets = { "< 1 month" => 0, "1-6 months" => 0, "6-12 months" => 0, "> 1 year" => 0 }
      
      webhooks["webhooks"].each do |webhook|
        created_time = Time.at(webhook['created_at_unix'])
        days_old = (now - created_time) / (60 * 60 * 24)
        
        case days_old
        when 0..30
          age_buckets["< 1 month"] += 1
        when 31..180
          age_buckets["1-6 months"] += 1
        when 181..365
          age_buckets["6-12 months"] += 1
        else
          age_buckets["> 1 year"] += 1
        end
      end
      
      age_buckets.each do |range, count|
        percentage = (count.to_f / total * 100).round(1)
        puts "  #{range}: #{count} (#{percentage}%)"
      end
      
      # Failure analysis
      if categories[:active_with_issues].any? || categories[:auto_disabled].any?
        puts "\n⚠️ Failure Analysis:"
        
        all_failures = categories[:active_with_issues] + categories[:auto_disabled]
        error_codes = all_failures.map { |w| w['most_recent_failure_error_code'] }.compact
        
        if error_codes.any?
          error_frequency = error_codes.group_by(&:itself).transform_values(&:count)
          puts "  Common Error Codes:"
          error_frequency.sort_by { |_, count| -count }.each do |code, count|
            puts "    #{code}: #{count} occurrence(s)"
          end
        end
      end
      
      # Recommendations
      puts "\n💡 Performance Recommendations:"
      
      if health_score < 80
        puts "  🔴 URGENT: Overall health is below 80% - immediate action required"
      end
      
      if http_count > 0
        puts "  🔒 Migrate #{http_count} HTTP webhook(s) to HTTPS for security"
      end
      
      if categories[:auto_disabled].any?
        puts "  🔧 Fix #{categories[:auto_disabled].length} auto-disabled webhook(s)"
      end
      
      if categories[:active_with_issues].any?
        puts "  ⚠️ Monitor #{categories[:active_with_issues].length} webhook(s) with recent failures"
      end
      
      old_webhooks = webhooks["webhooks"].count do |w|
        days_old = (now - Time.at(w['created_at_unix'])) / (60 * 60 * 24)
        days_old > 365
      end
      
      if old_webhooks > 0
        puts "  📅 Review #{old_webhooks} webhook(s) older than 1 year"
      end
      
      if auth_types.key?('none')
        puts "  🔐 Add authentication to #{auth_types['none'].length} unsecured webhook(s)"
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Performance analysis failed: #{e.message}"
    end
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  controller = WorkspaceWebhooksController.new
  controller.run_examples
end
