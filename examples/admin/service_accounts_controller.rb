# frozen_string_literal: true

# Example Rails controller demonstrating the ElevenlabsClient Admin::ServiceAccounts API
# This controller shows how to integrate service account management functionality
# into a Rails application with proper error handling and user feedback.
#
# Usage:
# 1. Include this controller in your Rails application
# 2. Add routes for the service account management actions
# 3. Ensure the Elevenlabs API key is configured in your environment
# 4. Customize the views and error handling for your application's needs
#
# Routes example:
#   Rails.application.routes.draw do
#     namespace :admin do
#       resources :service_accounts, only: [:index] do
#         collection do
#           get :list
#         end
#       end
#     end
#   end

class Admin::ServiceAccountsController < ApplicationController
  before_action :authenticate_admin!
  before_action :initialize_client
  before_action :set_pagination_params, only: [:index, :list]

  # GET /admin/service_accounts
  # List all service accounts in the workspace
  def index
    fetch_service_accounts
  end

  # GET /admin/service_accounts/list
  # Alternative endpoint for listing service accounts (API format)
  def list
    fetch_service_accounts
  end

  private

  def initialize_client
    @client = ElevenlabsClient::Client.new
    @service_accounts = @client.service_accounts
  rescue StandardError => e
    Rails.logger.error "Failed to initialize ElevenLabs client: #{e.message}"
    render_error("Service temporarily unavailable", :service_unavailable)
  end

  def set_pagination_params
    @page = params[:page]&.to_i || 1
    @per_page = [params[:per_page]&.to_i || 20, 100].min # Max 100 items per page
  end

  def fetch_service_accounts
    return unless @service_accounts

    begin
      result = @service_accounts.get_service_accounts
      
      @service_accounts_data = result["service-accounts"] || []
      @total_count = @service_accounts_data.count
      
      # Apply pagination for display
      @paginated_accounts = paginate_accounts(@service_accounts_data)
      
      # Calculate statistics
      @statistics = calculate_statistics(@service_accounts_data)
      
      Rails.logger.info "Retrieved #{@total_count} service accounts"

      respond_to do |format|
        format.json { render json: success_response }
        format.html # Renders the index.html.erb view
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

  def paginate_accounts(accounts)
    offset = (@page - 1) * @per_page
    accounts.slice(offset, @per_page) || []
  end

  def calculate_statistics(accounts)
    return default_statistics if accounts.empty?

    total_api_keys = accounts.sum { |account| account["api-keys"]&.count || 0 }
    active_api_keys = accounts.sum do |account|
      (account["api-keys"] || []).count { |key| !key["is_disabled"] }
    end
    disabled_api_keys = total_api_keys - active_api_keys
    
    total_character_limit = accounts.sum do |account|
      (account["api-keys"] || []).sum { |key| key["character_limit"] || 0 }
    end
    
    total_character_usage = accounts.sum do |account|
      (account["api-keys"] || []).sum { |key| key["character_count"] || 0 }
    end

    usage_percentage = total_character_limit > 0 ? 
      (total_character_usage.to_f / total_character_limit * 100).round(2) : 0

    permissions_summary = calculate_permissions_summary(accounts)

    {
      total_service_accounts: accounts.count,
      total_api_keys: total_api_keys,
      active_api_keys: active_api_keys,
      disabled_api_keys: disabled_api_keys,
      total_character_limit: total_character_limit,
      total_character_usage: total_character_usage,
      usage_percentage: usage_percentage,
      permissions_summary: permissions_summary,
      average_keys_per_account: accounts.count > 0 ? (total_api_keys.to_f / accounts.count).round(2) : 0
    }
  end

  def calculate_permissions_summary(accounts)
    permissions_count = Hash.new(0)
    
    accounts.each do |account|
      (account["api-keys"] || []).each do |api_key|
        (api_key["permissions"] || []).each do |permission|
          permissions_count[permission] += 1
        end
      end
    end
    
    permissions_count.sort_by { |_, count| -count }.to_h
  end

  def default_statistics
    {
      total_service_accounts: 0,
      total_api_keys: 0,
      active_api_keys: 0,
      disabled_api_keys: 0,
      total_character_limit: 0,
      total_character_usage: 0,
      usage_percentage: 0,
      permissions_summary: {},
      average_keys_per_account: 0
    }
  end

  def success_response
    {
      success: true,
      data: {
        service_accounts: @paginated_accounts,
        pagination: {
          page: @page,
          per_page: @per_page,
          total_count: @total_count,
          total_pages: (@total_count.to_f / @per_page).ceil,
          has_next_page: @page * @per_page < @total_count,
          has_prev_page: @page > 1
        },
        statistics: @statistics
      },
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
    Rails.logger.error "Unexpected error in service accounts retrieval: #{error.message}"
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
    # authorize! :manage, :admin_service_accounts
  end
end

# Example view helper methods that could be added to ApplicationHelper
module Admin::ServiceAccountsHelper
  def service_account_status_badge(service_account)
    api_keys = service_account["api-keys"] || []
    active_keys = api_keys.count { |key| !key["is_disabled"] }
    total_keys = api_keys.count

    if total_keys == 0
      content_tag :span, "No API Keys", class: "badge badge-secondary"
    elsif active_keys == total_keys
      content_tag :span, "All Active (#{active_keys})", class: "badge badge-success"
    elsif active_keys > 0
      content_tag :span, "Partial (#{active_keys}/#{total_keys})", class: "badge badge-warning"
    else
      content_tag :span, "All Disabled (#{total_keys})", class: "badge badge-danger"
    end
  end

  def api_key_permissions_badges(permissions)
    permissions.map do |permission|
      badge_class = case permission
                   when "text_to_speech"
                     "badge-primary"
                   when "speech_to_text"
                     "badge-info"
                   when "voice_cloning"
                     "badge-success"
                   else
                     "badge-secondary"
                   end
      
      content_tag :span, permission.humanize, class: "badge #{badge_class} mr-1"
    end.join.html_safe
  end

  def character_usage_progress_bar(character_count, character_limit)
    return content_tag(:div, "No limit set", class: "text-muted") if character_limit == 0

    percentage = (character_count.to_f / character_limit * 100).round(2)
    progress_class = case percentage
                    when 0..50
                      "bg-success"
                    when 51..80
                      "bg-warning"
                    else
                      "bg-danger"
                    end

    content_tag :div, class: "progress" do
      content_tag :div, 
                  "#{number_with_delimiter(character_count)} / #{number_with_delimiter(character_limit)} (#{percentage}%)",
                  class: "progress-bar #{progress_class}",
                  style: "width: #{[percentage, 100].min}%",
                  role: "progressbar",
                  "aria-valuenow": percentage,
                  "aria-valuemin": 0,
                  "aria-valuemax": 100
    end
  end

  def service_account_created_date(created_at_unix)
    Time.at(created_at_unix).strftime("%B %d, %Y")
  rescue
    "Unknown"
  end

  def api_key_hint_display(hint)
    return "No hint available" if hint.blank?
    
    # Show only first 4 and last 4 characters if hint is long enough
    if hint.length > 12
      "#{hint[0..3]}...#{hint[-4..-1]}"
    else
      hint
    end
  end

  def service_accounts_summary_cards(statistics)
    [
      {
        title: "Total Service Accounts",
        value: statistics[:total_service_accounts],
        icon: "fas fa-users",
        color: "primary"
      },
      {
        title: "Total API Keys",
        value: statistics[:total_api_keys],
        icon: "fas fa-key",
        color: "info"
      },
      {
        title: "Active API Keys",
        value: statistics[:active_api_keys],
        icon: "fas fa-check-circle",
        color: "success"
      },
      {
        title: "Character Usage",
        value: "#{statistics[:usage_percentage]}%",
        icon: "fas fa-chart-line",
        color: statistics[:usage_percentage] > 80 ? "danger" : "warning"
      }
    ]
  end
end

# Example JavaScript for enhanced UX (app/assets/javascripts/admin/service_accounts.js)
=begin
document.addEventListener('DOMContentLoaded', function() {
  // Initialize service accounts management
  initializeServiceAccountsTable();
  initializeFiltering();
  initializeExport();
});

function initializeServiceAccountsTable() {
  const table = document.getElementById('service-accounts-table');
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
  // Implement table sorting logic
  console.log(`Sorting by ${column} in ${direction} order`);
  
  // This would typically make an AJAX request to re-fetch sorted data
  // or sort the existing table rows client-side
}

function updateSortIndicators(activeHeader, direction) {
  // Remove existing sort indicators
  document.querySelectorAll('th[data-sortable] .sort-indicator').forEach(indicator => {
    indicator.remove();
  });
  
  // Add sort indicator to active header
  const indicator = document.createElement('span');
  indicator.className = 'sort-indicator';
  indicator.innerHTML = direction === 'asc' ? ' ↑' : ' ↓';
  activeHeader.appendChild(indicator);
  
  // Update data attribute
  activeHeader.dataset.direction = direction;
}

function initializeFiltering() {
  const filterForm = document.getElementById('service-accounts-filter');
  if (!filterForm) return;

  filterForm.addEventListener('submit', function(e) {
    e.preventDefault();
    applyFilters();
  });

  // Real-time search
  const searchInput = document.getElementById('search-input');
  if (searchInput) {
    let searchTimeout;
    searchInput.addEventListener('input', function() {
      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(() => {
        applyFilters();
      }, 500);
    });
  }
}

function applyFilters() {
  const formData = new FormData(document.getElementById('service-accounts-filter'));
  const params = new URLSearchParams(formData);
  
  // Update URL and fetch filtered results
  const newUrl = `${window.location.pathname}?${params.toString()}`;
  history.pushState({}, '', newUrl);
  
  fetch(newUrl, {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      updateServiceAccountsTable(data.data);
    } else {
      showNotification(data.error || 'Failed to filter service accounts', 'error');
    }
  })
  .catch(error => {
    console.error('Error applying filters:', error);
    showNotification('Failed to apply filters', 'error');
  });
}

