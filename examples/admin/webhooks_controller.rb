# frozen_string_literal: true

# Example Rails controller demonstrating the ElevenlabsClient Admin::Webhooks API
# This controller shows how to integrate workspace webhook management functionality
# into a Rails application with proper error handling and user feedback.
#
# Usage:
# 1. Include this controller in your Rails application
# 2. Add routes for the webhook management actions
# 3. Ensure the Elevenlabs API key is configured in your environment
# 4. Customize the views and error handling for your application's needs
#
# Routes example:
#   Rails.application.routes.draw do
#     namespace :admin do
#       resources :webhooks, only: [:index] do
#         collection do
#           get :list
#           get :health_check
#           get :export
#         end
#       end
#     end
#   end

class Admin::WebhooksController < ApplicationController
  before_action :authenticate_admin!
  before_action :initialize_client
  before_action :set_query_params, only: [:index, :list]

  # GET /admin/webhooks
  # List all workspace webhooks
  def index
    fetch_webhooks
  end

  # GET /admin/webhooks/list
  # Alternative endpoint for listing webhooks (API format)
  def list
    fetch_webhooks
  end

  # GET /admin/webhooks/health_check
  # Check the health status of all webhooks
  def health_check
    perform_health_check
  end

  # GET /admin/webhooks/export
  # Export webhook data in various formats
  def export
    export_webhooks_data
  end

  private

  def initialize_client
    @client = ElevenlabsClient::Client.new
    @webhooks = @client.webhooks
  rescue StandardError => e
    Rails.logger.error "Failed to initialize ElevenLabs client: #{e.message}"
    render_error("Service temporarily unavailable", :service_unavailable)
  end

  def set_query_params
    @include_usages = params[:include_usages].present? && 
                      ActiveModel::Type::Boolean.new.cast(params[:include_usages])
    @filter_status = params[:status] # 'active', 'disabled', 'auto_disabled', 'failed'
    @filter_auth_type = params[:auth_type] # 'hmac', 'bearer', 'none'
  end

  def fetch_webhooks
    return unless @webhooks

    begin
      result = @webhooks.list_webhooks(include_usages: @include_usages)
      
      @webhooks_data = result["webhooks"] || []
      
      # Apply filters
      @filtered_webhooks = apply_filters(@webhooks_data)
      
      # Calculate statistics
      @statistics = calculate_statistics(@webhooks_data)
      @health_summary = calculate_health_summary(@webhooks_data)
      
      Rails.logger.info "Retrieved #{@webhooks_data.count} webhooks, #{@filtered_webhooks.count} after filtering"

      respond_to do |format|
        format.json { render json: success_response }
        format.html # Renders the index.html.erb view
        format.csv { render csv: generate_csv(@filtered_webhooks) }
      end

    rescue ElevenlabsClient::AuthenticationError => e
      handle_authentication_error(e)
    rescue ElevenlabsClient::UnprocessableEntityError => e
      handle_validation_error(e)
    rescue ElevenlabsClient::RateLimitError => e
      handle_rate_limit_error(e)
    rescue ElevenlabsClient::APIError => e
      handle_api_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end
  end

  def perform_health_check
    return unless @webhooks

    begin
      result = @webhooks.list_webhooks(include_usages: true)
      webhooks_data = result["webhooks"] || []
      
      @health_report = generate_health_report(webhooks_data)
      
      Rails.logger.info "Webhook health check completed: #{@health_report[:summary][:total_webhooks]} webhooks analyzed"

      respond_to do |format|
        format.json { render json: health_check_response }
        format.html { render :health_check }
      end

    rescue ElevenlabsClient::AuthenticationError => e
      handle_authentication_error(e)
    rescue ElevenlabsClient::APIError => e
      handle_api_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end
  end

  def export_webhooks_data
    return unless @webhooks

    begin
      result = @webhooks.list_webhooks(include_usages: true)
      webhooks_data = result["webhooks"] || []
      
      format = params[:format] || 'json'
      
      case format.downcase
      when 'csv'
        send_data generate_csv(webhooks_data), 
                  filename: "webhooks_export_#{Date.current}.csv",
                  type: 'text/csv'
      when 'json'
        send_data generate_json_export(webhooks_data),
                  filename: "webhooks_export_#{Date.current}.json",
                  type: 'application/json'
      when 'xlsx'
        send_data generate_excel_export(webhooks_data),
                  filename: "webhooks_export_#{Date.current}.xlsx",
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      else
        render json: { error: "Unsupported format: #{format}" }, status: :bad_request
      end

    rescue ElevenlabsClient::APIError => e
      handle_api_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end
  end

  def apply_filters(webhooks_data)
    filtered = webhooks_data.dup
    
    if @filter_status.present?
      filtered = case @filter_status.downcase
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
    
    if @filter_auth_type.present?
      filtered = filtered.select { |w| w["auth_type"]&.downcase == @filter_auth_type.downcase }
    end
    
    filtered
  end

  def calculate_statistics(webhooks_data)
    return default_statistics if webhooks_data.empty?

    total_webhooks = webhooks_data.count
    active_webhooks = webhooks_data.count { |w| !w["is_disabled"] && !w["is_auto_disabled"] }
    disabled_webhooks = webhooks_data.count { |w| w["is_disabled"] }
    auto_disabled_webhooks = webhooks_data.count { |w| w["is_auto_disabled"] }
    failed_webhooks = webhooks_data.count { |w| w["most_recent_failure_error_code"] }
    
    auth_types = webhooks_data.group_by { |w| w["auth_type"] }.transform_values(&:count)
    usage_types = webhooks_data.flat_map { |w| w["usage"] || [] }
                               .group_by { |u| u["usage_type"] }
                               .transform_values(&:count)

    {
      total_webhooks: total_webhooks,
      active_webhooks: active_webhooks,
      disabled_webhooks: disabled_webhooks,
      auto_disabled_webhooks: auto_disabled_webhooks,
      failed_webhooks: failed_webhooks,
      success_rate: total_webhooks > 0 ? ((total_webhooks - failed_webhooks).to_f / total_webhooks * 100).round(2) : 0,
      auth_types_distribution: auth_types,
      usage_types_distribution: usage_types
    }
  end

  def calculate_health_summary(webhooks_data)
    return default_health_summary if webhooks_data.empty?

    healthy_webhooks = webhooks_data.count { |w| !w["is_disabled"] && !w["is_auto_disabled"] && !w["most_recent_failure_error_code"] }
    warning_webhooks = webhooks_data.count { |w| !w["is_disabled"] && w["most_recent_failure_error_code"] }
    critical_webhooks = webhooks_data.count { |w| w["is_auto_disabled"] }
    
    overall_health = if critical_webhooks > 0
                      'critical'
                    elsif warning_webhooks > 0
                      'warning'
                    elsif healthy_webhooks > 0
                      'healthy'
                    else
                      'unknown'
                    end

    {
      overall_health: overall_health,
      healthy_count: healthy_webhooks,
      warning_count: warning_webhooks,
      critical_count: critical_webhooks,
      health_percentage: webhooks_data.count > 0 ? (healthy_webhooks.to_f / webhooks_data.count * 100).round(2) : 0
    }
  end

  def generate_health_report(webhooks_data)
    summary = calculate_statistics(webhooks_data)
    health_summary = calculate_health_summary(webhooks_data)
    
    issues = []
    recommendations = []
    
    webhooks_data.each do |webhook|
      webhook_name = webhook["name"]
      
      # Check for disabled webhooks
      if webhook["is_disabled"]
        issues << {
          severity: 'medium',
          type: 'disabled_webhook',
          webhook: webhook_name,
          description: "Webhook is manually disabled"
        }
      end
      
      # Check for auto-disabled webhooks
      if webhook["is_auto_disabled"]
        issues << {
          severity: 'high',
          type: 'auto_disabled_webhook',
          webhook: webhook_name,
          description: "Webhook was automatically disabled due to failures"
        }
        recommendations << "Re-enable and fix webhook: #{webhook_name}"
      end
      
      # Check for recent failures
      if webhook["most_recent_failure_error_code"]
        error_code = webhook["most_recent_failure_error_code"]
        timestamp = webhook["most_recent_failure_timestamp"]
        
        issues << {
          severity: 'high',
          type: 'recent_failure',
          webhook: webhook_name,
          description: "Recent failure with HTTP #{error_code}",
          timestamp: timestamp
        }
        recommendations << "Investigate failure for webhook: #{webhook_name} (HTTP #{error_code})"
      end
      
      # Check for old webhooks without recent activity
      webhook_age_days = (Time.current.to_i - webhook["created_at_unix"]) / 86400
      if webhook_age_days > 365 && webhook["usage"].empty?
        issues << {
          severity: 'low',
          type: 'unused_webhook',
          webhook: webhook_name,
          description: "Webhook is over 1 year old with no usage"
        }
        recommendations << "Consider removing unused webhook: #{webhook_name}"
      end
    end

    {
      summary: summary,
      health_summary: health_summary,
      issues: issues.sort_by { |i| severity_order(i[:severity]) },
      recommendations: recommendations.uniq,
      generated_at: Time.current.iso8601
    }
  end

  def severity_order(severity)
    case severity
    when 'high' then 1
    when 'medium' then 2
    when 'low' then 3
    else 4
    end
  end

  def generate_csv(webhooks_data)
    CSV.generate do |csv|
      csv << ["Name", "Webhook ID", "URL", "Status", "Auth Type", "Usage Types", "Created At", "Recent Failure Code", "Recent Failure Time"]
      
      webhooks_data.each do |webhook|
        status = if webhook["is_auto_disabled"]
                  "Auto Disabled"
                elsif webhook["is_disabled"]
                  "Disabled"
                else
                  "Active"
                end
        
        usage_types = webhook["usage"]&.map { |u| u["usage_type"] }&.join("; ") || ""
        recent_failure_time = webhook["most_recent_failure_timestamp"] ? 
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
          recent_failure_time
        ]
      end
    end
  end

  def generate_json_export(webhooks_data)
    {
      export_metadata: {
        generated_at: Time.current.iso8601,
        total_webhooks: webhooks_data.count,
        export_version: "1.0"
      },
      webhooks: webhooks_data,
      statistics: calculate_statistics(webhooks_data)
    }.to_json
  end

  def generate_excel_export(webhooks_data)
    # This would require a gem like 'rubyXL' or 'axlsx'
    # For now, return CSV data as a placeholder
    generate_csv(webhooks_data)
  end

  def default_statistics
    {
      total_webhooks: 0,
      active_webhooks: 0,
      disabled_webhooks: 0,
      auto_disabled_webhooks: 0,
      failed_webhooks: 0,
      success_rate: 0,
      auth_types_distribution: {},
      usage_types_distribution: {}
    }
  end

  def default_health_summary
    {
      overall_health: 'unknown',
      healthy_count: 0,
      warning_count: 0,
      critical_count: 0,
      health_percentage: 0
    }
  end

  def success_response
    {
      success: true,
      data: {
        webhooks: @filtered_webhooks,
        statistics: @statistics,
        health_summary: @health_summary,
        filters: {
          include_usages: @include_usages,
          status: @filter_status,
          auth_type: @filter_auth_type
        }
      },
      timestamp: Time.current.iso8601
    }
  end

  def health_check_response
    {
      success: true,
      health_report: @health_report,
      timestamp: Time.current.iso8601
    }
  end

  def handle_authentication_error(error)
    Rails.logger.error "ElevenLabs authentication failed: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Authentication failed", :unauthorized) }
      format.html do
        flash[:alert] = "Service authentication failed"
        redirect_to admin_root_path
      end
    end
  end

  def handle_validation_error(error)
    Rails.logger.warn "Validation error: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Invalid request parameters", :unprocessable_entity) }
      format.html do
        flash[:alert] = "Invalid request parameters"
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def handle_rate_limit_error(error)
    Rails.logger.warn "Rate limit exceeded: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Rate limit exceeded. Please try again later.", :too_many_requests) }
      format.html do
        flash[:alert] = "Too many requests. Please try again in a moment."
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def handle_api_error(error)
    Rails.logger.error "ElevenLabs API error: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Service temporarily unavailable", :service_unavailable) }
      format.html do
        flash[:alert] = "Service temporarily unavailable. Please try again later."
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def handle_unexpected_error(error)
    Rails.logger.error "Unexpected error in webhooks retrieval: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    respond_to do |format|
      format.json { render json: error_response("An unexpected error occurred", :internal_server_error) }
      format.html do
        flash[:alert] = "An unexpected error occurred"
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def error_response(message, status)
    {
      success: false,
      error: message,
      timestamp: Time.current.iso8601
    }
  end

  def render_error(message, status)
    respond_to do |format|
      format.json { render json: error_response(message, status), status: status }
      format.html do
        flash[:alert] = message
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  # Ensure only admin users can access these endpoints
  def authenticate_admin!
    # Implement your admin authentication logic here
    # Example:
    # redirect_to root_path unless current_user&.admin?
    # or use a gem like CanCan:
    # authorize! :manage, :admin_webhooks
  end
