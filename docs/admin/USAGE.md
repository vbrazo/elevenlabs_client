# Admin Usage API

The Admin Usage API allows you to retrieve character usage metrics for your account or workspace, providing detailed insights into your API consumption patterns.

## Available Methods

- `client.usage.get_character_stats(start_unix:, end_unix:, **options)` - Get character usage metrics

### Alias Methods

- `client.usage.character_stats(start_unix:, end_unix:, **options)` - Alias for `get_character_stats`

## Usage Examples

### Basic Usage Statistics

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Get usage stats for the last 30 days
end_time = Time.now.to_i * 1000  # Convert to milliseconds
start_time = (Time.now - 30 * 24 * 60 * 60).to_i * 1000

usage_stats = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time
)

puts "Usage data points: #{usage_stats['time'].length}"
puts "Total usage categories: #{usage_stats['usage'].keys.length}"

# Display usage by day
usage_stats['time'].each_with_index do |timestamp, index|
  date = Time.at(timestamp / 1000).strftime("%Y-%m-%d")
  total_chars = usage_stats['usage']['All'][index]
  puts "#{date}: #{total_chars} characters"
end
```

### Workspace Usage Metrics

```ruby
# Include workspace-wide metrics
workspace_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  include_workspace_metrics: true
)

puts "Personal usage vs Workspace usage:"
workspace_usage['time'].each_with_index do |timestamp, index|
  date = Time.at(timestamp / 1000).strftime("%Y-%m-%d")
  personal = workspace_usage['usage']['Personal']&.[](index) || 0
  workspace = workspace_usage['usage']['Workspace']&.[](index) || 0
  puts "#{date}: Personal: #{personal}, Workspace: #{workspace}"
end
```

### Usage by Voice Breakdown

```ruby
# Get usage broken down by voice
voice_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  breakdown_type: "voice"
)

puts "Usage by voice:"
voice_usage['usage'].each do |voice_name, usage_data|
  total_usage = usage_data.sum
  puts "#{voice_name}: #{total_usage} characters"
end

# Find most used voice
most_used_voice = voice_usage['usage'].max_by { |_, usage_data| usage_data.sum }
puts "Most used voice: #{most_used_voice[0]} (#{most_used_voice[1].sum} characters)"
```

### Usage by Model Breakdown

```ruby
# Get usage broken down by model
model_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  breakdown_type: "model"
)

puts "Usage by model:"
model_usage['usage'].each do |model_id, usage_data|
  total_usage = usage_data.sum
  puts "#{model_id}: #{total_usage} characters"
end
```

### Hourly Usage Analysis

```ruby
# Get hourly usage data
hourly_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_interval: "hour"
)

puts "Hourly usage pattern:"
hourly_usage['time'].each_with_index do |timestamp, index|
  datetime = Time.at(timestamp / 1000).strftime("%Y-%m-%d %H:%M")
  chars = hourly_usage['usage']['All'][index]
  puts "#{datetime}: #{chars} characters"
end
```

### Weekly Usage Trends

```ruby
# Get weekly aggregated data
weekly_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_interval: "week"
)

puts "Weekly usage trends:"
weekly_usage['time'].each_with_index do |timestamp, index|
  week_start = Time.at(timestamp / 1000).strftime("%Y-%m-%d")
  chars = weekly_usage['usage']['All'][index]
  puts "Week of #{week_start}: #{chars} characters"
end
```

### Custom Aggregation Bucket

```ruby
# Use custom aggregation bucket (6 hours = 21600 seconds)
custom_usage = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_bucket_size: 21600
)

puts "Usage in 6-hour buckets:"
custom_usage['time'].each_with_index do |timestamp, index|
  datetime = Time.at(timestamp / 1000).strftime("%Y-%m-%d %H:%M")
  chars = custom_usage['usage']['All'][index]
  puts "#{datetime}: #{chars} characters"