function updateServiceAccountsTable(data) {
  const tableBody = document.querySelector('#service-accounts-table tbody');
  if (!tableBody) return;

  // Update table content
  tableBody.innerHTML = generateTableRows(data.service_accounts);
  
  // Update pagination
  updatePagination(data.pagination);
  
  // Update statistics
  updateStatistics(data.statistics);
}

function generateTableRows(serviceAccounts) {
  return serviceAccounts.map(account => {
    const apiKeysCount = account['api-keys']?.length || 0;
    const activeKeysCount = account['api-keys']?.filter(key => !key.is_disabled).length || 0;
    
    return `
      <tr>
        <td>${escapeHtml(account.name)}</td>
        <td>${escapeHtml(account.service_account_user_id)}</td>
        <td>
          <span class="badge ${apiKeysCount > 0 ? 'badge-success' : 'badge-secondary'}">
            ${apiKeysCount} keys
          </span>
        </td>
        <td>
          <span class="badge ${activeKeysCount > 0 ? 'badge-success' : 'badge-danger'}">
            ${activeKeysCount} active
          </span>
        </td>
        <td>${formatDate(account.created_at_unix)}</td>
        <td>
          <button class="btn btn-sm btn-outline-primary" onclick="viewServiceAccount('${account.service_account_user_id}')">
            View Details
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function initializeExport() {
  const exportBtn = document.getElementById('export-service-accounts');
  if (!exportBtn) return;

  exportBtn.addEventListener('click', function() {
    exportServiceAccounts();
  });
}

function exportServiceAccounts() {
  const params = new URLSearchParams(window.location.search);
  params.set('format', 'csv');
  
  window.location.href = `${window.location.pathname}?${params.toString()}`;
}

function viewServiceAccount(serviceAccountId) {
  // Implement service account detail view
  console.log(`Viewing service account: ${serviceAccountId}`);
  
  // This could open a modal or navigate to a detail page
}

function showNotification(message, type) {
  // Implement your notification system
  console.log(`${type.toUpperCase()}: ${message}`);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function formatDate(unixTimestamp) {
  return new Date(unixTimestamp * 1000).toLocaleDateString();
}
=end

# Example Stimulus controller (app/javascript/controllers/admin_service_accounts_controller.js)
=begin
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "filterForm", "searchInput", "statisticsCards"]
  static values = { 
    refreshInterval: { type: Number, default: 30000 }, // 30 seconds
    autoRefresh: { type: Boolean, default: false }
  }

  connect() {
    console.log("Admin service accounts controller connected")
    
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    }
  }

  disconnect() {
    this.stopAutoRefresh()
  }

  refresh(event) {
    if (event) event.preventDefault()
    
    this.fetchServiceAccounts()
  }

  async fetchServiceAccounts() {
    try {
      const params = new URLSearchParams(new FormData(this.filterFormTarget))
      const response = await fetch(`${window.location.pathname}?${params.toString()}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.updateTable(data.data)
        this.showNotification('Service accounts refreshed', 'success')
      } else {
        throw new Error(data.error || 'Failed to fetch service accounts')
      }
    } catch (error) {
      console.error('Error fetching service accounts:', error)
      this.showNotification(error.message || 'Failed to refresh service accounts', 'error')
    }
  }

  filter(event) {
    event.preventDefault()
    this.fetchServiceAccounts()
  }

  search() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.fetchServiceAccounts()
    }, 500)
  }

  updateTable(data) {
    // Update table content
    const tbody = this.tableTarget.querySelector('tbody')
    if (tbody) {
      tbody.innerHTML = this.generateTableRows(data.service_accounts)
    }
    
    // Update statistics cards
    this.updateStatistics(data.statistics)
  }

  generateTableRows(serviceAccounts) {
    return serviceAccounts.map(account => {
      const apiKeysCount = account['api-keys']?.length || 0
      const activeKeysCount = account['api-keys']?.filter(key => !key.is_disabled).length || 0
      
      return `
        <tr>
          <td>${this.escapeHtml(account.name)}</td>
          <td><code>${this.escapeHtml(account.service_account_user_id)}</code></td>
          <td>
            <span class="badge ${apiKeysCount > 0 ? 'badge-success' : 'badge-secondary'}">
              ${apiKeysCount} keys
            </span>
          </td>
          <td>
            <span class="badge ${activeKeysCount > 0 ? 'badge-success' : 'badge-danger'}">
              ${activeKeysCount} active
            </span>
          </td>
          <td>${this.formatDate(account.created_at_unix)}</td>
          <td>
            <button class="btn btn-sm btn-outline-primary" 
                    data-action="click->admin-service-accounts#viewDetails"
                    data-service-account-id="${account.service_account_user_id}">
              View Details
            </button>
          </td>
        </tr>
      `
    }).join('')
  }

  updateStatistics(statistics) {
    if (!this.hasStatisticsCardsTarget) return

    const cards = [
      { key: 'total_service_accounts', label: 'Total Accounts' },
      { key: 'total_api_keys', label: 'Total API Keys' },
      { key: 'active_api_keys', label: 'Active Keys' },
      { key: 'usage_percentage', label: 'Usage %' }
    ]

    cards.forEach(card => {
      const element = this.statisticsCardsTarget.querySelector(`[data-stat="${card.key}"]`)
      if (element) {
        const value = card.key === 'usage_percentage' 
          ? `${statistics[card.key]}%` 
          : statistics[card.key]
        element.textContent = value
      }
    })
  }

  viewDetails(event) {
    const serviceAccountId = event.target.dataset.serviceAccountId
    console.log(`Viewing details for service account: ${serviceAccountId}`)
    
    // Implement detail view logic
    // This could open a modal, navigate to a detail page, or expand inline details
  }

  startAutoRefresh() {
    this.stopAutoRefresh() // Clear any existing interval
    
    this.refreshInterval = setInterval(() => {
      this.fetchServiceAccounts()
    }, this.refreshIntervalValue)
  }

  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }

  showNotification(message, type) {
    // Dispatch a custom event for the notification system
    const event = new CustomEvent('notification', {
      detail: { message, type }
    })
    document.dispatchEvent(event)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  formatDate(unixTimestamp) {
    return new Date(unixTimestamp * 1000).toLocaleDateString()
  }
}
=end
