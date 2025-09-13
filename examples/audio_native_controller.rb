# frozen_string_literal: true

# Example Rails controller for Audio Native functionality
# This demonstrates how to integrate ElevenLabs Audio Native API in a Rails application

class AudioNativeController < ApplicationController
  before_action :initialize_client

  # POST /audio_native/create_project
  # Create an Audio Native project with embeddable player
  def create_project
    project_name = params[:name]

    unless project_name.present?
      return render json: { error: "name is required" }, status: :bad_request
    end

    begin
      project_params = {
        author: params[:author],
        title: params[:title],
        voice_id: params[:voice_id],
        model_id: params[:model_id],
        text_color: params[:text_color],
        background_color: params[:background_color],
        auto_convert: params[:auto_convert] == "true",
        apply_text_normalization: params[:apply_text_normalization] || "auto"
      }

      # Add file if provided
      if params[:content_file].present?
        project_params[:file] = params[:content_file].tempfile
        project_params[:filename] = params[:content_file].original_filename
      end

      project = @client.audio_native.create(project_name, **project_params.compact)

      render json: {
        project_id: project["project_id"],
        converting: project["converting"],
        html_snippet: project["html_snippet"],
        embed_url: generate_embed_url(project["project_id"]),
        status: "created"
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid project parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /audio_native/:project_id/update_content
  # Update content for an existing Audio Native project
  def update_content
    project_id = params[:project_id]
    content_file = params[:content_file]

    unless project_id.present?
      return render json: { error: "project_id is required" }, status: :bad_request
    end

    begin
      update_params = {
        auto_convert: params[:auto_convert] == "true",
        auto_publish: params[:auto_publish] == "true"
      }

      # Add file if provided
      if content_file.present?
        update_params[:file] = content_file.tempfile
        update_params[:filename] = content_file.original_filename
      end

      result = @client.audio_native.update_content(project_id, **update_params.compact)

      render json: {
        project_id: result["project_id"],
        converting: result["converting"],
        publishing: result["publishing"],
        html_snippet: result["html_snippet"],
        status: "updated"
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Project not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid update parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /audio_native/:project_id/settings
  # Get settings and status for an Audio Native project
  def show_settings
    project_id = params[:project_id]

    unless project_id.present?
      return render json: { error: "project_id is required" }, status: :bad_request
    end

    begin
      settings = @client.audio_native.get_settings(project_id)

      render json: {
        project_id: project_id,
        enabled: settings["enabled"],
        snapshot_id: settings["snapshot_id"],
        settings: settings["settings"],
        status: settings["settings"]&.dig("status"),
        audio_url: settings["settings"]&.dig("audio_url"),
        ready_for_embed: settings["settings"]&.dig("status") == "ready"
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Project not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /audio_native/:project_id/embed
  # Get embeddable HTML for the Audio Native player
  def embed
    project_id = params[:project_id]

    unless project_id.present?
      return render json: { error: "project_id is required" }, status: :bad_request
    end

    begin
      settings = @client.audio_native.get_settings(project_id)

      if settings["settings"]&.dig("status") != "ready"
        return render json: { 
          error: "Project not ready for embedding", 
          status: settings["settings"]&.dig("status"),
          converting: settings["settings"]&.dig("status") == "converting"
        }, status: :unprocessable_entity
      end

      # Generate enhanced HTML snippet with custom styling
      html_snippet = generate_enhanced_embed_html(project_id, settings)

      render json: {
        project_id: project_id,
        html_snippet: html_snippet,
        audio_url: settings["settings"]["audio_url"],
        embed_instructions: {
          html: "Copy the html_snippet and paste it into your webpage",
          iframe: "Use the iframe_url for iframe embedding",
          javascript: "Include the JavaScript snippet for dynamic loading"
        },
        iframe_url: generate_iframe_url(project_id)
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Project not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /audio_native/batch_create
  # Create multiple Audio Native projects from a batch of content
  def batch_create
    projects_data = params[:projects]

    unless projects_data.present?
      return render json: { error: "projects data is required" }, status: :bad_request
    end

    results = []
    errors = []

    projects_data.each_with_index do |project_data, index|
      begin
        project_params = {
          author: project_data[:author],
          title: project_data[:title],
          voice_id: project_data[:voice_id] || params[:default_voice_id],
          auto_convert: project_data[:auto_convert] == "true"
        }

        # Add file if provided
        if project_data[:content_file].present?
          project_params[:file] = project_data[:content_file].tempfile
          project_params[:filename] = project_data[:content_file].original_filename
        end

        project = @client.audio_native.create(
          project_data[:name],
          **project_params.compact
        )

        results << {
          name: project_data[:name],
          project_id: project["project_id"],
          html_snippet: project["html_snippet"],
          converting: project["converting"],
          status: "created"
        }

      rescue ElevenlabsClient::APIError => e
        errors << {
          name: project_data[:name],
          error: e.message,
          index: index
        }
      end
    end

    render json: {
      results: results,
      errors: errors,
      total_created: results.length,
      total_errors: errors.length
    }
  end

  # GET /audio_native/projects
  # List all Audio Native projects (mock implementation - API doesn't provide this)
  def index
    # Note: This would typically come from your database
    # The ElevenLabs API doesn't provide a list projects endpoint
    
    # Mock response showing how you might track projects
    render json: {
      message: "Project listing would come from your application database",
      example_structure: {
        projects: [
          {
            id: "local_id_1",
            project_id: "elevenlabs_project_id_1",
            name: "My Article",
            status: "ready",
            created_at: "2024-01-01T00:00:00Z",
            audio_url: "https://example.com/audio.mp3"
          }
        ]
      },
      note: "Store project IDs in your database to track Audio Native projects"
    }
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  def generate_embed_url(project_id)
    # This would be your application's embed URL
    "#{request.base_url}/audio_native/#{project_id}/embed"
  end

  def generate_iframe_url(project_id)
    # This would be your application's iframe URL
    "#{request.base_url}/audio_native/#{project_id}/player"
  end

  def generate_enhanced_embed_html(project_id, settings)
    # Enhanced HTML with custom styling and controls
    base_snippet = settings.dig("html_snippet") || "<div id='audio-native-player'></div>"
    
    <<~HTML
      <div class="audio-native-container" data-project-id="#{project_id}">
        #{base_snippet}
        <div class="audio-native-controls">
          <button class="audio-native-play-pause">⏯️</button>
          <div class="audio-native-progress">
            <div class="audio-native-progress-bar"></div>
          </div>
          <div class="audio-native-time">
            <span class="current-time">0:00</span> / 
            <span class="total-time">0:00</span>
          </div>
        </div>
        <style>
          .audio-native-container {
            max-width: 100%;
            margin: 1rem 0;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .audio-native-controls {
            display: flex;
            align-items: center;
            padding: 0.5rem;
            background: #f5f5f5;
            border-radius: 0 0 8px 8px;
          }
        </style>
      </div>
    HTML
  end

  # Strong parameters for audio native
  def audio_native_params
    params.permit(
      :name,
      :author,
      :title,
      :voice_id,
      :model_id,
      :text_color,
      :background_color,
      :auto_convert,
      :auto_publish,
      :apply_text_normalization,
      :content_file,
      :default_voice_id,
      projects: [
        :name, :author, :title, :voice_id, :auto_convert, :content_file
      ]
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :audio_native do
#     get :index, to: :index
#     post :create_project
#     post :batch_create
#     get ':project_id/settings', to: :show_settings
#     post ':project_id/update_content', to: :update_content
#     get ':project_id/embed', to: :embed
#   end
# end

# Example usage in views:
#
# <%= form_with url: audio_native_create_project_path, multipart: true do |form| %>
#   <%= form.text_field :name, placeholder: "Project name", required: true %>
#   <%= form.text_field :title, placeholder: "Article title" %>
#   <%= form.text_field :author, placeholder: "Author name" %>
#   <%= form.file_field :content_file, accept: ".html,.txt", required: true %>
#   <%= form.select :voice_id, options_for_select([
#     ["Professional Female", "21m00Tcm4TlvDq8ikWAM"],
#     ["Casual Male", "pNInz6obpgDQGcFmaJgB"]
#   ]), { prompt: "Select voice" } %>
#   <%= form.check_box :auto_convert %>
#   <%= form.label :auto_convert, "Auto-convert to audio" %>
#   <%= form.submit "Create Audio Native Project" %>
# <% end %>