end
```

## Methods

### `get_character_stats(start_unix:, end_unix:, **options)`

Retrieves character usage metrics for the specified time period with various breakdown and aggregation options.

**Required Parameters:**
- **start_unix** (Integer): UTC Unix timestamp for the start of the usage window (in milliseconds). Should be at 00:00:00 of the first day to include the full day.
- **end_unix** (Integer): UTC Unix timestamp for the end of the usage window (in milliseconds). Should be at 23:59:59 of the last day to include the full day.

**Optional Parameters:**
- **include_workspace_metrics** (Boolean): Whether to include statistics for the entire workspace (default: false)
- **breakdown_type** (String): How to break down the information. Options:
  - `"voice"` - Break down by voice
  - `"model"` - Break down by model
  - `"user"` - Break down by user (only available when `include_workspace_metrics` is true)
  - `"source"` - Break down by source
  - `"request_origin"` - Break down by request origin
  - `"language"` - Break down by language
  - And more...
- **aggregation_interval** (String): How to aggregate usage data over time. Options:
  - `"hour"` - Hourly aggregation
  - `"day"` - Daily aggregation (default)
  - `"week"` - Weekly aggregation
  - `"month"` - Monthly aggregation
  - `"cumulative"` - Cumulative totals
- **aggregation_bucket_size** (Integer): Custom aggregation bucket size in seconds. Overrides `aggregation_interval`
- **metric** (String): Which metric to aggregate. Options include:
  - `"character_count"` - Character count (default)
  - `"request_count"` - Request count
  - And more...

**Returns:** Hash containing time axis and usage breakdown

## Response Structure

### Usage Stats Response

```ruby
{
  "time" => [
    1738252091000,  # Unix timestamp in milliseconds
    1739404800000
  ],
  "usage" => {
    "All" => [
      49,    # Usage for first time period
      1053   # Usage for second time period
    ]
  }
}
```

### Voice Breakdown Response

```ruby
{
  "time" => [1738252091000, 1739404800000],
  "usage" => {
    "Rachel" => [25, 500],
    "Josh" => [24, 553],
    "Custom Voice" => [0, 0]
  }
}
```

### Model Breakdown Response

```ruby
{
  "time" => [1738252091000, 1739404800000],
  "usage" => {
    "eleven_multilingual_v2" => [30, 800],
    "eleven_monolingual_v1" => [19, 253],
    "eleven_turbo_v2" => [0, 0]
  }
}
```

## Time Periods and Aggregation

### Setting Up Time Ranges

```ruby
# Last 24 hours
end_time = Time.now.to_i * 1000
start_time = (Time.now - 24 * 60 * 60).to_i * 1000

# Last 7 days (start at beginning of week)
end_time = Time.now.end_of_day.to_i * 1000
start_time = (Time.now - 7.days).beginning_of_day.to_i * 1000

# Current month
start_time = Time.now.beginning_of_month.to_i * 1000
end_time = Time.now.end_of_month.to_i * 1000

# Previous month
last_month = Time.now - 1.month
start_time = last_month.beginning_of_month.to_i * 1000
end_time = last_month.end_of_month.to_i * 1000
```

### Aggregation Examples

```ruby
# Daily aggregation (default)
daily_stats = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_interval: "day"
)

# Hourly aggregation for detailed analysis
hourly_stats = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_interval: "hour"
)

# Weekly aggregation for trends
weekly_stats = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_interval: "week"
)

# Custom 4-hour buckets
custom_stats = client.usage.get_character_stats(
  start_unix: start_time,
  end_unix: end_time,
  aggregation_bucket_size: 14400  # 4 hours in seconds
)
```

## Advanced Usage Analytics

### Usage Trend Analysis

```ruby
def analyze_usage_trends(days: 30)
  end_time = Time.now.to_i * 1000
  start_time = (Time.now - days * 24 * 60 * 60).to_i * 1000
  
  usage_stats = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    aggregation_interval: "day"
  )
  
  daily_usage = usage_stats['usage']['All']
  
  # Calculate statistics
  total_usage = daily_usage.sum
  avg_daily = total_usage.to_f / daily_usage.length
  max_daily = daily_usage.max
  min_daily = daily_usage.min
  
  puts "Usage Analysis (#{days} days):"
  puts "Total characters: #{total_usage}"
  puts "Average daily: #{avg_daily.round(2)}"
  puts "Peak daily: #{max_daily}"
  puts "Minimum daily: #{min_daily}"
  
  # Find peak usage day
  peak_index = daily_usage.index(max_daily)
  peak_date = Time.at(usage_stats['time'][peak_index] / 1000).strftime("%Y-%m-%d")
  puts "Peak usage day: #{peak_date}"
  
  usage_stats
