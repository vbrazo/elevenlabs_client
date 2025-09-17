# Batch Calling

The batch calling endpoints allow you to schedule and manage bulk calling campaigns for multiple recipients using your conversational AI agents.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
batch_calling = client.batch_calling
```

## Available Methods

### Submit Batch Call Job

Schedule a batch call campaign for multiple recipients.

```ruby
recipients = [
  { phone_number: "+1234567890" },
  { phone_number: "+1987654321" },
  { phone_number: "+1555123456" }
]

batch_job = client.batch_calling.submit(
  call_name: "Customer Survey Campaign",
  agent_id: "agent_id_here",
  agent_phone_number_id: "phone_number_id_here",
  scheduled_time_unix: Time.now.to_i + 3600, # Schedule for 1 hour from now
  recipients: recipients
)

puts "Batch job created: #{batch_job['id']}"
puts "Total calls scheduled: #{batch_job['total_calls_scheduled']}"
puts "Status: #{batch_job['status']}"
puts "Agent: #{batch_job['agent_name']}"
puts "Phone Provider: #{batch_job['phone_provider']}"
```

### List Batch Call Jobs

Retrieve all batch calling jobs for your workspace.

```ruby
# List all batch jobs
batch_jobs = client.batch_calling.list

batch_jobs['batch_calls'].each do |job|
  puts "#{job['id']}: #{job['name']}"
  puts "  Agent: #{job['agent_name']}"
  puts "  Status: #{job['status']}"
  puts "  Scheduled: #{Time.at(job['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
  puts "  Progress: #{job['total_calls_dispatched']}/#{job['total_calls_scheduled']}"
  puts
end

# List with pagination
paginated_jobs = client.batch_calling.list(
  limit: 50,
  last_doc: "last_document_id_from_previous_request"
)

if paginated_jobs['has_more']
  puts "More jobs available. Next cursor: #{paginated_jobs['next_doc']}"
end
```

### Get Batch Call Details

Retrieve detailed information about a specific batch job, including all recipients.

```ruby
batch_details = client.batch_calling.get("batch_job_id_here")

puts "Batch Job Details:"
puts "Name: #{batch_details['name']}"
puts "Agent: #{batch_details['agent_name']} (#{batch_details['agent_id']})"
puts "Phone Provider: #{batch_details['phone_provider']}"
puts "Status: #{batch_details['status']}"
puts "Created: #{Time.at(batch_details['created_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
puts "Scheduled: #{Time.at(batch_details['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
puts "Total Recipients: #{batch_details['recipients'].length}"

# Analyze recipient status
recipient_stats = batch_details['recipients'].group_by { |r| r['status'] }
recipient_stats.each do |status, recipients|
  puts "#{status.capitalize}: #{recipients.length}"
end

# Show detailed recipient information
puts "\nRecipient Details:"
batch_details['recipients'].each_with_index do |recipient, index|
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
```

### Cancel Batch Call Job

Cancel a running batch call job and stop all pending calls.

```ruby
cancelled_job = client.batch_calling.cancel("batch_job_id_here")

puts "Batch job cancelled: #{cancelled_job['id']}"
puts "Status: #{cancelled_job['status']}"
puts "Last updated: #{Time.at(cancelled_job['last_updated_at_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
```

### Retry Batch Call Job

Retry failed and no-response recipients in a batch job.

```ruby
retried_job = client.batch_calling.retry("batch_job_id_here")