end

# Example view helper methods that could be added to ApplicationHelper
module Admin::WebhooksHelper
  def webhook_status_badge(webhook)
    if webhook["is_auto_disabled"]
      content_tag :span, "Auto Disabled", class: "badge badge-danger"
    elsif webhook["is_disabled"]
      content_tag :span, "Disabled", class: "badge badge-secondary"
    else
      content_tag :span, "Active", class: "badge badge-success"
    end
  end

  def webhook_health_badge(webhook)
    if webhook["is_auto_disabled"]
      content_tag :span, "Critical", class: "badge badge-danger"
    elsif webhook["most_recent_failure_error_code"]
      content_tag :span, "Warning", class: "badge badge-warning"
    elsif !webhook["is_disabled"]
      content_tag :span, "Healthy", class: "badge badge-success"
    else
      content_tag :span, "Inactive", class: "badge badge-secondary"
    end
  end

  def webhook_auth_type_badge(auth_type)
    badge_class = case auth_type&.downcase
                 when "hmac"
                   "badge-primary"
                 when "bearer"
                   "badge-info"
                 when "none"
                   "badge-warning"
                 else
                   "badge-secondary"
                 end
    
    content_tag :span, auth_type&.upcase || "UNKNOWN", class: "badge #{badge_class}"
  end

  def webhook_usage_badges(usage_array)
    return content_tag(:span, "No usage", class: "text-muted") if usage_array.blank?

    usage_array.map do |usage|
      content_tag :span, usage["usage_type"], class: "badge badge-outline-primary mr-1"
    end.join.html_safe
  end

  def webhook_failure_info(webhook)
    error_code = webhook["most_recent_failure_error_code"]
    timestamp = webhook["most_recent_failure_timestamp"]
    
    return content_tag(:span, "No recent failures", class: "text-success") unless error_code
    
    failure_time = Time.at(timestamp).strftime("%Y-%m-%d %H:%M:%S") if timestamp
    
    content_tag :div, class: "text-danger" do
      content_tag(:strong, "HTTP #{error_code}") +
      (failure_time ? content_tag(:small, " at #{failure_time}", class: "text-muted d-block") : "")
    end
  end

  def webhook_created_date(created_at_unix)
    Time.at(created_at_unix).strftime("%B %d, %Y")
  rescue
    "Unknown"
  end

  def webhook_url_display(url, max_length: 50)
    return "Invalid URL" if url.blank?
    
    if url.length > max_length
      truncated = url[0..max_length-4] + "..."
      content_tag :span, truncated, title: url
    else
      content_tag :span, url
    end
  end

  def webhook_health_summary_cards(health_summary)
    [
      {
        title: "Healthy Webhooks",
        value: health_summary[:healthy_count],
        icon: "fas fa-check-circle",
        color: "success"
      },
      {
        title: "Warning Webhooks",
        value: health_summary[:warning_count],
        icon: "fas fa-exclamation-triangle",
        color: "warning"
      },
      {
        title: "Critical Webhooks",
        value: health_summary[:critical_count],
        icon: "fas fa-times-circle",
        color: "danger"
      },
      {
        title: "Overall Health",
        value: "#{health_summary[:health_percentage]}%",
        icon: "fas fa-heart",
        color: health_summary[:health_percentage] > 80 ? "success" : 
               health_summary[:health_percentage] > 50 ? "warning" : "danger"
      }
    ]
  end
