# frozen_string_literal: true

require_relative "../../lib/elevenlabs_client"

class ServiceAccountApiKeysController
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV["ELEVENLABS_API_KEY"])
  end

  def run_examples
    puts "🔑 Service Account API Keys Examples"
    puts "=" * 40

    # You'll need to provide a service account ID for these examples
    service_account_id = ENV["SERVICE_ACCOUNT_ID"] || "service_account_example_id"

    example_list_api_keys(service_account_id)
    example_create_api_key(service_account_id)
    example_update_api_key(service_account_id)
    example_delete_api_key(service_account_id)
    example_api_key_management_workflow(service_account_id)
    example_security_audit(service_account_id)
    example_usage_monitoring(service_account_id)
  end

  private

  def example_list_api_keys(service_account_id)
    puts "\n1️⃣ List API Keys"
    puts "-" * 20

    begin
      api_keys = @client.service_account_api_keys.list(service_account_id)

      if api_keys["api-keys"].empty?
        puts "No API keys found for service account: #{service_account_id}"
        return
      end

      puts "✅ Found #{api_keys['api-keys'].length} API key(s):"
      
      api_keys["api-keys"].each_with_index do |key, index|
        status = key['is_disabled'] ? "❌ Disabled" : "✅ Enabled"
        
        puts "\n#{index + 1}. #{key['name']}"
        puts "   Key ID: #{key['key_id']}"
        puts "   Hint: #{key['hint']}"
        puts "   Status: #{status}"
        puts "   Created: #{Time.at(key['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        puts "   Permissions: #{key['permissions'].join(', ')}"
        
        if key['character_limit']
          usage_percent = (key['character_count'].to_f / key['character_limit'] * 100).round(1)
          puts "   Usage: #{key['character_count'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} / #{key['character_limit'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters (#{usage_percent}%)"
          
          # Visual usage bar
          bar_length = 20
          filled = (usage_percent / 5).round
          bar = "█" * filled + "░" * (bar_length - filled)
          puts "   Usage: [#{bar}] #{usage_percent}%"
          
          if usage_percent > 80
            puts "   ⚠️ WARNING: High usage (#{usage_percent}%)"
          end
        else
          puts "   Usage: #{key['character_count'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters (unlimited)"
        end
      end

    rescue ElevenlabsClient::NotFoundError => e
      puts "❌ Service account not found: #{e.message}"
    rescue ElevenlabsClient::AuthenticationError => e
      puts "❌ Authentication failed: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_create_api_key(service_account_id)
    puts "\n2️⃣ Create API Key"
    puts "-" * 20

    begin
      puts "Creating a new API key with limited permissions..."
      
      new_key = @client.service_account_api_keys.create(
        service_account_id,
        name: "Ruby Client Demo Key",
        permissions: ["text_to_speech", "voices"],
        character_limit: 10000  # 10k character limit for demo
      )

      puts "✅ API key created successfully!"
      puts "New API Key: #{new_key['xi-api-key']}"
      puts "⚠️ IMPORTANT: Save this key securely - it won't be shown again!"
      
      # Store the key hint for later use in other examples
      @demo_key_hint = new_key['xi-api-key'][-4..-1] # Last 4 characters as hint
      
      puts "\n📝 Key Details:"
      puts "Name: Ruby Client Demo Key"
      puts "Permissions: text_to_speech, voices"
      puts "Character Limit: 10,000"

    rescue ElevenlabsClient::ValidationError => e
      puts "❌ Validation error: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Creation failed: #{e.message}"
    end
  end

  def example_update_api_key(service_account_id)
    puts "\n3️⃣ Update API Key"
    puts "-" * 20

    begin
      # First, find the demo key we created
      api_keys = @client.service_account_api_keys.list(service_account_id)
      demo_key = api_keys["api-keys"].find { |key| key['name'] == "Ruby Client Demo Key" }

      if demo_key.nil?
        puts "⚠️ Demo key not found. Creating one for the update example..."
        
        new_key = @client.service_account_api_keys.create(
          service_account_id,
          name: "Ruby Client Demo Key",
          permissions: ["text_to_speech"],
          character_limit: 5000
        )
        
        # Refresh the list to get the key details
        api_keys = @client.service_account_api_keys.list(service_account_id)
        demo_key = api_keys["api-keys"].find { |key| key['name'] == "Ruby Client Demo Key" }
      end

      puts "Updating API key: #{demo_key['name']}"
      puts "Current permissions: #{demo_key['permissions'].join(', ')}"
      puts "Current limit: #{demo_key['character_limit'] || 'unlimited'}"
      
      # Update the key with more permissions and higher limit
      @client.service_account_api_keys.update(
        service_account_id,
        demo_key['key_id'],
        is_enabled: true,
        name: "Ruby Client Demo Key (Updated)",
        permissions: ["text_to_speech", "voices", "models"],
        character_limit: 25000
      )

      puts "✅ API key updated successfully!"
      puts "New name: Ruby Client Demo Key (Updated)"
      puts "New permissions: text_to_speech, voices, models"
      puts "New character limit: 25,000"

    rescue ElevenlabsClient::NotFoundError => e
      puts "❌ API key not found: #{e.message}"
    rescue ElevenlabsClient::ValidationError => e
      puts "❌ Validation error: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Update failed: #{e.message}"
    end
  end

  def example_delete_api_key(service_account_id)
    puts "\n4️⃣ Delete API Key"
    puts "-" * 20

    begin
      # Find the demo key we created/updated
      api_keys = @client.service_account_api_keys.list(service_account_id)
      demo_key = api_keys["api-keys"].find { |key| key['name'].include?("Ruby Client Demo Key") }

      if demo_key.nil?
        puts "⚠️ No demo key found to delete."
        return
      end

      puts "Deleting API key: #{demo_key['name']}"
      puts "Key ID: #{demo_key['key_id']}"
      
      @client.service_account_api_keys.delete(service_account_id, demo_key['key_id'])

      puts "✅ API key deleted successfully!"
      puts "The key #{demo_key['name']} has been permanently removed."

    rescue ElevenlabsClient::NotFoundError => e
      puts "❌ API key not found: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Deletion failed: #{e.message}"
    end
  end

  def example_api_key_management_workflow(service_account_id)
    puts "\n5️⃣ Complete API Key Management Workflow"
    puts "-" * 45

    begin
      puts "🔄 Starting comprehensive API key management workflow..."
      
      # Step 1: Initial audit
      puts "\nStep 1: Initial API Key Audit"
      initial_keys = @client.service_account_api_keys.list(service_account_id)
      puts "Current API keys: #{initial_keys['api-keys'].length}"
      
      # Step 2: Create development key
      puts "\nStep 2: Creating Development API Key"
      dev_key = @client.service_account_api_keys.create(
        service_account_id,
        name: "Development Key - #{Time.now.strftime('%Y%m%d')}", 
        permissions: ["text_to_speech", "voices"],
        character_limit: 50000
      )
      puts "✅ Development key created: #{dev_key['xi-api-key'][-8..-1]}****"
      
      # Step 3: Create production key
      puts "\nStep 3: Creating Production API Key"
      prod_key = @client.service_account_api_keys.create(
        service_account_id,
        name: "Production Key - #{Time.now.strftime('%Y%m%d')}",
        permissions: ["text_to_speech"],
        character_limit: 1000000  # 1M characters for production
      )
      puts "✅ Production key created: #{prod_key['xi-api-key'][-8..-1]}****"
      
      # Step 4: Verify creation
      puts "\nStep 4: Verifying New Keys"
      updated_keys = @client.service_account_api_keys.list(service_account_id)
      new_keys = updated_keys["api-keys"].select do |key|
        key['name'].include?(Time.now.strftime('%Y%m%d'))
      end
      
      puts "New keys created: #{new_keys.length}"
      new_keys.each do |key|
        puts "  • #{key['name']} (#{key['permissions'].join(', ')})"
      end
      
      # Step 5: Update development key (simulate configuration change)
      puts "\nStep 5: Updating Development Key Configuration"
      dev_key_info = new_keys.find { |k| k['name'].include?('Development') }
      if dev_key_info
        @client.service_account_api_keys.update(
          service_account_id,
          dev_key_info['key_id'],
          is_enabled: true,
          name: dev_key_info['name'] + " (Enhanced)",
          permissions: ["text_to_speech", "voices", "models"], # Add models permission
          character_limit: 75000  # Increase limit
        )
        puts "✅ Development key enhanced with additional permissions"
      end
      
      # Step 6: Security audit
      puts "\nStep 6: Security Audit"
      final_keys = @client.service_account_api_keys.list(service_account_id)
      
      security_issues = []
      final_keys["api-keys"].each do |key|
        if key['permissions'].include?("all") || key['permissions'] == "all"
          security_issues << "#{key['name']}: Has 'all' permissions (overprivileged)"
        end
        
        if key['character_limit'].nil?
          security_issues << "#{key['name']}: No character limit set"
        end
        
        created_time = Time.at(key['created_at_unix'])
        days_old = (Time.now - created_time) / (60 * 60 * 24)
        if days_old > 365
          security_issues << "#{key['name']}: Very old key (#{days_old.round} days)"
        end
      end
      
      if security_issues.any?
        puts "⚠️ Security issues found:"
        security_issues.each { |issue| puts "  • #{issue}" }
      else
        puts "✅ No security issues found"
      end
      
      # Step 7: Cleanup (delete demo keys)
      puts "\nStep 7: Cleanup"
      demo_keys_to_delete = final_keys["api-keys"].select do |key|
        key['name'].include?(Time.now.strftime('%Y%m%d'))
      end
      
      demo_keys_to_delete.each do |key|
        @client.service_account_api_keys.delete(service_account_id, key['key_id'])
        puts "🗑️ Deleted demo key: #{key['name']}"
      end
      
      puts "\n🎉 Workflow completed successfully!"

    rescue ElevenlabsClient::APIError => e
      puts "❌ Workflow failed: #{e.message}"
    end
  end

  def example_security_audit(service_account_id)
    puts "\n6️⃣ Security Audit"
    puts "-" * 20

    begin
      puts "🔒 Conducting security audit of API keys..."
      
      api_keys = @client.service_account_api_keys.list(service_account_id)
      
      if api_keys["api-keys"].empty?
        puts "No API keys to audit."
        return
      end
      
      security_score = 0
      max_score = api_keys["api-keys"].length * 4  # 4 checks per key
      security_issues = []
      
      api_keys["api-keys"].each do |key|
        puts "\n🔑 Auditing: #{key['name']}"
        
        # Check 1: Key status
        if key['is_disabled']
          puts "  ✅ Status: Disabled (secure when not needed)"
          security_score += 1
        else
          puts "  ⚠️ Status: Enabled"
        end
        
        # Check 2: Permissions
        if key['permissions'].include?("all") || key['permissions'] == "all"
          puts "  ❌ Permissions: ALL (overprivileged)"
          security_issues << "#{key['name']}: Has 'all' permissions"
        else
          puts "  ✅ Permissions: Limited (#{key['permissions'].join(', ')})"
          security_score += 1
        end
        
        # Check 3: Character limit
        if key['character_limit']
          usage_percent = (key['character_count'].to_f / key['character_limit'] * 100).round(1)
          puts "  ✅ Character Limit: #{key['character_limit']} (#{usage_percent}% used)"
          security_score += 1
          
          if usage_percent > 90
            security_issues << "#{key['name']}: Near character limit (#{usage_percent}%)"
          end
        else
          puts "  ❌ Character Limit: Unlimited"
          security_issues << "#{key['name']}: No character limit set"
        end
        
        # Check 4: Age
        created_time = Time.at(key['created_at_unix'])
        days_old = (Time.now - created_time) / (60 * 60 * 24)
        
        if days_old > 365
          puts "  ❌ Age: #{days_old.round} days (consider rotation)"
          security_issues << "#{key['name']}: Very old key (#{days_old.round} days)"
        elsif days_old > 180
          puts "  ⚠️ Age: #{days_old.round} days"
        else
          puts "  ✅ Age: #{days_old.round} days"
          security_score += 1
        end
      end
      
      # Calculate security score
      security_percentage = (security_score.to_f / max_score * 100).round(1)
      
      puts "\n📊 Security Audit Results:"
      puts "Security Score: #{security_score}/#{max_score} (#{security_percentage}%)"
      
      case security_percentage
      when 90..100
        puts "🟢 EXCELLENT - Strong security posture"
      when 75..89
        puts "🟡 GOOD - Minor security improvements needed"
      when 50..74
        puts "🟠 FAIR - Several security issues to address"
      else
        puts "🔴 POOR - Critical security vulnerabilities"
      end
      
      if security_issues.any?
        puts "\n❌ Security Issues (#{security_issues.length}):"
        security_issues.each { |issue| puts "  • #{issue}" }
        
        puts "\n💡 Security Recommendations:"
        puts "  • Rotate API keys older than 6 months"
        puts "  • Set character limits on all keys"
        puts "  • Use principle of least privilege for permissions"
        puts "  • Disable unused API keys"
        puts "  • Monitor API key usage regularly"
      else
        puts "\n✅ No security issues found - excellent security posture!"
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Security audit failed: #{e.message}"
    end
  end

  def example_usage_monitoring(service_account_id)
    puts "\n7️⃣ Usage Monitoring"
    puts "-" * 20

    begin
      puts "📊 Monitoring API key usage patterns..."
      
      api_keys = @client.service_account_api_keys.list(service_account_id)
      
      if api_keys["api-keys"].empty?
        puts "No API keys to monitor."
        return
      end
      
      total_usage = 0
      total_limit = 0
      keys_near_limit = []
      unlimited_keys = []
      high_usage_keys = []
      
      puts "\n📈 Usage Overview:"
      puts "-" * 60
      
      api_keys["api-keys"].each do |key|
        usage = key['character_count']
        limit = key['character_limit']
        
        total_usage += usage
        
        puts "\n#{key['name']}"
        puts "  Status: #{key['is_disabled'] ? 'Disabled' : 'Active'}"
        puts "  Permissions: #{key['permissions'].join(', ')}"
        
        if limit
          total_limit += limit
          usage_percent = (usage.to_f / limit * 100).round(1)
          
          # Create visual usage bar
          bar_length = 30
          filled = (usage_percent / (100.0 / bar_length)).round
          filled = [filled, bar_length].min
          bar = "█" * filled + "░" * (bar_length - filled)
          
          puts "  Usage: [#{bar}] #{usage_percent}%"
          puts "  Characters: #{usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} / #{limit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
          
          # Flag keys near limit
          if usage_percent > 80
            keys_near_limit << {
              name: key['name'],
              usage_percent: usage_percent,
              usage: usage,
              limit: limit
            }
            puts "  ⚠️ HIGH USAGE WARNING"
          end
          
          # Track high usage keys for recommendations
          if usage > 100000  # More than 100k characters
            high_usage_keys << key['name']
          end
          
        else
          unlimited_keys << {
            name: key['name'],
            usage: usage
          }
          puts "  Usage: Unlimited"
          puts "  Characters: #{usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
        end
        
        # Calculate daily usage estimate
        created_time = Time.at(key['created_at_unix'])
        days_active = [(Time.now - created_time) / (60 * 60 * 24), 1].max
        daily_avg = (usage / days_active).round
        
        puts "  Daily Average: #{daily_avg.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters"
        
        # Project monthly usage
        if daily_avg > 0
          monthly_projection = daily_avg * 30
          puts "  Monthly Projection: #{monthly_projection.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters"
          
          if limit && monthly_projection > limit
            puts "  ❌ PROJECTION EXCEEDS LIMIT"
          end
        end
      end
      
      # Summary statistics
      puts "\n📊 Usage Statistics:"
      puts "Total Characters Used: #{total_usage.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
      if total_limit > 0
        overall_usage_percent = (total_usage.to_f / total_limit * 100).round(1)
        puts "Total Character Limit: #{total_limit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
        puts "Overall Usage: #{overall_usage_percent}%"
      end
      
      active_keys = api_keys['api-keys'].count { |k| !k['is_disabled'] }
      puts "Active Keys: #{active_keys}/#{api_keys['api-keys'].length}"
      
      # Alerts and warnings
      if keys_near_limit.any?
        puts "\n⚠️ Keys Near Limit (>80%):"
        keys_near_limit.each do |key_info|
          puts "  • #{key_info[:name]}: #{key_info[:usage_percent]}% (#{key_info[:usage]}/#{key_info[:limit]})"
        end
      end
      
      if unlimited_keys.any?
        puts "\n📝 Unlimited Keys:"
        unlimited_keys.each do |key_info|
          puts "  • #{key_info[:name]}: #{key_info[:usage].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters used"
        end
      end
      
      # Usage insights and recommendations
      puts "\n💡 Usage Insights:"
      
      if keys_near_limit.any?
        puts "  • #{keys_near_limit.length} key(s) approaching character limits"
        puts "  • Consider increasing limits or optimizing usage"
      end
      
      if high_usage_keys.any?
        puts "  • #{high_usage_keys.length} key(s) with high usage (>100k characters)"
        puts "  • Monitor these keys closely for cost management"
      end
      
      if unlimited_keys.any?
        puts "  • #{unlimited_keys.length} key(s) have unlimited usage"
        puts "  • Consider setting limits for cost control"
      end
      
      disabled_count = api_keys['api-keys'].count { |k| k['is_disabled'] }
      if disabled_count > 0
        puts "  • #{disabled_count} disabled key(s) - consider removing if unused"
      end
      
      # Growth projections
      if total_usage > 0 && api_keys['api-keys'].any?
        avg_age_days = api_keys['api-keys'].map do |key|
          (Time.now - Time.at(key['created_at_unix'])) / (60 * 60 * 24)
        end.sum / api_keys['api-keys'].length
        
        if avg_age_days > 30
          growth_rate = total_usage / avg_age_days * 30  # Monthly growth
          puts "\n📈 Growth Projections:"
          puts "  Current Monthly Rate: #{growth_rate.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters"
          puts "  Projected 3-month usage: #{(growth_rate * 3).round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} characters"
        end
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Usage monitoring failed: #{e.message}"
    end
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  controller = ServiceAccountApiKeysController.new
  controller.run_examples
end