end
```

### Voice Usage Comparison

```ruby
def compare_voice_usage(days: 30)
  end_time = Time.now.to_i * 1000
  start_time = (Time.now - days * 24 * 60 * 60).to_i * 1000
  
  voice_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    breakdown_type: "voice"
  )
  
  # Calculate total usage per voice
  voice_totals = voice_usage['usage'].map do |voice_name, usage_data|
    [voice_name, usage_data.sum]
  end.sort_by { |_, total| -total }  # Sort by usage descending
  
  puts "Voice Usage Ranking:"
  voice_totals.each_with_index do |(voice, total), index|
    percentage = (total.to_f / voice_totals.sum { |_, t| t } * 100).round(1)
    puts "#{index + 1}. #{voice}: #{total} chars (#{percentage}%)"
  end
  
  voice_totals
end
```

### Model Performance Analysis

```ruby
def analyze_model_performance(days: 30)
  end_time = Time.now.to_i * 1000
  start_time = (Time.now - days * 24 * 60 * 60).to_i * 1000
  
  model_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    breakdown_type: "model"
  )
  
  puts "Model Usage Analysis:"
  model_usage['usage'].each do |model_id, usage_data|
    total_chars = usage_data.sum
    avg_daily = total_chars.to_f / usage_data.length
    
    puts "#{model_id}:"
    puts "  Total: #{total_chars} characters"
    puts "  Daily average: #{avg_daily.round(2)} characters"
    puts "  Peak day: #{usage_data.max} characters"
    puts
  end
end
```

### Cost Estimation

```ruby
def estimate_costs(days: 30)
  end_time = Time.now.to_i * 1000
  start_time = (Time.now - days * 24 * 60 * 60).to_i * 1000
  
  # Get usage by model for cost calculation
  model_usage = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    breakdown_type: "model"
  )
  
  # Example cost factors (adjust based on your plan)
  cost_factors = {
    "eleven_multilingual_v2" => 1.0,
    "eleven_monolingual_v1" => 1.0,
    "eleven_turbo_v2" => 0.3,
    "eleven_multilingual_v1" => 1.0
  }
  
  total_cost_units = 0
  
  puts "Cost Estimation:"
  model_usage['usage'].each do |model_id, usage_data|
    total_chars = usage_data.sum
    cost_factor = cost_factors[model_id] || 1.0
    cost_units = total_chars * cost_factor
    total_cost_units += cost_units
    
    puts "#{model_id}: #{total_chars} chars × #{cost_factor} = #{cost_units.round(2)} cost units"
  end
  
  puts "Total estimated cost units: #{total_cost_units.round(2)}"
  total_cost_units
end
```

## Error Handling

```ruby
begin
  usage_stats = client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time
  )
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid parameters: #{e.message}"
  # Common issues:
  # - Invalid date range (end_unix must be after start_unix)
  # - Dates too far in the past
  # - Invalid breakdown_type or aggregation_interval
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Rails Integration Example