puts "Batch job retry initiated: #{retried_job['id']}"
puts "Status: #{retried_job['status']}"
puts "Total calls scheduled: #{retried_job['total_calls_scheduled']}"
puts "Total calls dispatched: #{retried_job['total_calls_dispatched']}"
```

## Examples

### Customer Survey Campaign

```ruby
def create_customer_survey_campaign(survey_recipients, agent_id, phone_number_id)
  puts "📋 Creating Customer Survey Campaign"
  puts "=" * 40
  
  # Prepare recipients with enhanced data
  enhanced_recipients = survey_recipients.map do |customer|
    {
      phone_number: customer[:phone],
      conversation_initiation_client_data: {
        conversation_config_override: {
          agent: {
            first_message: "Hello #{customer[:name]}! We'd love to get your feedback on our recent service.",
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
  
  # Schedule campaign for optimal time (e.g., 2 PM today)
  scheduled_time = Time.now.beginning_of_day + 14.hours
  
  batch_job = client.batch_calling.submit(
    call_name: "Customer Satisfaction Survey - #{Date.today.strftime('%Y-%m-%d')}",
    agent_id: agent_id,
    agent_phone_number_id: phone_number_id,
    scheduled_time_unix: scheduled_time.to_i,
    recipients: enhanced_recipients
  )
  
  puts "✅ Survey campaign created!"
  puts "Campaign ID: #{batch_job['id']}"
  puts "Total recipients: #{batch_job['total_calls_scheduled']}"
  puts "Scheduled for: #{Time.at(batch_job['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M:%S')}"
  puts "Agent: #{batch_job['agent_name']}"
  
  batch_job
end

# Usage
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
  }
]

survey_campaign = create_customer_survey_campaign(
  survey_customers,
  "survey_agent_id",
  "survey_phone_id"
)
```

### Appointment Reminder System

```ruby
def create_appointment_reminders(appointments, agent_id, phone_number_id)
  puts "📅 Creating Appointment Reminder Campaign"
  puts "=" * 45
  
  # Group appointments by reminder time (24 hours before)
  reminder_groups = appointments.group_by do |apt|
    (Time.parse(apt[:appointment_time]) - 24.hours).beginning_of_hour
  end
  
  batch_jobs = []
  
  reminder_groups.each do |reminder_time, group_appointments|
    puts "\nScheduling reminders for #{reminder_time.strftime('%Y-%m-%d %H:%M')}"
    puts "Appointments: #{group_appointments.length}"
    
    # Prepare recipients with appointment details
    recipients = group_appointments.map do |appointment|
      {
        phone_number: appointment[:phone],
        conversation_initiation_client_data: {
          conversation_config_override: {
            agent: {
              first_message: "Hello #{appointment[:patient_name]}! This is a reminder about your appointment tomorrow at #{appointment[:appointment_time]}.",
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
    
    batch_job = client.batch_calling.submit(
      call_name: "Appointment Reminders - #{reminder_time.strftime('%Y-%m-%d %H:%M')}",
      agent_id: agent_id,
      agent_phone_number_id: phone_number_id,
      scheduled_time_unix: reminder_time.to_i,
      recipients: recipients
    )
    
    batch_jobs << batch_job
    puts "✅ Reminder batch created: #{batch_job['id']}"
  end
  
  puts "\n📊 Reminder Campaign Summary:"
  puts "Total batches: #{batch_jobs.length}"
  puts "Total reminders: #{appointments.length}"
  
  batch_jobs
end

# Usage
appointments = [
  {
    patient_id: "pat_001",
    patient_name: "Alice Wilson",
    phone: "+1555111111",
    appointment_time: "2024-02-15 10:00 AM",
    doctor_name: "Dr. Smith",
    appointment_type: "Check-up",
    location: "Main Clinic",
    confirmation_code: "APT123"
  },
  {
    patient_id: "pat_002",
    patient_name: "Bob Chen",
    phone: "+1555222222",
    appointment_time: "2024-02-15 14:30 PM",
    doctor_name: "Dr. Johnson",
    appointment_type: "Consultation",
    location: "Specialist Center",
    confirmation_code: "APT456"
  }
]

reminder_campaigns = create_appointment_reminders(
  appointments,
  "reminder_agent_id",
  "reminder_phone_id"
)
```

### Campaign Monitoring and Management

```ruby
def monitor_batch_campaigns
  puts "📊 Batch Campaign Monitoring Dashboard"
  puts "=" * 45
  
  # Get all batch jobs
  all_jobs = client.batch_calling.list(limit: 100)
  
  if all_jobs['batch_calls'].empty?
    puts "No batch campaigns found."
    return
  end
  
  # Categorize jobs by status
  jobs_by_status = all_jobs['batch_calls'].group_by { |job| job['status'] }
  
  puts "\n📈 Campaign Overview:"
  puts "Total campaigns: #{all_jobs['batch_calls'].length}"
  
  jobs_by_status.each do |status, jobs|
    puts "#{status.capitalize}: #{jobs.length}"
  end
  
  # Analyze active campaigns
  active_jobs = jobs_by_status['in_progress'] || []
  
  if active_jobs.any?
    puts "\n🔄 Active Campaigns:"
    active_jobs.each do |job|
      progress_percent = job['total_calls_scheduled'] > 0 ? 
        (job['total_calls_dispatched'].to_f / job['total_calls_scheduled'] * 100).round(1) : 0
      
      puts "\n#{job['name']} (#{job['id']})"
      puts "  Agent: #{job['agent_name']}"
      puts "  Progress: #{job['total_calls_dispatched']}/#{job['total_calls_scheduled']} (#{progress_percent}%)"
      puts "  Provider: #{job['phone_provider']}"
      puts "  Scheduled: #{Time.at(job['scheduled_time_unix']).strftime('%Y-%m-%d %H:%M')}"
      
      # Get detailed information for more analysis
      begin
        details = client.batch_calling.get(job['id'])
        recipient_stats = details['recipients'].group_by { |r| r['status'] }
        
        puts "  Recipient Status:"
        recipient_stats.each do |status, recipients|
          puts "    #{status}: #{recipients.length}"
        end
        
        # Check if any calls failed and suggest retry
        failed_count = (recipient_stats['failed'] || []).length + (recipient_stats['no_response'] || []).length
        if failed_count > 0
          puts "  ⚠️ #{failed_count} calls need retry"
        end
        
      rescue => e
        puts "  ❌ Could not get detailed info: #{e.message}"
      end
    end
  end
  
  # Check for campaigns that need attention
  puts "\n⚠️ Campaigns Needing Attention:"
  
  # Failed campaigns
  failed_jobs = jobs_by_status['failed'] || []
  if failed_jobs.any?
    puts "Failed Campaigns (#{failed_jobs.length}):"
    failed_jobs.each do |job|
      puts "  - #{job['name']} (#{job['id']})"
    end
  end
  
  # Completed campaigns with high failure rates
  completed_jobs = jobs_by_status['completed'] || []
  completed_jobs.each do |job|
    begin
      details = client.batch_calling.get(job['id'])
      total_recipients = details['recipients'].length
      successful_calls = details['recipients'].count { |r| r['status'] == 'completed' }
      success_rate = total_recipients > 0 ? (successful_calls.to_f / total_recipients * 100).round(1) : 0
      
      if success_rate < 80
        puts "  - #{job['name']}: Low success rate (#{success_rate}%)"
      end
    rescue
      # Skip if we can't get details
    end
  end
  
  all_jobs
end

def manage_campaign_retries
  puts "🔄 Managing Campaign Retries"
  puts "=" * 30
  
  # Get all campaigns
  campaigns = client.batch_calling.list
  
  campaigns['batch_calls'].each do |campaign|
    next unless campaign['status'] == 'completed'
    
    begin
      details = client.batch_calling.get(campaign['id'])
      
      # Check for failed or no-response calls
      failed_recipients = details['recipients'].select do |r|
        ['failed', 'no_response'].include?(r['status'])
      end
      
      if failed_recipients.length > 0
        retry_percentage = (failed_recipients.length.to_f / details['recipients'].length * 100).round(1)
        
        puts "\n#{campaign['name']}:"
        puts "  Failed/No Response: #{failed_recipients.length}/#{details['recipients'].length} (#{retry_percentage}%)"
        
        if retry_percentage > 10 # Only retry if more than 10% failed
          puts "  🔄 Initiating retry..."
          
          retry_result = client.batch_calling.retry(campaign['id'])
          puts "  ✅ Retry initiated: #{retry_result['status']}"
          
          sleep(1) # Rate limiting
        else
          puts "  ✅ Failure rate acceptable, no retry needed"
        end
      end
      
    rescue => e
      puts "❌ Error processing campaign #{campaign['id']}: #{e.message}"
    end
  end
end

# Usage
monitor_batch_campaigns
manage_campaign_retries
```

### Advanced Campaign Analytics

```ruby
def analyze_campaign_performance(time_period_days = 30)
  puts "📊 Campaign Performance Analytics"
  puts "=" * 40
  puts "Period: Last #{time_period_days} days"
  
  # Get all campaigns
  all_campaigns = client.batch_calling.list(limit: 100)
  
  # Filter campaigns from the specified time period
  cutoff_time = Time.now - (time_period_days * 24 * 3600)
  recent_campaigns = all_campaigns['batch_calls'].select do |campaign|
    Time.at(campaign['created_at_unix']) >= cutoff_time
  end
  
  if recent_campaigns.empty?
    puts "No campaigns found in the specified period."
    return
  end
  
  puts "\n📈 Overall Statistics:"
  puts "Total campaigns: #{recent_campaigns.length}"
  
  # Analyze campaign details
  detailed_stats = {
    total_recipients: 0,
    total_successful: 0,
    total_failed: 0,
    campaigns_by_agent: Hash.new(0),
    campaigns_by_provider: Hash.new(0),
    campaigns_by_status: Hash.new(0),
    success_rates: []
  }
  
  recent_campaigns.each do |campaign|
    detailed_stats[:campaigns_by_agent][campaign['agent_name']] += 1
    detailed_stats[:campaigns_by_provider][campaign['phone_provider']] += 1
    detailed_stats[:campaigns_by_status][campaign['status']] += 1
    
    # Get detailed recipient information
    begin
      details = client.batch_calling.get(campaign['id'])
      
      total_recipients = details['recipients'].length
      successful_recipients = details['recipients'].count { |r| r['status'] == 'completed' }
      failed_recipients = total_recipients - successful_recipients
      
      detailed_stats[:total_recipients] += total_recipients
      detailed_stats[:total_successful] += successful_recipients
      detailed_stats[:total_failed] += failed_recipients
      
      if total_recipients > 0
        success_rate = (successful_recipients.to_f / total_recipients * 100).round(1)
        detailed_stats[:success_rates] << success_rate
      end
      
    rescue => e
      puts "⚠️ Could not analyze campaign #{campaign['id']}: #{e.message}"
    end
  end
  
  # Calculate overall metrics
  overall_success_rate = detailed_stats[:total_recipients] > 0 ? 
    (detailed_stats[:total_successful].to_f / detailed_stats[:total_recipients] * 100).round(1) : 0
  
  average_success_rate = detailed_stats[:success_rates].any? ? 
    (detailed_stats[:success_rates].sum / detailed_stats[:success_rates].length).round(1) : 0
  
  puts "Total recipients: #{detailed_stats[:total_recipients]}"
  puts "Successful calls: #{detailed_stats[:total_successful]}"
  puts "Failed calls: #{detailed_stats[:total_failed]}"
  puts "Overall success rate: #{overall_success_rate}%"
  puts "Average campaign success rate: #{average_success_rate}%"
  
  # Agent performance
  puts "\n👥 Agent Performance:"
  detailed_stats[:campaigns_by_agent].sort_by { |_, count| -count }.each do |agent, count|
    puts "  #{agent}: #{count} campaigns"
  end
  
  # Provider performance
  puts "\n📞 Provider Distribution:"
  detailed_stats[:campaigns_by_provider].each do |provider, count|
    percentage = (count.to_f / recent_campaigns.length * 100).round(1)
    puts "  #{provider}: #{count} campaigns (#{percentage}%)"
  end
  
  # Campaign status distribution
  puts "\n📊 Campaign Status:"
  detailed_stats[:campaigns_by_status].each do |status, count|
    percentage = (count.to_f / recent_campaigns.length * 100).round(1)
    puts "  #{status}: #{count} campaigns (#{percentage}%)"
  end
  
  # Performance insights
  puts "\n💡 Performance Insights:"
  
  if overall_success_rate >= 90
    puts "✅ Excellent overall success rate!"
  elsif overall_success_rate >= 80
    puts "✅ Good overall success rate"
  elsif overall_success_rate >= 70
    puts "⚠️ Moderate success rate - consider optimizing"
  else
    puts "❌ Low success rate - immediate optimization needed"
  end
  
  # Success rate distribution
  if detailed_stats[:success_rates].any?
    min_rate = detailed_stats[:success_rates].min
    max_rate = detailed_stats[:success_rates].max
    puts "Success rate range: #{min_rate}% - #{max_rate}%"
    
    poor_campaigns = detailed_stats[:success_rates].count { |rate| rate < 70 }
    if poor_campaigns > 0
      puts "⚠️ #{poor_campaigns} campaigns with success rate < 70%"
    end
  end
  
  detailed_stats
end

# Usage
performance_report = analyze_campaign_performance(30)
```

## Error Handling

```ruby
begin
  batch_job = client.batch_calling.submit(
    call_name: "Test Campaign",
    agent_id: "agent_id",
    agent_phone_number_id: "phone_id",
    scheduled_time_unix: Time.now.to_i,
    recipients: []
  )
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid campaign parameters: #{e.message}"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "Campaign submission failed: #{e.message}"
end
```

## Best Practices

### Campaign Planning

1. **Optimal Timing**: Schedule campaigns for times when recipients are likely to answer
2. **Recipient Segmentation**: Group recipients by demographics, time zones, or preferences
3. **Message Personalization**: Use dynamic variables to personalize conversations
4. **Compliance**: Ensure campaigns comply with local calling regulations and opt-out requirements

### Campaign Management

1. **Monitoring**: Regularly monitor campaign progress and success rates
2. **Retry Strategy**: Implement intelligent retry logic for failed calls
3. **Load Balancing**: Distribute large campaigns across multiple time slots
4. **Quality Control**: Test campaigns with small groups before full deployment

### Performance Optimization

1. **Success Rate Tracking**: Monitor and analyze campaign success rates
2. **Provider Selection**: Choose optimal providers based on destination and quality
3. **Agent Optimization**: Use well-trained agents for better conversation outcomes
4. **Feedback Integration**: Collect and analyze conversation feedback for improvements

### Scalability

1. **Batch Size Management**: Break large recipient lists into manageable batches
2. **Resource Planning**: Ensure adequate phone number and agent capacity
3. **Rate Limiting**: Respect provider rate limits and API constraints
4. **Error Recovery**: Implement robust error handling and recovery mechanisms

## API Reference

For detailed API documentation, visit: [ElevenLabs Batch Calling API Reference](https://elevenlabs.io/docs/api-reference/convai/batch-calling)
