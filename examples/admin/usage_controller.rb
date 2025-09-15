# frozen_string_literal: true

# Example Rails controller demonstrating ElevenLabs Admin Usage API integration
# This controller provides comprehensive usage analytics and monitoring functionality
class Admin::UsageController < ApplicationController
  before_action :initialize_client
  before_action :authenticate_admin # Ensure only admins can access usage data
  
  # GET /admin/usage
  # Main usage dashboard with overview metrics
  def index
    @period = params[:period] || '30'
    days = @period.to_i
    
    @usage_data = fetch_usage_overview(days)
    @account_health = check_account_health
    @usage_trends = calculate_usage_trends(@usage_data[:daily])
    
    respond_to do |format|
      format.html
      format.json { render json: @usage_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load usage dashboard")
  end
  
  # GET /admin/usage/analytics
  # Detailed analytics with breakdowns
  def analytics
    @period = params[:period] || '30'
    days = @period.to_i
    
    @analytics_data = fetch_detailed_analytics(days)
    @voice_rankings = calculate_voice_rankings(@analytics_data[:by_voice])
    @model_performance = calculate_model_performance(@analytics_data[:by_model])
    @cost_analysis = estimate_usage_costs(@analytics_data[:by_model])
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load analytics data")
  end
  
  # GET /admin/usage/trends
  # Historical trends and forecasting
  def trends
    @period = params[:period] || '90'
    days = @period.to_i
    
    @trends_data = fetch_trends_data(days)
    @forecast = generate_usage_forecast(@trends_data[:daily])
    @seasonal_patterns = analyze_seasonal_patterns(@trends_data[:daily])
    
    respond_to do |format|
      format.html
      format.json { render json: { trends: @trends_data, forecast: @forecast, patterns: @seasonal_patterns } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load trends data")
  end
  
  # GET /admin/usage/export
  # Export usage data to CSV
  def export
    period = params[:period] || '30'
    days = period.to_i
    breakdown = params[:breakdown] || 'daily'
    
    usage_data = fetch_export_data(days, breakdown)
    csv_data = generate_usage_csv(usage_data, breakdown)
    
    filename = "usage_report_#{breakdown}_#{days}days_#{Date.current}.csv"
    
    send_data csv_data,
              type: 'text/csv',
              filename: filename,
              disposition: 'attachment'
  rescue ElevenlabsClient::APIError => e
    redirect_to admin_usage_path, alert: "Export failed: #{e.message}"
  end
  
  # GET /admin/usage/realtime
  # Real-time usage monitoring (AJAX endpoint)
  def realtime
    # Get today's usage
    today_start = Time.current.beginning_of_day.to_i * 1000
    now = Time.current.to_i * 1000
    
    today_usage = @client.usage.get_character_stats(
      start_unix: today_start,
      end_unix: now,
      aggregation_interval: "hour"
    )
    
    # Calculate current rate
    current_hour_usage = today_usage['usage']['All'].last || 0
    daily_total = today_usage['usage']['All'].sum
    
    # Get user limits for context
    user_info = @client.user.get_user
    character_limit = user_info['subscription']['character_limit']
    usage_percent = (daily_total.to_f / character_limit * 100).round(2)
    
    render json: {
      current_hour: current_hour_usage,
      daily_total: daily_total,
      character_limit: character_limit,
      usage_percent: usage_percent,
      status: determine_usage_status(usage_percent),
      timestamp: Time.current.iso8601
    }
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :service_unavailable
  end
  
  # GET /admin/usage/alerts
  # Usage alerts and notifications
  def alerts
    @alerts = []
    
    begin
      user_info = @client.user.get_user
      subscription = user_info['subscription']
      
      # Check character usage
      char_usage_percent = (subscription['character_count'].to_f / subscription['character_limit'] * 100)
      if char_usage_percent > 90
        @alerts << {
          type: 'critical',
          title: 'Character Usage Critical',
          message: "Character usage is at #{char_usage_percent.round(1)}% of limit",
          action: 'Consider upgrading your plan or monitoring usage closely'
        }
      elsif char_usage_percent > 75
        @alerts << {
          type: 'warning',
          title: 'High Character Usage',
          message: "Character usage is at #{char_usage_percent.round(1)}% of limit",
          action: 'Monitor usage and consider upgrading if needed'
        }
      end
      
      # Check voice slots
      voice_usage_percent = (subscription['voice_slots_used'].to_f / subscription['voice_limit'] * 100)
      if voice_usage_percent > 90
        @alerts << {
          type: 'warning',
          title: 'Voice Slots Nearly Full',
          message: "Using #{subscription['voice_slots_used']} of #{subscription['voice_limit']} voice slots",
          action: 'Clean up unused voices or upgrade plan'
        }
      end
      
      # Check reset timing
      if subscription['next_character_count_reset_unix']
        days_until_reset = (subscription['next_character_count_reset_unix'] - Time.current.to_i) / (24 * 60 * 60)
        if days_until_reset < 3 && char_usage_percent > 50
          @alerts << {
            type: 'info',
            title: 'Usage Reset Soon',
            message: "Character count resets in #{days_until_reset.round(1)} days",
            action: 'Plan usage accordingly for remaining period'
          }
        end
      end
      
    rescue ElevenlabsClient::APIError => e
      @alerts << {
        type: 'error',
        title: 'Unable to Check Usage',
        message: e.message,
        action: 'Check API connectivity and try again'
      }
    end
    
    respond_to do |format|
      format.html
      format.json { render json: { alerts: @alerts } }
    end
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def authenticate_admin
    # Implement your admin authentication logic here
    # redirect_to root_path unless current_user&.admin?
  end
  
  def fetch_usage_overview(days)
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    {
      daily: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "day"
      ),
      by_voice: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "voice"
      ),
      by_model: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "model"
      )
    }
  end
  
  def fetch_detailed_analytics(days)
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    {
      daily: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "day"
      ),
      hourly: @client.usage.get_character_stats(
        start_unix: (Time.current - 3.days).to_i * 1000,
        end_unix: end_time,
        aggregation_interval: "hour"
      ),
      by_voice: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "voice"
      ),
      by_model: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "model"
      ),
      by_source: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "source"
      )
    }
  end
  
  def fetch_trends_data(days)
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    {
      daily: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "day"
      ),
      weekly: @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "week"
      )
    }
  end
  
  def fetch_export_data(days, breakdown)
    end_time = Time.current.to_i * 1000
    start_time = (Time.current - days.days).to_i * 1000
    
    case breakdown
    when 'hourly'
      @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "hour"
      )
    when 'daily'
      @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        aggregation_interval: "day"
      )
    when 'voice'
      @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "voice"
      )
    when 'model'
      @client.usage.get_character_stats(
        start_unix: start_time,
        end_unix: end_time,
        breakdown_type: "model"
      )
    end
  end
  
  def check_account_health
    user_info = @client.user.get_user
    subscription = user_info['subscription']
    
    char_usage_percent = (subscription['character_count'].to_f / subscription['character_limit'] * 100)
    voice_usage_percent = (subscription['voice_slots_used'].to_f / subscription['voice_limit'] * 100)
    
    status = if char_usage_percent > 90 || voice_usage_percent > 90
               'critical'
             elsif char_usage_percent > 75 || voice_usage_percent > 75
               'warning'
             else
               'healthy'
             end
    
    {
      status: status,
      character_usage_percent: char_usage_percent.round(2),
      voice_usage_percent: voice_usage_percent.round(2),
      days_until_reset: calculate_days_until_reset(subscription['next_character_count_reset_unix'])
    }
  end
  
  def calculate_usage_trends(daily_data)
    usage_values = daily_data['usage']['All']
    return { trend: 'stable', change: 0 } if usage_values.length < 7
    
    # Calculate 7-day moving average trend
    recent_avg = usage_values.last(7).sum / 7.0
    previous_avg = usage_values[-14..-8].sum / 7.0 rescue recent_avg
    
    change_percent = ((recent_avg - previous_avg) / previous_avg * 100).round(2) rescue 0
    
    trend = if change_percent > 10
              'increasing'
            elsif change_percent < -10
              'decreasing'
            else
              'stable'
            end
    
    {
      trend: trend,
      change: change_percent,
      recent_avg: recent_avg.round(0),
      previous_avg: previous_avg.round(0)
    }
  end
  
  def calculate_voice_rankings(voice_data)
    return [] unless voice_data&.dig('usage')
    
    voice_data['usage'].map do |voice_name, usage_values|
      total_usage = usage_values.sum
      avg_daily = total_usage.to_f / usage_values.length
      
      {
        name: voice_name,
        total_usage: total_usage,
        avg_daily: avg_daily.round(2),
        percentage: 0 # Will be calculated after sorting
      }
    end.sort_by { |v| -v[:total_usage] }.tap do |rankings|
      total_all = rankings.sum { |v| v[:total_usage] }
      rankings.each do |voice|
        voice[:percentage] = (voice[:total_usage].to_f / total_all * 100).round(2)
      end
    end
  end
  
  def calculate_model_performance(model_data)
    return [] unless model_data&.dig('usage')
    
    model_data['usage'].map do |model_name, usage_values|
      total_usage = usage_values.sum
      avg_daily = total_usage.to_f / usage_values.length
      peak_usage = usage_values.max
      
      {
        name: model_name,
        total_usage: total_usage,
        avg_daily: avg_daily.round(2),
        peak_usage: peak_usage,
        consistency: calculate_consistency(usage_values)
      }
    end.sort_by { |m| -m[:total_usage] }
  end
  
  def estimate_usage_costs(model_data)
    return { total_cost_units: 0, by_model: [] } unless model_data&.dig('usage')
    
    # Cost factors (adjust based on actual pricing)
    cost_factors = {
      'eleven_multilingual_v2' => 1.0,
      'eleven_monolingual_v1' => 1.0,
      'eleven_turbo_v2' => 0.3,
      'eleven_multilingual_v1' => 1.0
    }
    
    total_cost_units = 0
    by_model = []
    
    model_data['usage'].each do |model_name, usage_values|
      total_chars = usage_values.sum
      cost_factor = cost_factors[model_name] || 1.0
      cost_units = total_chars * cost_factor
      total_cost_units += cost_units
      
      by_model << {
        model: model_name,
        characters: total_chars,
        cost_factor: cost_factor,
        cost_units: cost_units.round(2)
      }
    end
    
    {
      total_cost_units: total_cost_units.round(2),
      by_model: by_model.sort_by { |m| -m[:cost_units] }
    }
  end
  
  def generate_usage_forecast(daily_data)
    usage_values = daily_data['usage']['All']
    return { forecast: [], confidence: 'low' } if usage_values.length < 14
    
    # Simple linear trend forecast for next 7 days
    recent_trend = calculate_linear_trend(usage_values.last(14))
    last_value = usage_values.last
    
    forecast = (1..7).map do |days_ahead|
      forecasted_value = [last_value + (recent_trend * days_ahead), 0].max
      {
        date: (Date.current + days_ahead).to_s,
        predicted_usage: forecasted_value.round(0)
      }
    end
    
    confidence = usage_values.length > 30 ? 'high' : 'medium'
    
    {
      forecast: forecast,
      confidence: confidence,
      trend_slope: recent_trend.round(2)
    }
  end
  
  def analyze_seasonal_patterns(daily_data)
    usage_values = daily_data['usage']['All']
    time_stamps = daily_data['time']
    
    return { patterns: [], insights: [] } if usage_values.length < 28
    
    # Group by day of week
    by_day_of_week = Hash.new { |h, k| h[k] = [] }
    
    time_stamps.each_with_index do |timestamp, index|
      date = Time.at(timestamp / 1000)
      day_of_week = date.strftime('%A')
      by_day_of_week[day_of_week] << usage_values[index]
    end
    
    patterns = by_day_of_week.map do |day, values|
      {
        day: day,
        avg_usage: (values.sum.to_f / values.length).round(2),
        pattern_strength: calculate_pattern_strength(values)
      }
    end.sort_by { |p| Date::DAYNAMES.index(p[:day]) }
    
    insights = generate_pattern_insights(patterns)
    
    {
      patterns: patterns,
      insights: insights
    }
  end
  
  def generate_usage_csv(usage_data, breakdown)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      case breakdown
      when 'daily', 'hourly'
        csv << ['Timestamp', 'Date', 'Characters Used']
        usage_data['time'].each_with_index do |timestamp, index|
          date = Time.at(timestamp / 1000)
          chars = usage_data['usage']['All'][index]
          csv << [timestamp, date.strftime('%Y-%m-%d %H:%M'), chars]
        end
      when 'voice', 'model'
        csv << ['Name', 'Total Characters', 'Average Daily', 'Peak Day']
        usage_data['usage'].each do |name, usage_values|
          total = usage_values.sum
          avg = (total.to_f / usage_values.length).round(2)
          peak = usage_values.max
          csv << [name, total, avg, peak]
        end
      end
    end
  end
  
  def determine_usage_status(usage_percent)
    case usage_percent
    when 0..50 then 'normal'
    when 51..75 then 'moderate'
    when 76..90 then 'high'
    else 'critical'
    end
  end
  
  def calculate_days_until_reset(reset_unix)
    return nil unless reset_unix
    (reset_unix - Time.current.to_i) / (24 * 60 * 60)
  end
  
  def calculate_consistency(values)
    return 0 if values.empty?
    mean = values.sum.to_f / values.length
    variance = values.sum { |v| (v - mean) ** 2 } / values.length
    std_dev = Math.sqrt(variance)
    coefficient_of_variation = std_dev / mean
    # Convert to consistency score (lower CV = higher consistency)
    [100 - (coefficient_of_variation * 100), 0].max.round(2)
  end
  
  def calculate_linear_trend(values)
    return 0 if values.length < 2
    n = values.length
    sum_x = (0...n).sum
    sum_y = values.sum
    sum_xy = values.each_with_index.sum { |y, x| x * y }
    sum_x2 = (0...n).sum { |x| x * x }
    
    # Linear regression slope
    (n * sum_xy - sum_x * sum_y).to_f / (n * sum_x2 - sum_x * sum_x)
  end
  
  def calculate_pattern_strength(values)
    return 0 if values.length < 2
    mean = values.sum.to_f / values.length
    variance = values.sum { |v| (v - mean) ** 2 } / values.length
    Math.sqrt(variance).round(2)
  end
  
  def generate_pattern_insights(patterns)
    insights = []
    
    # Find peak day
    peak_day = patterns.max_by { |p| p[:avg_usage] }
    insights << "Highest usage typically occurs on #{peak_day[:day]} (#{peak_day[:avg_usage]} chars avg)"
    
    # Find low day
    low_day = patterns.min_by { |p| p[:avg_usage] }
    insights << "Lowest usage typically occurs on #{low_day[:day]} (#{low_day[:avg_usage]} chars avg)"
    
    # Weekend vs weekday pattern
    weekend_avg = patterns.select { |p| %w[Saturday Sunday].include?(p[:day]) }.sum { |p| p[:avg_usage] } / 2.0
    weekday_avg = patterns.reject { |p| %w[Saturday Sunday].include?(p[:day]) }.sum { |p| p[:avg_usage] } / 5.0
    
    if weekend_avg > weekday_avg * 1.2
      insights << "Weekend usage is significantly higher than weekdays"
    elsif weekday_avg > weekend_avg * 1.2
      insights << "Weekday usage is significantly higher than weekends"
    else
      insights << "Usage patterns are relatively consistent across the week"
    end
    
    insights
  end
  
  def handle_api_error(error, default_message)
    Rails.logger.error "ElevenLabs API Error: #{error.message}"
    flash.now[:error] = "#{default_message}: #{error.message}"
    
    # Set empty data to prevent view errors
    @usage_data = { daily: { 'time' => [], 'usage' => {} }, by_voice: { 'usage' => {} }, by_model: { 'usage' => {} } }
    @analytics_data = @usage_data
    @trends_data = @usage_data
    
    render :index
  end
end