```ruby
class UsageController < ApplicationController
  before_action :initialize_client
  
  def dashboard
    @period = params[:period] || '30'
    days = @period.to_i
    
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    @daily_usage = @client.usage.get_character_stats(
      start_unix: start_time,
      end_unix: end_time,
      aggregation_interval: "day"
    )
    
    @voice_breakdown = @client.usage.get_character_stats(
      start_unix: start_time,
      end_unix: end_time,
      breakdown_type: "voice"
    )
    
    @model_breakdown = @client.usage.get_character_stats(
      start_unix: start_time,
      end_unix: end_time,
      breakdown_type: "model"
    )
    
  rescue ElevenlabsClient::APIError => e
    flash[:error] = "Unable to load usage data: #{e.message}"
    @daily_usage = { 'time' => [], 'usage' => {} }
    @voice_breakdown = { 'time' => [], 'usage' => {} }
    @model_breakdown = { 'time' => [], 'usage' => {} }
  end
  
  def export_csv
    days = params[:days]&.to_i || 30
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    usage_stats = @client.usage.get_character_stats(
      start_unix: start_time,
      end_unix: end_time,
      aggregation_interval: "day"
    )
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Date", "Characters Used"]
      
      usage_stats['time'].each_with_index do |timestamp, index|
        date = Time.at(timestamp / 1000).strftime("%Y-%m-%d")
        chars = usage_stats['usage']['All'][index]
        csv << [date, chars]
      end
    end
    
    send_data csv_data,
              type: "text/csv",
              filename: "usage_report_#{Date.current}.csv",
              disposition: "attachment"
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
end
```

## Best Practices

### Efficient Data Retrieval

```ruby
# Use appropriate time ranges
def get_monthly_usage(year, month)
  start_time = Time.new(year, month, 1).beginning_of_month.to_i * 1000
  end_time = Time.new(year, month, 1).end_of_month.to_i * 1000
  
  client.usage.get_character_stats(
    start_unix: start_time,
    end_unix: end_time,
    aggregation_interval: "day"
  )
end

# Cache expensive queries
def cached_usage_stats(cache_key, **options)
  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    client.usage.get_character_stats(**options)
  end
end
```

### Data Visualization Preparation

```ruby
def prepare_chart_data(usage_stats)
  {
    labels: usage_stats['time'].map { |ts| Time.at(ts / 1000).strftime("%Y-%m-%d") },
    datasets: usage_stats['usage'].map do |category, data|
      {
        label: category,
        data: data,
        borderColor: generate_color(category),
        backgroundColor: generate_color(category, 0.2)
      }
    end
  }
end

def generate_color(category, opacity = 1)
  # Generate consistent colors based on category name
  hash = category.hash.abs
  r = (hash % 256)
  g = ((hash / 256) % 256)
  b = ((hash / 65536) % 256)
  
  if opacity < 1
    "rgba(#{r}, #{g}, #{b}, #{opacity})"
  else
    "rgb(#{r}, #{g}, #{b})"
  end
end
```

## Use Cases

### Business Intelligence
- **Usage Trends** - Track usage patterns over time
- **Cost Analysis** - Estimate costs based on model usage
- **Voice Performance** - Compare voice usage and effectiveness
- **Capacity Planning** - Predict future usage needs

### Optimization
- **Model Selection** - Choose cost-effective models
- **Voice Optimization** - Identify most/least used voices
- **Usage Patterns** - Understand peak usage times
- **Resource Allocation** - Plan API usage distribution

### Reporting
- **Executive Dashboards** - High-level usage metrics
- **Team Analytics** - Workspace usage breakdown
- **Billing Reconciliation** - Verify usage charges
- **Compliance Reporting** - Track usage for audit purposes

## Limitations

- **Time Range**: Maximum time range may be limited based on your plan
- **Data Retention**: Historical data availability depends on your account type
- **Aggregation**: Some breakdown types may not be available for all time periods
- **Rate Limits**: Usage API calls count toward your rate limits

## Performance Tips

1. **Use Appropriate Intervals**: Choose aggregation intervals that match your needs
2. **Cache Results**: Cache usage data for frequently accessed periods
3. **Batch Requests**: Combine multiple breakdown types when possible
4. **Optimize Time Ranges**: Use precise time ranges to minimize data transfer
5. **Background Processing**: Use background jobs for large usage analysis tasks
