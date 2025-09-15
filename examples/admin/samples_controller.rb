# frozen_string_literal: true

# Example Rails controller demonstrating the ElevenlabsClient Admin::Samples API
# This controller shows how to integrate voice sample deletion functionality
# into a Rails application with proper error handling and user feedback.
#
# Usage:
# 1. Include this controller in your Rails application
# 2. Add routes for the sample management actions
# 3. Ensure the Elevenlabs API key is configured in your environment
# 4. Customize the views and error handling for your application's needs
#
# Routes example:
#   Rails.application.routes.draw do
#     namespace :admin do
#       resources :samples, only: [:destroy] do
#         member do
#           delete :delete_sample
#         end
#       end
#     end
#   end

class Admin::SamplesController < ApplicationController
  before_action :authenticate_admin!
  before_action :initialize_client
  before_action :set_voice_and_sample_ids, only: [:destroy, :delete_sample]

  # DELETE /admin/samples/:id
  # Delete a voice sample by ID
  def destroy
    delete_sample_action
  end

  # DELETE /admin/samples/:id/delete_sample
  # Alternative endpoint for deleting a voice sample
  def delete_sample
    delete_sample_action
  end

  private

  def initialize_client
    @client = ElevenlabsClient::Client.new
    @samples = @client.samples
  rescue StandardError => e
    Rails.logger.error "Failed to initialize ElevenLabs client: #{e.message}"
    render_error("Service temporarily unavailable", :service_unavailable)
  end

  def set_voice_and_sample_ids
    @voice_id = params[:voice_id]
    @sample_id = params[:id] || params[:sample_id]

    unless @voice_id.present? && @sample_id.present?
      render_error("Voice ID and Sample ID are required", :bad_request)
    end
  end

  def delete_sample_action
    return unless @samples && @voice_id && @sample_id

    begin
      result = @samples.delete_sample(
        voice_id: @voice_id,
        sample_id: @sample_id
      )

      Rails.logger.info "Successfully deleted sample #{@sample_id} from voice #{@voice_id}"

      respond_to do |format|
        format.json { render json: success_response(result) }
        format.html do
          flash[:notice] = "Voice sample deleted successfully"
          redirect_to admin_voice_path(@voice_id)
        end
      end

    rescue ElevenlabsClient::NotFoundError => e
      handle_not_found_error(e)
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

  def handle_not_found_error(error)
    Rails.logger.warn "Voice or sample not found: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Voice or sample not found", :not_found) }
      format.html do
        flash[:alert] = "Voice or sample not found"
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def handle_authentication_error(error)
    Rails.logger.error "ElevenLabs authentication failed: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Authentication failed", :unauthorized) }
      format.html do
        flash[:alert] = "Service authentication failed"
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def handle_validation_error(error)
    Rails.logger.warn "Validation error: #{error.message}"
    
    respond_to do |format|
      format.json { render json: error_response("Invalid request parameters", :unprocessable_entity) }
      format.html do
        flash[:alert] = "Invalid voice or sample ID"
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
    Rails.logger.error "Unexpected error in samples deletion: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    respond_to do |format|
      format.json { render json: error_response("An unexpected error occurred", :internal_server_error) }
      format.html do
        flash[:alert] = "An unexpected error occurred"
        redirect_back(fallback_location: admin_root_path)
      end
    end
  end

  def success_response(result)
    {
      success: true,
      message: "Voice sample deleted successfully",
      data: result,
      voice_id: @voice_id,
      sample_id: @sample_id,
      timestamp: Time.current.iso8601
    }
  end

  def error_response(message, status)
    {
      success: false,
      error: message,
      voice_id: @voice_id,
      sample_id: @sample_id,
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
    # authorize! :manage, :admin_samples
  end
end

# Example view helper methods that could be added to ApplicationHelper
module Admin::SamplesHelper
  def sample_deletion_confirmation_message(voice_name, sample_name)
    "Are you sure you want to delete the sample '#{sample_name}' from voice '#{voice_name}'? This action cannot be undone."
  end

  def sample_deletion_button(voice_id, sample_id, options = {})
    default_options = {
      method: :delete,
      data: {
        confirm: "Are you sure you want to delete this sample? This action cannot be undone.",
        remote: true
      },
      class: "btn btn-danger btn-sm"
    }
    
    merged_options = default_options.merge(options)
    
    link_to "Delete Sample", 
            admin_sample_path(sample_id, voice_id: voice_id), 
            merged_options
  end

  def sample_status_badge(status)
    case status&.downcase
    when "ok", "success"
      content_tag :span, "Deleted", class: "badge badge-success"
    when "error", "failed"
      content_tag :span, "Error", class: "badge badge-danger"
    else
      content_tag :span, "Unknown", class: "badge badge-secondary"
    end
  end
end

# Example JavaScript for enhanced UX (app/assets/javascripts/admin/samples.js)
=begin
document.addEventListener('DOMContentLoaded', function() {
  // Handle AJAX sample deletion
  const deleteSampleButtons = document.querySelectorAll('[data-sample-delete]');
  
  deleteSampleButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      const voiceId = this.dataset.voiceId;
      const sampleId = this.dataset.sampleId;
      const sampleName = this.dataset.sampleName;
      
      if (confirm(`Are you sure you want to delete sample "${sampleName}"? This action cannot be undone.`)) {
        deleteSample(voiceId, sampleId, this);
      }
    });
  });
  
  function deleteSample(voiceId, sampleId, button) {
    // Show loading state
    const originalText = button.textContent;
    button.textContent = 'Deleting...';
    button.disabled = true;
    
    fetch(`/admin/samples/${sampleId}?voice_id=${voiceId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Remove the sample from the UI
        const sampleElement = button.closest('.sample-item');
        if (sampleElement) {
          sampleElement.remove();
        }
        
        // Show success message
        showNotification('Sample deleted successfully', 'success');
      } else {
        throw new Error(data.error || 'Failed to delete sample');
      }
    })
    .catch(error => {
      console.error('Error deleting sample:', error);
      showNotification(error.message || 'Failed to delete sample', 'error');
      
      // Restore button state
      button.textContent = originalText;
      button.disabled = false;
    });
  }
  
  function showNotification(message, type) {
    // Implement your notification system here
    // This could use Bootstrap alerts, Toastr, or a custom notification system
    console.log(`${type.toUpperCase()}: ${message}`);
  }
});
=end

# Example Stimulus controller (app/javascript/controllers/admin_samples_controller.js)
=begin
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deleteButton", "sampleItem"]
  static values = { 
    voiceId: String, 
    sampleId: String,
    sampleName: String 
  }

  connect() {
    console.log("Admin samples controller connected")
  }

  delete(event) {
    event.preventDefault()
    
    const confirmation = `Are you sure you want to delete sample "${this.sampleNameValue}"? This action cannot be undone.`
    
    if (confirm(confirmation)) {
      this.performDeletion()
    }
  }

  async performDeletion() {
    const button = this.deleteButtonTarget
    const originalText = button.textContent
    
    // Show loading state
    button.textContent = "Deleting..."
    button.disabled = true
    
    try {
      const response = await fetch(`/admin/samples/${this.sampleIdValue}?voice_id=${this.voiceIdValue}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Remove sample from UI
        if (this.hasSampleItemTarget) {
          this.sampleItemTarget.remove()
        }
        
        this.showNotification('Sample deleted successfully', 'success')
      } else {
        throw new Error(data.error || 'Failed to delete sample')
      }
    } catch (error) {
      console.error('Error deleting sample:', error)
      this.showNotification(error.message || 'Failed to delete sample', 'error')
      
      // Restore button state
      button.textContent = originalText
      button.disabled = false
    }
  }

  showNotification(message, type) {
    // Implement your notification system
    // This could dispatch a custom event or call a global notification service
    const event = new CustomEvent('notification', {
      detail: { message, type }
    })
    document.dispatchEvent(event)
  }
}
=end