end

# Example JavaScript for enhanced UX (app/assets/javascripts/admin/webhooks.js)
=begin
document.addEventListener('DOMContentLoaded', function() {
  // Initialize webhooks management
  initializeWebhooksTable();
  initializeFiltering();
  initializeHealthCheck();
  initializeExport();
});

function initializeWebhooksTable() {
  const table = document.getElementById('webhooks-table');
  if (!table) return;

  // Add sorting functionality
  const headers = table.querySelectorAll('th[data-sortable]');
  headers.forEach(header => {
    header.addEventListener('click', function() {
      const column = this.dataset.column;
      const direction = this.dataset.direction === 'asc' ? 'desc' : 'asc';
      sortTable(column, direction);
      updateSortIndicators(this, direction);
    });
  });
}

function sortTable(column, direction) {
  console.log(`Sorting by ${column} in ${direction} order`);
  // Implement table sorting logic
}

function initializeFiltering() {
  const filterForm = document.getElementById('webhooks-filter');
  if (!filterForm) return;

  filterForm.addEventListener('submit', function(e) {
    e.preventDefault();
    applyFilters();
  });

  // Real-time filtering
  const filterInputs = filterForm.querySelectorAll('select, input[type="checkbox"]');
  filterInputs.forEach(input => {
    input.addEventListener('change', function() {
      applyFilters();
    });
  });
}

