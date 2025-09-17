# frozen_string_literal: true

require_relative "../../lib/elevenlabs_client"

class BatchCallingController
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV["ELEVENLABS_API_KEY"])
  end

  def run_examples
    puts "📞 Batch Calling Examples"
    puts "=" * 30

    # Get required IDs from environment
    agent_id = ENV["AGENT_ID"] || "your_agent_id_here"
    phone_number_id = ENV["PHONE_NUMBER_ID"] || "your_phone_number_id_here"

    example_submit_batch_call(agent_id, phone_number_id)
    example_list_batch_jobs
    example_get_batch_details
    example_cancel_batch_job
    example_retry_batch_job
    example_customer_survey_campaign(agent_id, phone_number_id)
    example_appointment_reminder_system(agent_id, phone_number_id)
    example_campaign_monitoring_dashboard
    example_campaign_analytics
  end

  private

  def example_submit_batch_call(agent_id, phone_number_id)
    puts "\n1️⃣ Submit Batch Call Job"
    puts "-" * 25

    # Sample recipients list
    recipients = [
      { phone_number: "+1555123456" },
      { phone_number: "+1555987654" },
      { phone_number: "+1555111222" },
      { phone_number: "+1555333444" },
      { phone_number: "+1555555666" }
    ]

    begin
      # Schedule batch call for 1 hour from now
      scheduled_time = Time.now + 3600

      puts "📋 Submitting batch call job..."
      puts "Recipients: #{recipients.length}"
      puts "Scheduled for: #{scheduled_time.strftime('%Y-%m-%d %H:%M:%S')}"

      # Simulate batch job submission
      batch_job = simulate_batch_job_creation(
        call_name: "Customer Survey Campaign - #{Date.today.strftime('%Y-%m-%d')}",
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        scheduled_time_unix: scheduled_time.to_i,
        recipients: recipients
      )

      puts "✅ Batch job created successfully!"
      puts "Job ID: #{batch_job['id']}"
      puts "Name: #{batch_job['name']}"
      puts "Total calls scheduled: #{batch_job['total_calls_scheduled']}"
      puts "Status: #{batch_job['status']}"
      puts "Agent: #{batch_job['agent_name']}"
      puts "Phone Provider: #{batch_job['phone_provider']}"

    rescue ElevenlabsClient::ValidationError => e
      puts "❌ Invalid parameters: #{e.message}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Submission failed: #{e.message}"
    end
  end

  def example_list_batch_jobs
    puts "\n2️⃣ List Batch Call Jobs"
    puts "-" * 25

    begin
      puts "📋 Retrieving batch call jobs..."

      # Simulate listing batch jobs
      batch_jobs = simulate_batch_jobs_list

      if batch_jobs['batch_calls'].empty?
        puts "No batch call jobs found."
        return
      end

      puts "✅ Found #{batch_jobs['batch_calls'].length} batch jobs:"
      
      batch_jobs['batch_calls'].each do |job|
        puts "\n#{job['id']}: #{job['name']}"
        puts "  Agent: #{job['agent_name']}"
        puts "  Status: #{job['status']}"
        puts "  Created: #{Time.at(job['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        puts "  Scheduled: #{Time.at(job['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        puts "  Progress: #{job['total_calls_dispatched']}/#{job['total_calls_scheduled']}"
        puts "  Provider: #{job['phone_provider']}"
        
        # Show status indicator
        case job['status']
        when 'pending'
          puts "  📅 Waiting to start"
        when 'in_progress'
          progress_percent = (job['total_calls_dispatched'].to_f / job['total_calls_scheduled'] * 100).round(1)
          puts "  🔄 In progress (#{progress_percent}%)"
        when 'completed'
          puts "  ✅ Completed"
        when 'failed'
          puts "  ❌ Failed"
        when 'cancelled'
          puts "  ⏹️ Cancelled"
        end
      end

      # Demonstrate pagination
      if batch_jobs['has_more']
        puts "\n📄 More jobs available. Next cursor: #{batch_jobs['next_doc']}"
        puts "To get next page: client.batch_calling.list(last_doc: '#{batch_jobs['next_doc']}')"
      end

    rescue ElevenlabsClient::APIError => e
      puts "❌ Failed to list batch jobs: #{e.message}"
    end
  end

  def example_get_batch_details
    puts "\n3️⃣ Get Batch Call Details"
    puts "-" * 30

    sample_batch_id = "batch_12345"
    
    begin
      puts "🔍 Getting detailed information for batch job: #{sample_batch_id}"

      # Simulate getting batch details
      batch_details = simulate_batch_job_details(sample_batch_id)

      puts "✅ Batch job details retrieved:"
      puts "\n📊 Job Information:"
      puts "ID: #{batch_details['id']}"
      puts "Name: #{batch_details['name']}"
      puts "Agent: #{batch_details['agent_name']} (#{batch_details['agent_id']})"
      puts "Phone Provider: #{batch_details['phone_provider']}"
      puts "Status: #{batch_details['status']}"
      puts "Created: #{Time.at(batch_details['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Scheduled: #{Time.at(batch_details['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Last Updated: #{Time.at(batch_details['last_updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"

      # Analyze recipient status
      recipients = batch_details['recipients']
      recipient_stats = recipients.group_by { |r| r['status'] }

      puts "\n📞 Recipient Summary:"
      puts "Total recipients: #{recipients.length}"
      recipient_stats.each do |status, recipients_in_status|
        percentage = (recipients_in_status.length.to_f / recipients.length * 100).round(1)
        puts "#{status.capitalize}: #{recipients_in_status.length} (#{percentage}%)"
      end

      # Show detailed recipient information (first 5)
      puts "\n👥 Recipient Details (showing first 5):"
      recipients.first(5).each_with_index do |recipient, index|
        puts "#{index + 1}. #{recipient['phone_number']} - #{recipient['status']}"
        puts "   ID: #{recipient['id']}"
        puts "   Created: #{Time.at(recipient['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        puts "   Updated: #{Time.at(recipient['updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
        
        if recipient['conversation_id']
          puts "   Conversation: #{recipient['conversation_id']}"
        end
        
        if recipient['conversation_initiation_client_data']
          client_data = recipient['conversation_initiation_client_data']
          puts "   User ID: #{client_data['user_id']}" if client_data['user_id']
          puts "   Source: #{client_data['source_info']['source']}" if client_data['source_info']
        end
        puts
      end

      if recipients.length > 5
        puts "... and #{recipients.length - 5} more recipients"
      end

    rescue ElevenlabsClient::NotFoundError
      puts "❌ Batch job not found: #{sample_batch_id}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Failed to get batch details: #{e.message}"
    end
  end

  def example_cancel_batch_job
    puts "\n4️⃣ Cancel Batch Call Job"
    puts "-" * 25

    sample_batch_id = "batch_active_12345"
    
    begin
      puts "⏹️ Cancelling batch job: #{sample_batch_id}"

      # Simulate cancelling batch job
      cancelled_job = simulate_batch_job_cancellation(sample_batch_id)

      puts "✅ Batch job cancelled successfully!"
      puts "Job ID: #{cancelled_job['id']}"
      puts "Status: #{cancelled_job['status']}"
      puts "Last updated: #{Time.at(cancelled_job['last_updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Total calls that were scheduled: #{cancelled_job['total_calls_scheduled']}"
      puts "Calls that were dispatched before cancellation: #{cancelled_job['total_calls_dispatched']}"

      # Calculate cancellation impact
      cancelled_calls = cancelled_job['total_calls_scheduled'] - cancelled_job['total_calls_dispatched']
      puts "Calls cancelled: #{cancelled_calls}"

    rescue ElevenlabsClient::NotFoundError
      puts "❌ Batch job not found: #{sample_batch_id}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Cancellation failed: #{e.message}"
    end
  end

  def example_retry_batch_job
    puts "\n5️⃣ Retry Batch Call Job"
    puts "-" * 23

    sample_batch_id = "batch_completed_12345"
    
    begin
      puts "🔄 Retrying failed calls in batch job: #{sample_batch_id}"

      # Simulate retrying batch job
      retried_job = simulate_batch_job_retry(sample_batch_id)

      puts "✅ Batch job retry initiated!"
      puts "Job ID: #{retried_job['id']}"
      puts "Status: #{retried_job['status']}"
      puts "Total calls scheduled: #{retried_job['total_calls_scheduled']}"
      puts "Total calls dispatched: #{retried_job['total_calls_dispatched']}"
      puts "Last updated: #{Time.at(retried_job['last_updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"

      # Show retry impact
      retry_count = retried_job['total_calls_scheduled'] - retried_job['total_calls_dispatched']
      puts "Calls queued for retry: #{retry_count}"

    rescue ElevenlabsClient::NotFoundError
      puts "❌ Batch job not found: #{sample_batch_id}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ Retry failed: #{e.message}"
    end
  end

  def example_customer_survey_campaign(agent_id, phone_number_id)
    puts "\n6️⃣ Customer Survey Campaign"
    puts "-" * 30

    # Sample customer data
    survey_customers = [
      {
        customer_id: "cust_001",
        name: "John Smith",
        phone: "+1555123456",
        last_purchase: "Premium Package",
        previous_score: "8/10"
      },
      {
        customer_id: "cust_002",
        name: "Jane Doe",
        phone: "+1555987654",
        last_purchase: "Basic Service",
        previous_score: "9/10"
      },
      {
        customer_id: "cust_003",
        name: "Bob Johnson",
        phone: "+1555555555",
        last_purchase: "Enterprise Solution",
        previous_score: "7/10"
      },
      {
        customer_id: "cust_004",
        name: "Alice Wilson",
        phone: "+1555111111",
        last_purchase: "Standard Package",
        previous_score: "6/10"
      }
    ]

    puts "📋 Creating Customer Satisfaction Survey Campaign"
    puts "Survey participants: #{survey_customers.length}"

    # Prepare enhanced recipients with survey context
    enhanced_recipients = survey_customers.map do |customer|
      {
        phone_number: customer[:phone],
        conversation_initiation_client_data: {
          conversation_config_override: {
            agent: {
              first_message: "Hello #{customer[:name]}! We'd love to get your feedback on our recent service. This will only take a few minutes.",
              language: "en"
            }
          },
          user_id: customer[:customer_id],
          source_info: {
            source: "survey_campaign",
            version: "1.0"
          },
          dynamic_variables: {
            customer_name: customer[:name],
            last_purchase: customer[:last_purchase],
            satisfaction_score: customer[:previous_score]
          }
        }
      }
    end

    # Schedule for optimal time (2 PM today)
    optimal_time = Time.now.beginning_of_day + 14.hours
    if optimal_time < Time.now
      optimal_time += 24.hours # Schedule for tomorrow if past 2 PM
    end

    begin
      puts "⏰ Scheduling campaign for: #{optimal_time.strftime('%Y-%m-%d %H:%M:%S')}"

      # Simulate survey campaign creation
      survey_campaign = simulate_batch_job_creation(
        call_name: "Customer Satisfaction Survey - #{Date.today.strftime('%Y-%m-%d')}",
        agent_id: agent_id,
        agent_phone_number_id: phone_number_id,
        scheduled_time_unix: optimal_time.to_i,
        recipients: enhanced_recipients
      )

      puts "✅ Survey campaign created successfully!"
      puts "Campaign ID: #{survey_campaign['id']}"
      puts "Campaign Name: #{survey_campaign['name']}"
      puts "Total participants: #{survey_campaign['total_calls_scheduled']}"
      puts "Agent: #{survey_campaign['agent_name']}"
      puts "Expected completion: #{(optimal_time + 2.hours).strftime('%Y-%m-%d %H:%M:%S')}"

      # Show campaign insights
      puts "\n📊 Campaign Insights:"
      puts "• Personalized greetings for each customer"
      puts "• Previous satisfaction scores available as context"
      puts "• Purchase history included for reference"
      puts "• Optimal timing for maximum response rate"

    rescue ElevenlabsClient::APIError => e
      puts "❌ Survey campaign creation failed: #{e.message}"
    end
  end

  def example_appointment_reminder_system(agent_id, phone_number_id)
    puts "\n7️⃣ Appointment Reminder System"
    puts "-" * 35

    # Sample appointment data
    appointments = [
      {
        patient_id: "pat_001",
        patient_name: "Alice Wilson",
        phone: "+1555111111",
        appointment_time: "2024-02-15 10:00 AM",
        doctor_name: "Dr. Smith",
        appointment_type: "Annual Check-up",
        location: "Main Clinic",
        confirmation_code: "APT123"
      },
      {
        patient_id: "pat_002",
        patient_name: "Bob Chen",
        phone: "+1555222222",
        appointment_time: "2024-02-15 14:30 PM",
        doctor_name: "Dr. Johnson",
        appointment_type: "Specialist Consultation",
        location: "Specialist Center",
        confirmation_code: "APT456"
      },
      {
        patient_id: "pat_003",
        patient_name: "Carol Davis",
        phone: "+1555333333",
        appointment_time: "2024-02-16 09:15 AM",
        doctor_name: "Dr. Williams",
        appointment_type: "Follow-up",
        location: "Downtown Office",
        confirmation_code: "APT789"
      }
    ]

    puts "📅 Creating Appointment Reminder System"
    puts "Appointments to remind: #{appointments.length}"

    # Group appointments by reminder time (24 hours before)
    reminder_groups = appointments.group_by do |apt|
      appointment_time = Time.parse(apt[:appointment_time])
      reminder_time = appointment_time - 24.hours
      reminder_time.beginning_of_hour
    end

    batch_jobs = []

    puts "\n📞 Scheduling reminder campaigns:"
    reminder_groups.each do |reminder_time, group_appointments|
      puts "\nReminder batch for #{reminder_time.strftime('%Y-%m-%d %H:%M')}"
      puts "Appointments: #{group_appointments.length}"

      # Prepare recipients with appointment details
      recipients = group_appointments.map do |appointment|
        {
          phone_number: appointment[:phone],
          conversation_initiation_client_data: {
            conversation_config_override: {
              agent: {
                first_message: "Hello #{appointment[:patient_name]}! This is a reminder about your appointment tomorrow at #{appointment[:appointment_time]} with #{appointment[:doctor_name]}.",
                language: "en"
              }
            },
            user_id: appointment[:patient_id],
            source_info: {
              source: "appointment_reminder",
              version: "1.0"
            },
            dynamic_variables: {
              patient_name: appointment[:patient_name],
              appointment_time: appointment[:appointment_time],
              doctor_name: appointment[:doctor_name],
              appointment_type: appointment[:appointment_type],
              location: appointment[:location],
              confirmation_code: appointment[:confirmation_code]
            }
          }
        }
      end

      begin
        # Simulate reminder batch creation
        batch_job = simulate_batch_job_creation(
          call_name: "Appointment Reminders - #{reminder_time.strftime('%Y-%m-%d %H:%M')}",
          agent_id: agent_id,
          agent_phone_number_id: phone_number_id,
          scheduled_time_unix: reminder_time.to_i,
          recipients: recipients
        )

        batch_jobs << batch_job
        puts "✅ Reminder batch created: #{batch_job['id']}"
        puts "   Scheduled for: #{Time.at(batch_job['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"

      rescue ElevenlabsClient::APIError => e
        puts "❌ Failed to create reminder batch: #{e.message}"
      end
    end

    puts "\n📊 Appointment Reminder Campaign Summary:"
    puts "Total reminder batches: #{batch_jobs.length}"
    puts "Total reminders: #{appointments.length}"
    puts "Coverage: 24-hour advance notice for all appointments"

    # Show reminder schedule
    puts "\n📅 Reminder Schedule:"
    batch_jobs.each do |job|
      scheduled_time = Time.at(job['scheduled_time_unix'])
      puts "• #{scheduled_time.strftime('%Y-%m-%d %H:%M')}: #{job['total_calls_scheduled']} reminders"
    end
  end

  def example_campaign_monitoring_dashboard
    puts "\n8️⃣ Campaign Monitoring Dashboard"
    puts "-" * 35

    puts "📊 Batch Campaign Monitoring Dashboard"

    # Simulate dashboard data
    dashboard_data = simulate_dashboard_data

    if dashboard_data[:campaigns].empty?
      puts "No batch campaigns found."
      return
    end

    # Campaign overview
    total_campaigns = dashboard_data[:campaigns].length
    campaigns_by_status = dashboard_data[:campaigns].group_by { |c| c[:status] }

    puts "\n📈 Campaign Overview:"
    puts "Total campaigns: #{total_campaigns}"

    campaigns_by_status.each do |status, campaigns|
      percentage = (campaigns.length.to_f / total_campaigns * 100).round(1)
      puts "#{status.capitalize}: #{campaigns.length} (#{percentage}%)"
    end

    # Active campaigns detail
    active_campaigns = campaigns_by_status['in_progress'] || []
    if active_campaigns.any?
      puts "\n🔄 Active Campaigns:"
      active_campaigns.each do |campaign|
        progress_percent = campaign[:total_scheduled] > 0 ? 
          (campaign[:dispatched].to_f / campaign[:total_scheduled] * 100).round(1) : 0

        puts "\n#{campaign[:name]} (#{campaign[:id]})"
        puts "  Progress: #{campaign[:dispatched]}/#{campaign[:total_scheduled]} (#{progress_percent}%)"
        puts "  Agent: #{campaign[:agent_name]}"
        puts "  Provider: #{campaign[:provider]}"
        puts "  Started: #{campaign[:started_at].strftime('%Y-%m-%d %H:%M')}"

        # Show progress bar
        bar_length = 20
        filled_length = (progress_percent / 5).round
        bar = "█" * filled_length + "░" * (bar_length - filled_length)
        puts "  Progress: [#{bar}] #{progress_percent}%"

        # Estimated completion
        if progress_percent > 0 && progress_percent < 100
          elapsed_time = Time.now - campaign[:started_at]
          estimated_total_time = elapsed_time / (progress_percent / 100.0)
          estimated_completion = campaign[:started_at] + estimated_total_time
          puts "  ETA: #{estimated_completion.strftime('%Y-%m-%d %H:%M:%S')}"
        end
      end
    end

    # Recent completions
    completed_campaigns = campaigns_by_status['completed'] || []
    if completed_campaigns.any?
      puts "\n✅ Recently Completed (last 5):"
      completed_campaigns.last(5).each do |campaign|
        success_rate = campaign[:total_scheduled] > 0 ? 
          (campaign[:successful].to_f / campaign[:total_scheduled] * 100).round(1) : 0

        puts "• #{campaign[:name]}: #{success_rate}% success rate"
        puts "  Completed: #{campaign[:completed_at].strftime('%Y-%m-%d %H:%M')}"
      end
    end

    # Campaigns needing attention
    failed_campaigns = campaigns_by_status['failed'] || []
    low_success_campaigns = completed_campaigns.select { |c| 
      c[:total_scheduled] > 0 && (c[:successful].to_f / c[:total_scheduled]) < 0.8 
    }

    if failed_campaigns.any? || low_success_campaigns.any?
      puts "\n⚠️ Campaigns Needing Attention:"
      
      failed_campaigns.each do |campaign|
        puts "❌ #{campaign[:name]}: Failed (#{campaign[:error]})"
      end
      
      low_success_campaigns.each do |campaign|
        success_rate = (campaign[:successful].to_f / campaign[:total_scheduled] * 100).round(1)
        puts "⚠️ #{campaign[:name]}: Low success rate (#{success_rate}%)"
      end
    end

    # Performance summary
    total_calls = dashboard_data[:campaigns].sum { |c| c[:total_scheduled] || 0 }
    total_successful = dashboard_data[:campaigns].sum { |c| c[:successful] || 0 }
    overall_success_rate = total_calls > 0 ? (total_successful.to_f / total_calls * 100).round(1) : 0

    puts "\n📊 Overall Performance:"
    puts "Total calls across all campaigns: #{total_calls}"
    puts "Successful calls: #{total_successful}"
    puts "Overall success rate: #{overall_success_rate}%"
  end

  def example_campaign_analytics
    puts "\n9️⃣ Campaign Performance Analytics"
    puts "-" * 35

    puts "📊 30-Day Campaign Performance Analytics"

    # Simulate analytics data
    analytics_data = simulate_analytics_data

    puts "\n📈 Performance Metrics:"
    puts "Campaigns analyzed: #{analytics_data[:total_campaigns]}"
    puts "Total recipients: #{analytics_data[:total_recipients]}"
    puts "Successful calls: #{analytics_data[:successful_calls]}"
    puts "Overall success rate: #{analytics_data[:overall_success_rate]}%"
    puts "Average campaign success rate: #{analytics_data[:average_success_rate]}%"

    # Agent performance
    puts "\n👥 Agent Performance:"
    analytics_data[:agent_performance].each do |agent_name, stats|
      puts "#{agent_name}:"
      puts "  Campaigns: #{stats[:campaigns]}"
      puts "  Success rate: #{stats[:success_rate]}%"
      puts "  Total calls: #{stats[:total_calls]}"
    end

    # Provider analysis
    puts "\n📞 Provider Analysis:"
    analytics_data[:provider_performance].each do |provider, stats|
      puts "#{provider.upcase}:"
      puts "  Campaigns: #{stats[:campaigns]}"
      puts "  Success rate: #{stats[:success_rate]}%"
      puts "  Market share: #{stats[:market_share]}%"
    end

    # Time-based analysis
    puts "\n⏰ Best Performance Times:"
    analytics_data[:hourly_performance].each do |hour, success_rate|
      puts "#{hour}:00 - #{success_rate}% success rate"
    end

    # Insights and recommendations
    puts "\n💡 Performance Insights:"
    analytics_data[:insights].each do |insight|
      puts "• #{insight}"
    end

    # Trending
    puts "\n📈 Trends:"
    if analytics_data[:success_trend] > 0
      puts "✅ Success rate trending up (+#{analytics_data[:success_trend]}% this month)"
    elsif analytics_data[:success_trend] < 0
      puts "⚠️ Success rate trending down (#{analytics_data[:success_trend]}% this month)"
    else
      puts "➡️ Success rate stable"
    end
  end

  # Helper methods for simulation

  def simulate_batch_job_creation(params)
    {
      'id' => "batch_#{SecureRandom.hex(8)}",
      'phone_number_id' => params[:agent_phone_number_id],
      'name' => params[:call_name],
      'agent_id' => params[:agent_id],
      'created_at_unix' => Time.now.to_i,
      'scheduled_time_unix' => params[:scheduled_time_unix],
      'total_calls_dispatched' => 0,
      'total_calls_scheduled' => params[:recipients].length,
      'last_updated_at_unix' => Time.now.to_i,
      'status' => 'pending',
      'agent_name' => 'Customer Service Agent',
      'phone_provider' => 'twilio'
    }
  end

  def simulate_batch_jobs_list
    {
      'batch_calls' => [
        {
          'id' => 'batch_001',
          'name' => 'Customer Survey Campaign - 2024-01-15',
          'agent_id' => 'agent_survey',
          'agent_name' => 'Survey Agent',
          'created_at_unix' => (Time.now - 2.hours).to_i,
          'scheduled_time_unix' => (Time.now - 1.hour).to_i,
          'total_calls_dispatched' => 45,
          'total_calls_scheduled' => 50,
          'last_updated_at_unix' => (Time.now - 30.minutes).to_i,
          'status' => 'in_progress',
          'phone_provider' => 'twilio'
        },
        {
          'id' => 'batch_002',
          'name' => 'Appointment Reminders - 2024-01-16',
          'agent_id' => 'agent_reminder',
          'agent_name' => 'Reminder Agent',
          'created_at_unix' => (Time.now - 1.day).to_i,
          'scheduled_time_unix' => (Time.now - 22.hours).to_i,
          'total_calls_dispatched' => 25,
          'total_calls_scheduled' => 25,
          'last_updated_at_unix' => (Time.now - 22.hours).to_i,
          'status' => 'completed',
          'phone_provider' => 'sip_trunk'
        },
        {
          'id' => 'batch_003',
          'name' => 'Product Launch Announcement',
          'agent_id' => 'agent_marketing',
          'agent_name' => 'Marketing Agent',
          'created_at_unix' => Time.now.to_i,
          'scheduled_time_unix' => (Time.now + 2.hours).to_i,
          'total_calls_dispatched' => 0,
          'total_calls_scheduled' => 100,
          'last_updated_at_unix' => Time.now.to_i,
          'status' => 'pending',
          'phone_provider' => 'twilio'
        }
      ],
      'next_doc' => 'next_page_token_123',
      'has_more' => false
    }
  end

  def simulate_batch_job_details(batch_id)
    {
      'id' => batch_id,
      'phone_number_id' => 'phone_001',
      'name' => 'Customer Survey Campaign - Sample',
      'agent_id' => 'agent_001',
      'agent_name' => 'Survey Agent',
      'created_at_unix' => (Time.now - 2.hours).to_i,
      'scheduled_time_unix' => (Time.now - 1.hour).to_i,
      'total_calls_dispatched' => 8,
      'total_calls_scheduled' => 10,
      'last_updated_at_unix' => (Time.now - 30.minutes).to_i,
      'status' => 'in_progress',
      'phone_provider' => 'twilio',
      'recipients' => [
        {
          'id' => 'rec_001',
          'phone_number' => '+1555123456',
          'status' => 'completed',
          'created_at_unix' => (Time.now - 2.hours).to_i,
          'updated_at_unix' => (Time.now - 1.hour).to_i,
          'conversation_id' => 'conv_001',
          'conversation_initiation_client_data' => {
            'user_id' => 'user_001',
            'source_info' => { 'source' => 'survey_campaign' }
          }
        },
        {
          'id' => 'rec_002',
          'phone_number' => '+1555987654',
          'status' => 'failed',
          'created_at_unix' => (Time.now - 2.hours).to_i,
          'updated_at_unix' => (Time.now - 1.hour).to_i,
          'conversation_id' => nil
        },
        {
          'id' => 'rec_003',
          'phone_number' => '+1555111222',
          'status' => 'completed',
          'created_at_unix' => (Time.now - 2.hours).to_i,
          'updated_at_unix' => (Time.now - 45.minutes).to_i,
          'conversation_id' => 'conv_003'
        }
      ]
    }
  end

  def simulate_batch_job_cancellation(batch_id)
    {
      'id' => batch_id,
      'phone_number_id' => 'phone_001',
      'name' => 'Marketing Campaign - Cancelled',
      'agent_id' => 'agent_001',
      'created_at_unix' => (Time.now - 1.hour).to_i,
      'scheduled_time_unix' => Time.now.to_i,
      'total_calls_dispatched' => 25,
      'total_calls_scheduled' => 100,
      'last_updated_at_unix' => Time.now.to_i,
      'status' => 'cancelled',
      'agent_name' => 'Marketing Agent',
      'phone_provider' => 'twilio'
    }
  end

  def simulate_batch_job_retry(batch_id)
    {
      'id' => batch_id,
      'phone_number_id' => 'phone_001',
      'name' => 'Customer Survey - Retry',
      'agent_id' => 'agent_001',
      'created_at_unix' => (Time.now - 3.hours).to_i,
      'scheduled_time_unix' => (Time.now - 2.hours).to_i,
      'total_calls_dispatched' => 15,
      'total_calls_scheduled' => 50,
      'last_updated_at_unix' => Time.now.to_i,
      'status' => 'in_progress',
      'agent_name' => 'Survey Agent',
      'phone_provider' => 'twilio'
    }
  end

  def simulate_dashboard_data
    {
      campaigns: [
        {
          id: 'batch_001',
          name: 'Customer Survey Q1',
          status: 'in_progress',
          agent_name: 'Survey Agent',
          provider: 'twilio',
          total_scheduled: 100,
          dispatched: 75,
          successful: 65,
          started_at: Time.now - 2.hours
        },
        {
          id: 'batch_002',
          name: 'Appointment Reminders',
          status: 'completed',
          agent_name: 'Reminder Agent',
          provider: 'sip',
          total_scheduled: 50,
          dispatched: 50,
          successful: 48,
          started_at: Time.now - 1.day,
          completed_at: Time.now - 20.hours
        },
        {
          id: 'batch_003',
          name: 'Product Launch',
          status: 'failed',
          agent_name: 'Marketing Agent',
          provider: 'twilio',
          total_scheduled: 200,
          dispatched: 25,
          successful: 20,
          error: 'API rate limit exceeded'
        }
      ]
    }
  end

  def simulate_analytics_data
    {
      total_campaigns: 15,
      total_recipients: 1250,
      successful_calls: 1075,
      overall_success_rate: 86.0,
      average_success_rate: 84.5,
      agent_performance: {
        'Survey Agent' => { campaigns: 5, success_rate: 88.5, total_calls: 400 },
        'Reminder Agent' => { campaigns: 6, success_rate: 92.1, total_calls: 350 },
        'Marketing Agent' => { campaigns: 4, success_rate: 78.3, total_calls: 500 }
      },
      provider_performance: {
        'twilio' => { campaigns: 9, success_rate: 85.2, market_share: 60 },
        'sip' => { campaigns: 6, success_rate: 87.8, market_share: 40 }
      },
      hourly_performance: {
        '10' => 89.2,
        '14' => 92.5,
        '16' => 87.1,
        '18' => 83.4
      },
      insights: [
        'Peak performance at 2 PM (92.5% success rate)',
        'SIP trunk shows 2.6% higher success rate than Twilio',
        'Reminder campaigns have highest success rate (92.1%)',
        'Consider avoiding calls after 6 PM (83.4% success rate)'
      ],
      success_trend: 2.3
    }
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  controller = BatchCallingController.new
  controller.run_examples
end
