# frozen_string_literal: true

# Example Rails controller demonstrating ElevenLabs Admin User API integration
# This controller provides user account management and subscription monitoring
class Admin::UserController < ApplicationController
  before_action :initialize_client
  before_action :authenticate_admin # Ensure only admins can access user data
  
  # GET /admin/user
  # Main user dashboard showing account overview
  def show
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    @subscription_extras = @user_info['subscription_extras']
    
    # Calculate usage percentages
    @character_usage_percent = calculate_usage_percent(
      @subscription['character_count'],
      @subscription['character_limit']
    )
    
    @voice_usage_percent = calculate_usage_percent(
      @subscription['voice_slots_used'],
      @subscription['voice_limit']
    )
    
    @voice_edit_percent = calculate_usage_percent(
      @subscription['voice_add_edit_counter'],
      @subscription['max_voice_add_edits']
    )
    
    # Generate alerts and recommendations
    @alerts = generate_usage_alerts
    @recommendations = generate_recommendations
    @account_health = assess_account_health
    
    respond_to do |format|
      format.html
      format.json { render json: user_dashboard_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load user information")
  end
  
  # GET /admin/user/subscription
  # Detailed subscription information and management
  def subscription
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    @subscription_extras = @user_info['subscription_extras']
    
    # Calculate detailed metrics
    @usage_breakdown = calculate_usage_breakdown
    @billing_info = extract_billing_information
    @feature_matrix = build_feature_matrix
    @usage_history = fetch_recent_usage_history
    
    respond_to do |format|
      format.html
      format.json { render json: subscription_details_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load subscription details")
  end
  
  # GET /admin/user/limits
  # Usage limits monitoring and management
  def limits
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    
    @limits_data = {
      character_limit: {
        current: @subscription['character_count'],
        limit: @subscription['character_limit'],
        percentage: calculate_usage_percent(@subscription['character_count'], @subscription['character_limit']),
        can_extend: @subscription['can_extend_character_limit'],
        max_extension: @subscription['max_character_limit_extension'],
        next_reset: @subscription['next_character_count_reset_unix']
      },
      voice_limit: {
        current: @subscription['voice_slots_used'],
        limit: @subscription['voice_limit'],
        percentage: calculate_usage_percent(@subscription['voice_slots_used'], @subscription['voice_limit']),
        can_extend: @subscription['can_extend_voice_limit']
      },
      voice_edits: {
        current: @subscription['voice_add_edit_counter'],
        limit: @subscription['max_voice_add_edits'],
        percentage: calculate_usage_percent(@subscription['voice_add_edit_counter'], @subscription['max_voice_add_edits'])
      }
    }
    
    @limit_projections = calculate_limit_projections
    @optimization_suggestions = generate_optimization_suggestions
    
    respond_to do |format|
      format.html
      format.json { render json: @limits_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load limits information")
  end
  
  # GET /admin/user/features
  # Feature availability and capabilities overview
  def features
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    @subscription_extras = @user_info['subscription_extras']
    
    @features = {
      voice_cloning: {
        instant: @subscription['can_use_instant_voice_cloning'],
        professional: @subscription['can_use_professional_voice_cloning'],
        description: "Create custom voices from audio samples"
      },
      limits_extension: {
        character_limit: @subscription['can_extend_character_limit'],
        voice_limit: @subscription['can_extend_voice_limit'],
        description: "Extend usage limits beyond base plan"
      },
      advanced_features: {
        delayed_payments: @user_info['can_use_delayed_payment_methods'],
        voice_captcha_bypass: @subscription_extras&.dig('can_bypass_voice_captcha'),
        manual_pro_verification: @subscription_extras&.dig('can_request_manual_pro_voice_verification'),
        force_logging_disabled: @subscription_extras&.dig('force_logging_disabled'),
        description: "Advanced account features and capabilities"
      },
      concurrency: {
        standard: @subscription_extras&.dig('concurrency'),
        convai: @subscription_extras&.dig('convai_concurrency'),
        description: "Concurrent request limits"
      }
    }
    
    @tier_comparison = build_tier_comparison
    @upgrade_recommendations = generate_upgrade_recommendations
    
    respond_to do |format|
      format.html
      format.json { render json: { features: @features, tier_comparison: @tier_comparison } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load features information")
  end
  
  # GET /admin/user/security
  # Security and moderation status
  def security
    @user_info = @client.user.get_user
    @subscription_extras = @user_info['subscription_extras']
    @moderation = @subscription_extras&.dig('moderation') || {}
    
    @security_status = {
      account_status: determine_account_security_status,
      moderation: {
        in_probation: @moderation['is_in_probation'],
        on_watchlist: @moderation['on_watchlist'],
        enterprise_check_nogo: @moderation['enterprise_check_nogo_voice'],
        background_moderation: @moderation['enterprise_background_moderation_enabled'],
        never_live_moderate: @moderation['never_live_moderate'],
        nogo_voice_count: @moderation['nogo_voice_similar_voice_upload_count']
      },
      api_key: {
        is_hashed: @user_info['is_api_key_hashed'],
        preview: @user_info['xi_api_key_preview'],
        full_key_visible: @user_info['xi_api_key'].present?
      }
    }
    
    @security_recommendations = generate_security_recommendations
    @moderation_history = analyze_moderation_patterns
    
    respond_to do |format|
      format.html
      format.json { render json: { security: @security_status, recommendations: @security_recommendations } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load security information")
  end
  
  # GET /admin/user/health_check
  # Comprehensive account health assessment (AJAX endpoint)
  def health_check
    @user_info = @client.user.get_user
    @subscription = @user_info['subscription']
    @subscription_extras = @user_info['subscription_extras']
    
    health_data = {
      overall_status: 'healthy',
      score: 100,
      checks: [],
      timestamp: Time.current.iso8601
    }
    
    # Character usage check
    char_usage_percent = calculate_usage_percent(@subscription['character_count'], @subscription['character_limit'])
    health_data[:checks] << {
      category: 'usage',
      name: 'Character Usage',
      status: char_usage_percent > 90 ? 'critical' : (char_usage_percent > 75 ? 'warning' : 'good'),
      value: char_usage_percent,
      message: "Using #{char_usage_percent}% of character limit"
    }
    
    # Voice slots check
    voice_usage_percent = calculate_usage_percent(@subscription['voice_slots_used'], @subscription['voice_limit'])
    health_data[:checks] << {
      category: 'usage',
      name: 'Voice Slots',
      status: voice_usage_percent > 90 ? 'warning' : 'good',
      value: voice_usage_percent,
      message: "Using #{@subscription['voice_slots_used']} of #{@subscription['voice_limit']} voice slots"
    }
    
    # Account status check
    moderation = @subscription_extras&.dig('moderation')
    if moderation
      account_status = if moderation['is_in_probation']
                        'critical'
                      elsif moderation['on_watchlist']
                        'warning'
                      else
                        'good'
                      end
      
      health_data[:checks] << {
        category: 'security',
        name: 'Account Standing',
        status: account_status,
        message: determine_account_status_message(moderation)
      }
    end
    
    # Subscription status check
    subscription_status = @subscription['status'] == 'active' ? 'good' : 'warning'
    health_data[:checks] << {
      category: 'subscription',
      name: 'Subscription Status',
      status: subscription_status,
      value: @subscription['status'],
      message: "Subscription is #{@subscription['status']}"
    }
    
    # Calculate overall health
    critical_count = health_data[:checks].count { |c| c[:status] == 'critical' }
    warning_count = health_data[:checks].count { |c| c[:status] == 'warning' }
    
    if critical_count > 0
      health_data[:overall_status] = 'critical'
      health_data[:score] = [health_data[:score] - (critical_count * 30), 0].max
    elsif warning_count > 0
      health_data[:overall_status] = 'warning'
      health_data[:score] = [health_data[:score] - (warning_count * 15), 0].max
    end
    
    render json: health_data
  rescue ElevenlabsClient::APIError => e
    render json: { 
      overall_status: 'error', 
      score: 0, 
      error: e.message,
      timestamp: Time.current.iso8601
    }, status: :service_unavailable
  end
  
  # GET /admin/user/export
  # Export user data and subscription information
  def export
    @user_info = @client.user.get_user
    
    export_data = prepare_export_data
    
    respond_to do |format|
      format.json { render json: export_data }
      format.csv { send_csv_export(export_data) }
    end
  rescue ElevenlabsClient::APIError => e
    redirect_to admin_user_path, alert: "Export failed: #{e.message}"
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def authenticate_admin
    # Implement your admin authentication logic here
    # redirect_to root_path unless current_user&.admin?
  end
  
  def calculate_usage_percent(used, limit)
    return 0 if limit.zero?
    ((used.to_f / limit) * 100).round(2)
  end
  
  def generate_usage_alerts
    alerts = []
    
    # Character usage alerts
    if @character_usage_percent > 95
      alerts << {
        type: 'critical',
        category: 'usage',
        title: 'Character Limit Critical',
        message: "Character usage is at #{@character_usage_percent}% of limit",
        action: 'Upgrade plan immediately or usage will be blocked'
      }
    elsif @character_usage_percent > 80
      alerts << {
        type: 'warning',
        category: 'usage',
        title: 'High Character Usage',
        message: "Character usage is at #{@character_usage_percent}% of limit",
        action: 'Consider upgrading plan or monitoring usage closely'
      }
    end
    
    # Voice slots alerts
    if @voice_usage_percent > 90
      alerts << {
        type: 'warning',
        category: 'usage',
        title: 'Voice Slots Nearly Full',
        message: "Using #{@subscription['voice_slots_used']} of #{@subscription['voice_limit']} voice slots",
        action: 'Clean up unused voices or upgrade plan'
      }
    end
    
    # Voice edit limit alerts
    if @voice_edit_percent > 90
      alerts << {
        type: 'warning',
        category: 'usage',
        title: 'Voice Edit Limit Nearly Reached',
        message: "Used #{@subscription['voice_add_edit_counter']} of #{@subscription['max_voice_add_edits']} voice edits",
        action: 'Limit will reset next billing cycle'
      }
    end
    
    # Account status alerts
    if @subscription_extras&.dig('moderation', 'is_in_probation')
      alerts << {
        type: 'critical',
        category: 'security',
        title: 'Account in Probation',
        message: 'Your account is currently under review',
        action: 'Contact support for more information'
      }
    end
    
    if @subscription_extras&.dig('moderation', 'on_watchlist')
      alerts << {
        type: 'warning',
        category: 'security',
        title: 'Account on Watchlist',
        message: 'Your account is being monitored',
        action: 'Ensure compliance with terms of service'
      }
    end
    
    # Reset timing alerts
    if @subscription['next_character_count_reset_unix']
      days_until_reset = (@subscription['next_character_count_reset_unix'] - Time.current.to_i) / (24 * 60 * 60)
      if days_until_reset < 3 && @character_usage_percent > 50
        alerts << {
          type: 'info',
          category: 'billing',
          title: 'Usage Reset Soon',
          message: "Character count resets in #{days_until_reset.round(1)} days",
          action: 'Plan usage accordingly for remaining period'
        }
      end
    end
    
    alerts
  end
  
  def generate_recommendations
    recommendations = []
    
    # Usage-based recommendations
    if @character_usage_percent > 75
      recommendations << {
        category: 'upgrade',
        title: 'Consider Plan Upgrade',
        description: 'Your character usage suggests you might benefit from a higher tier plan',
        priority: @character_usage_percent > 90 ? 'high' : 'medium'
      }
    end
    
    if @voice_usage_percent > 80
      recommendations << {
        category: 'optimization',
        title: 'Voice Management',
        description: 'Clean up unused voices to free up slots',
        priority: 'medium'
      }
    end
    
    # Feature recommendations
    unless @subscription['can_use_professional_voice_cloning']
      recommendations << {
        category: 'feature',
        title: 'Professional Voice Cloning',
        description: 'Upgrade to access professional voice cloning features',
        priority: 'low'
      }
    end
    
    # Security recommendations
    if @user_info['is_api_key_hashed'] == false
      recommendations << {
        category: 'security',
        title: 'API Key Security',
        description: 'Consider enabling API key hashing for enhanced security',
        priority: 'medium'
      }
    end
    
    recommendations
  end
  
  def assess_account_health
    score = 100
    issues = []
    
    # Usage health
    if @character_usage_percent > 90
      score -= 30
      issues << 'Critical character usage'
    elsif @character_usage_percent > 75
      score -= 15
      issues << 'High character usage'
    end
    
    if @voice_usage_percent > 90
      score -= 20
      issues << 'Voice slots nearly full'
    end
    
    # Account status health
    if @subscription_extras&.dig('moderation', 'is_in_probation')
      score -= 50
      issues << 'Account in probation'
    elsif @subscription_extras&.dig('moderation', 'on_watchlist')
      score -= 25
      issues << 'Account on watchlist'
    end
    
    # Subscription health
    unless @subscription['status'] == 'active'
      score -= 40
      issues << 'Subscription not active'
    end
    
    status = if score >= 80
               'excellent'
             elsif score >= 60
               'good'
             elsif score >= 40
               'warning'
             else
               'critical'
             end
    
    {
      score: [score, 0].max,
      status: status,
      issues: issues
    }
  end
  
  def calculate_usage_breakdown
    {
      characters: {
        used: @subscription['character_count'],
        limit: @subscription['character_limit'],
        remaining: @subscription['character_limit'] - @subscription['character_count'],
        rollover: @subscription_extras&.dig('unused_characters_rolled_over_from_previous_period') || 0,
        overuse: @subscription_extras&.dig('overused_characters_rolled_over_from_previous_period') || 0
      },
      voices: {
        used: @subscription['voice_slots_used'],
        limit: @subscription['voice_limit'],
        professional_used: @subscription['professional_voice_slots_used'],
        professional_limit: @subscription['professional_voice_limit']
      },
      edits: {
        used: @subscription['voice_add_edit_counter'],
        limit: @subscription['max_voice_add_edits'],
        remaining: @subscription['max_voice_add_edits'] - @subscription['voice_add_edit_counter']
      }
    }
  end
  
  def extract_billing_information
    {
      tier: @subscription['tier'],
      status: @subscription['status'],
      currency: @subscription['currency'],
      billing_period: @subscription['billing_period'],
      character_refresh_period: @subscription['character_refresh_period'],
      next_reset: @subscription['next_character_count_reset_unix'] ? 
        Time.at(@subscription['next_character_count_reset_unix']).strftime('%Y-%m-%d %H:%M:%S') : nil
    }
  end
  
  def build_feature_matrix
    {
      voice_cloning: {
        instant: @subscription['can_use_instant_voice_cloning'],
        professional: @subscription['can_use_professional_voice_cloning']
      },
      limits: {
        extend_characters: @subscription['can_extend_character_limit'],
        extend_voices: @subscription['can_extend_voice_limit']
      },
      payments: {
        delayed_methods: @user_info['can_use_delayed_payment_methods']
      },
      advanced: {
        voice_captcha_bypass: @subscription_extras&.dig('can_bypass_voice_captcha'),
        manual_verification: @subscription_extras&.dig('can_request_manual_pro_voice_verification'),
        force_logging_disabled: @subscription_extras&.dig('force_logging_disabled')
      }
    }
  end
  
  def fetch_recent_usage_history
    # This would typically fetch from usage API or database
    # For now, return placeholder data
    {
      last_7_days: "Would fetch from usage API",
      trend: "increasing/decreasing/stable"
    }
  end
  
  def calculate_limit_projections
    return {} unless @subscription['next_character_count_reset_unix']
    
    days_until_reset = (@subscription['next_character_count_reset_unix'] - Time.current.to_i) / (24 * 60 * 60)
    remaining_chars = @subscription['character_limit'] - @subscription['character_count']
    daily_budget = days_until_reset > 0 ? remaining_chars / days_until_reset : 0
    
    {
      days_until_reset: days_until_reset.round(1),
      remaining_characters: remaining_chars,
      daily_budget: daily_budget.round(0),
      projected_overuse: daily_budget < 500 ? "Risk of exceeding limit" : nil
    }
  end
  
  def generate_optimization_suggestions
    suggestions = []
    
    # Character optimization
    if @character_usage_percent > 75
      suggestions << {
        type: 'usage',
        title: 'Optimize Text Length',
        description: 'Review generated text for unnecessary content to reduce character usage'
      }
      
      suggestions << {
        type: 'usage',
        title: 'Use Efficient Models',
        description: 'Consider using Turbo models for less critical content to reduce costs'
      }
    end
    
    # Voice optimization
    if @voice_usage_percent > 80
      suggestions << {
        type: 'management',
        title: 'Voice Cleanup',
        description: 'Remove unused or duplicate voices to free up slots'
      }
    end
    
    suggestions
  end
  
  def build_tier_comparison
    # This would typically come from a configuration or API
    {
      current: @subscription['tier'],
      available_tiers: %w[starter creator pro scale enterprise],
      upgrade_benefits: {
        'creator' => ['More characters', 'Professional voices', 'Priority support'],
        'pro' => ['Unlimited characters', 'Commercial license', 'API access'],
        'scale' => ['Team collaboration', 'Advanced analytics', 'Custom integrations'],
        'enterprise' => ['Dedicated support', 'Custom models', 'SLA guarantees']
      }
    }
  end
  
  def generate_upgrade_recommendations
    recommendations = []
    
    case @subscription['tier']
    when 'trial', 'starter'
      if @character_usage_percent > 50
        recommendations << {
          target_tier: 'creator',
          reason: 'Increased character limits and professional features',
          urgency: @character_usage_percent > 80 ? 'high' : 'medium'
        }
      end
    when 'creator'
      if @voice_usage_percent > 70
        recommendations << {
          target_tier: 'pro',
          reason: 'More voice slots and advanced features',
          urgency: 'medium'
        }
      end
    end
    
    recommendations
  end
  
  def determine_account_security_status
    if @subscription_extras&.dig('moderation', 'is_in_probation')
      'probation'
    elsif @subscription_extras&.dig('moderation', 'on_watchlist')
      'watchlist'
    else
      'good_standing'
    end
  end
  
  def generate_security_recommendations
    recommendations = []
    
    unless @user_info['is_api_key_hashed']
      recommendations << {
        category: 'api_security',
        title: 'Enable API Key Hashing',
        description: 'Hash your API key for enhanced security',
        priority: 'medium'
      }
    end
    
    if @subscription_extras&.dig('moderation', 'nogo_voice_similar_voice_upload_count', 0) > 0
      recommendations << {
        category: 'content_policy',
        title: 'Review Voice Uploads',
        description: 'Some voice uploads may have triggered content policy checks',
        priority: 'high'
      }
    end
    
    recommendations
  end
  
  def analyze_moderation_patterns
    moderation = @subscription_extras&.dig('moderation') || {}
    
    {
      current_status: determine_account_security_status,
      flags: {
        probation: moderation['is_in_probation'],
        watchlist: moderation['on_watchlist'],
        enterprise_restrictions: moderation['enterprise_check_nogo_voice'],
        background_moderation: moderation['enterprise_background_moderation_enabled']
      },
      metrics: {
        nogo_voice_count: moderation['nogo_voice_similar_voice_upload_count'] || 0
      }
    }
  end
  
  def determine_account_status_message(moderation)
    if moderation['is_in_probation']
      'Account is currently in probation - contact support'
    elsif moderation['on_watchlist']
      'Account is being monitored for compliance'
    else
      'Account is in good standing'
    end
  end
  
  def user_dashboard_data
    {
      user_info: @user_info.except('xi_api_key'), # Don't expose API key in JSON
      usage_percentages: {
        characters: @character_usage_percent,
        voices: @voice_usage_percent,
        voice_edits: @voice_edit_percent
      },
      alerts: @alerts,
      recommendations: @recommendations,
      account_health: @account_health
    }
  end
  
  def subscription_details_data
    {
      subscription: @subscription,
      subscription_extras: @subscription_extras,
      usage_breakdown: @usage_breakdown,
      billing_info: @billing_info,
      feature_matrix: @feature_matrix
    }
  end
  
  def prepare_export_data
    {
      exported_at: Time.current.iso8601,
      user_id: @user_info['user_id'],
      account_info: {
        created_at: @user_info['created_at'],
        first_name: @user_info['first_name'],
        onboarding_completed: @user_info['is_onboarding_completed'],
        onboarding_checklist_completed: @user_info['is_onboarding_checklist_completed']
      },
      subscription: @user_info['subscription'],
      subscription_extras: @user_info['subscription_extras'],
      usage_summary: calculate_usage_breakdown,
      account_health: assess_account_health
    }
  end
  
  def send_csv_export(data)
    require 'csv'
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Metric', 'Value', 'Details']
      
      # Basic info
      csv << ['User ID', data[:user_id], '']
      csv << ['Account Created', Time.at(data[:account_info][:created_at]).strftime('%Y-%m-%d'), ''] if data[:account_info][:created_at] > 0
      csv << ['Subscription Tier', data[:subscription]['tier'], '']
      csv << ['Subscription Status', data[:subscription]['status'], '']
      
      # Usage metrics
      csv << ['Character Usage', "#{data[:subscription]['character_count']} / #{data[:subscription]['character_limit']}", "#{@character_usage_percent}%"]
      csv << ['Voice Slots', "#{data[:subscription]['voice_slots_used']} / #{data[:subscription]['voice_limit']}", "#{@voice_usage_percent}%"]
      csv << ['Voice Edits', "#{data[:subscription]['voice_add_edit_counter']} / #{data[:subscription]['max_voice_add_edits']}", "#{@voice_edit_percent}%"]
      
      # Health metrics
      csv << ['Account Health Score', data[:account_health][:score], data[:account_health][:status]]
      csv << ['Account Issues', data[:account_health][:issues].join(', '), ''] if data[:account_health][:issues].any?
    end
    
    filename = "user_export_#{@user_info['user_id']}_#{Date.current}.csv"
    send_data csv_data, type: 'text/csv', filename: filename, disposition: 'attachment'
  end
  
  def handle_api_error(error, default_message)
    Rails.logger.error "ElevenLabs API Error: #{error.message}"
    flash.now[:error] = "#{default_message}: #{error.message}"
    
    # Set fallback data
    @user_info = {}
    @subscription = {}
    @subscription_extras = {}
    @alerts = []
    @recommendations = []
    @account_health = { score: 0, status: 'unknown', issues: ['API Error'] }
    
    render :show
  end
end