function applyFilters() {
  const formData = new FormData(document.getElementById('webhooks-filter'));
  const params = new URLSearchParams(formData);
  
  fetch(`${window.location.pathname}?${params.toString()}`, {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      updateWebhooksTable(data.data);
    } else {
      showNotification(data.error || 'Failed to filter webhooks', 'error');
    }
  })
  .catch(error => {
    console.error('Error applying filters:', error);
    showNotification('Failed to apply filters', 'error');
  });
}

function initializeHealthCheck() {
  const healthCheckBtn = document.getElementById('health-check-btn');
  if (!healthCheckBtn) return;

  healthCheckBtn.addEventListener('click', function() {
    performHealthCheck();
  });
}

function performHealthCheck() {
  const button = document.getElementById('health-check-btn');
  const originalText = button.textContent;
  
  button.textContent = 'Checking...';
  button.disabled = true;
  
  fetch('/admin/webhooks/health_check', {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      displayHealthReport(data.health_report);
      showNotification('Health check completed', 'success');
    } else {
      showNotification('Health check failed', 'error');
    }
  })
  .catch(error => {
    console.error('Health check error:', error);
    showNotification('Health check failed', 'error');
  })
  .finally(() => {
    button.textContent = originalText;
    button.disabled = false;
  });
}

function displayHealthReport(report) {
  // Update health summary cards
  updateHealthSummary(report.health_summary);
  
  // Display issues and recommendations
  displayIssues(report.issues);
  displayRecommendations(report.recommendations);
}

function initializeExport() {
  const exportBtns = document.querySelectorAll('[data-export-format]');
  
  exportBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      const format = this.dataset.exportFormat;
      exportWebhooks(format);
    });
  });
}

function exportWebhooks(format) {
  const params = new URLSearchParams(window.location.search);
  params.set('format', format);
  
  window.location.href = `/admin/webhooks/export?${params.toString()}`;
}

function showNotification(message, type) {
  console.log(`${type.toUpperCase()}: ${message}`);
}
=end
