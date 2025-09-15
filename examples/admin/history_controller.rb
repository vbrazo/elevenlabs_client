# frozen_string_literal: true

# Example Rails controller for Admin History functionality
# This demonstrates how to integrate ElevenLabs Admin History API in a Rails application

class Admin::HistoryController < ApplicationController
  before_action :initialize_client

  # GET /admin/history
  # List generated audio history with optional filtering and pagination
  def index
    begin
      options = build_list_options

      @history = @client.history.list(**options)

      render json: {
        history: @history["history"],
        pagination: {
          has_more: @history["has_more"],
          last_item_id: @history["last_history_item_id"],
          scanned_until: @history["scanned_until"],
          current_page_size: @history["history"].length
        },
        filters_applied: options.except(:page_size, :start_after_history_item_id),
        total_displayed: @history["history"].length
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /admin/history/:id
  # Get detailed information for a specific history item
  def show
    history_item_id = params[:id]

    begin
      @item = @client.history.get(history_item_id)

      render json: {
        history_item: @item,
        metadata: {
          created_at: Time.at(@item["date_unix"]).iso8601,
          character_usage: @item["character_count_change_to"] - @item["character_count_change_from"],
          audio_available: @item["content_type"].present?,
          has_feedback: @item["feedback"].present?
        }
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "History item not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # DELETE /admin/history/:id
  # Delete a specific history item
  def destroy
    history_item_id = params[:id]

    begin
      result = @client.history.delete(history_item_id)

      render json: {
        history_item_id: history_item_id,
        status: result["status"],
        message: "History item deleted successfully"
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "History item not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Cannot delete this item", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /admin/history/:id/audio
  # Download the audio file for a history item
  def download_audio
    history_item_id = params[:id]

    begin
      audio_data = @client.history.get_audio(history_item_id)

      # Get item details for filename
      item = @client.history.get(history_item_id)
      filename = generate_audio_filename(item)

      send_data audio_data,
                type: item["content_type"] || "audio/mpeg",
                filename: filename,
                disposition: "attachment"

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Audio not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Audio not available", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /admin/history/bulk_download
  # Download multiple history items as a ZIP file or single audio file
  def bulk_download
    history_item_ids = params[:history_item_ids]
    output_format = params[:output_format]

    unless history_item_ids.present?
      return render json: { error: "history_item_ids are required" }, status: :bad_request
    end

    begin
      download_data = @client.history.download(history_item_ids, output_format: output_format)

      if history_item_ids.length == 1
        # Single item - return as audio file
        item = @client.history.get(history_item_ids.first)
        filename = generate_audio_filename(item, output_format)
        content_type = output_format == "wav" ? "audio/wav" : "audio/mpeg"
        
        send_data download_data,
                  type: content_type,
                  filename: filename,
                  disposition: "attachment"
      else
        # Multiple items - return as ZIP
        zip_filename = "history_items_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip"
        
        send_data download_data,
                  type: "application/zip",
                  filename: zip_filename,
                  disposition: "attachment"
      end

    rescue ElevenlabsClient::BadRequestError => e
      render json: { error: "Invalid download request", details: e.message }, status: :bad_request
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Some items not found", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /admin/history/bulk_delete
  # Delete multiple history items
  def bulk_delete
    history_item_ids = params[:history_item_ids]

    unless history_item_ids.present?
      return render json: { error: "history_item_ids are required" }, status: :bad_request
    end

    results = []
    errors = []

    history_item_ids.each do |item_id|
      begin
        result = @client.history.delete(item_id)
        results << {
          history_item_id: item_id,
          status: result["status"]
        }
      rescue ElevenlabsClient::APIError => e
        errors << {
          history_item_id: item_id,
          error: e.message
        }
      end
    end

    render json: {
      results: results,
      errors: errors,
      summary: {
        total_requested: history_item_ids.length,
        successful_deletions: results.length,
        failed_deletions: errors.length
      }
    }
  end

  # POST /admin/history/cleanup
  # Intelligent cleanup of old history items
  def cleanup
    days_to_keep = params[:days_to_keep]&.to_i || 30
    keep_favorites = params[:keep_favorites] != "false"
    dry_run = params[:dry_run] == "true"

    cutoff_date = Time.now.to_i - (days_to_keep * 24 * 60 * 60)
    
    items_to_delete = []
    start_after_id = nil

    # Collect items to delete
    loop do
      begin
        page = @client.history.list(
          page_size: 100,
          start_after_history_item_id: start_after_id
        )

        page['history'].each do |item|
          # Skip if too recent
          next if item['date_unix'] >= cutoff_date

          # Skip favorites if requested
          if keep_favorites && item['feedback']&.dig('thumbs_up')
            next
          end

          items_to_delete << item
        end

        break unless page['has_more']
        start_after_id = page['last_history_item_id']

      rescue ElevenlabsClient::APIError => e
        return render json: { error: "Failed to fetch history", details: e.message }, status: :internal_server_error
      end
    end

    # Perform deletions (unless dry run)
    deleted_count = 0
    deletion_errors = []

    unless dry_run
      items_to_delete.each do |item|
        begin
          @client.history.delete(item['history_item_id'])
          deleted_count += 1
        rescue ElevenlabsClient::APIError => e
          deletion_errors << {
            history_item_id: item['history_item_id'],
            text: item['text'],
            error: e.message
          }
        end
      end
    end

    render json: {
      cleanup_summary: {
        cutoff_date: Time.at(cutoff_date).iso8601,
        days_kept: days_to_keep,
        keep_favorites: keep_favorites,
        dry_run: dry_run,
        items_identified_for_deletion: items_to_delete.length,
        items_actually_deleted: deleted_count,
        deletion_errors: deletion_errors.length
      },
      items_to_delete: items_to_delete.map do |item|
        {
          history_item_id: item['history_item_id'],
          text: item['text'][0..100],
          voice_name: item['voice_name'],
          created_at: Time.at(item['date_unix']).iso8601,
          character_count: item['character_count_change_to'] - item['character_count_change_from']
        }
      end,
      errors: deletion_errors
    }
  end

  # GET /admin/history/analytics
  # Get analytics about history usage
  def analytics
    begin
      # Get recent history for analytics
      recent_history = @client.history.list(page_size: 1000)
      items = recent_history['history']

      # Calculate analytics
      analytics = {
        total_items: items.length,
        total_characters: items.sum { |item| item['character_count_change_to'] - item['character_count_change_from'] },
        voice_usage: calculate_voice_usage(items),
        model_usage: calculate_model_usage(items),
        source_breakdown: calculate_source_breakdown(items),
        daily_usage: calculate_daily_usage(items),
        average_character_count: calculate_average_character_count(items),
        most_recent_item: items.first ? Time.at(items.first['date_unix']).iso8601 : nil,
        oldest_item: items.last ? Time.at(items.last['date_unix']).iso8601 : nil
      }

      render json: {
        analytics: analytics,
        data_period: {
          note: "Analytics based on most recent #{items.length} items",
          has_more_data: recent_history['has_more']
        }
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /admin/history/export
  # Export history data as CSV
  def export
    begin
      format = params[:format]&.downcase || "csv"
      
      unless %w[csv json].include?(format)
        return render json: { error: "Invalid format. Supported: csv, json" }, status: :bad_request
      end

      # Get all history items
      all_items = fetch_all_history_items

      case format
      when "csv"
        csv_data = generate_csv_export(all_items)
        send_data csv_data,
                  type: "text/csv",
                  filename: "history_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                  disposition: "attachment"
      when "json"
        json_data = generate_json_export(all_items)
        send_data json_data,
                  type: "application/json",
                  filename: "history_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
                  disposition: "attachment"
      end

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  def build_list_options
    options = {}
    options[:page_size] = [params[:page_size]&.to_i || 50, 1000].min
    options[:start_after_history_item_id] = params[:after] if params[:after].present?
    options[:voice_id] = params[:voice_id] if params[:voice_id].present?
    options[:source] = params[:source] if params[:source].present?
    
    # Search requires source parameter
    if params[:search].present?
      options[:search] = params[:search]
      options[:source] ||= "TTS"  # Default to TTS if not specified
    end
    
    options.compact
  end

  def generate_audio_filename(item, format = nil)
    extension = case format
                when "wav" then ".wav"
                else ".mp3"
                end
    
    # Create safe filename from text
    safe_text = item["text"]&.gsub(/[^\w\s-]/, "")&.strip&.gsub(/\s+/, "_")&.[](0..50) || "audio"
    timestamp = Time.at(item["date_unix"]).strftime("%Y%m%d_%H%M%S")
    
    "#{timestamp}_#{safe_text}_#{item['voice_name']&.gsub(/\s+/, "_")}#{extension}"
  end

  def fetch_all_history_items
    all_items = []
    start_after_id = nil

    loop do
      options = { page_size: 100 }
      options[:start_after_history_item_id] = start_after_id if start_after_id

      page = @client.history.list(**options)
      all_items.concat(page['history'])

      break unless page['has_more']
      start_after_id = page['last_history_item_id']
    end

    all_items
  end

  def calculate_voice_usage(items)
    usage = Hash.new(0)
    items.each do |item|
      voice_key = "#{item['voice_name']} (#{item['voice_category']})"
      usage[voice_key] += 1
    end
    usage.sort_by { |_, count| -count }.to_h
  end

  def calculate_model_usage(items)
    usage = Hash.new(0)
    items.each do |item|
      usage[item['model_id']] += 1 if item['model_id']
    end
    usage.sort_by { |_, count| -count }.to_h
  end

  def calculate_source_breakdown(items)
    breakdown = Hash.new(0)
    items.each do |item|
      breakdown[item['source']] += 1 if item['source']
    end
    breakdown
  end

  def calculate_daily_usage(items)
    daily = Hash.new(0)
    items.each do |item|
      date = Time.at(item['date_unix']).strftime('%Y-%m-%d')
      daily[date] += 1
    end
    daily.sort.reverse.to_h
  end

  def calculate_average_character_count(items)
    return 0 if items.empty?
    
    total_chars = items.sum { |item| item['character_count_change_to'] - item['character_count_change_from'] }
    (total_chars.to_f / items.length).round(2)
  end

  def generate_csv_export(items)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << [
        "History Item ID", "Date", "Text", "Voice Name", "Voice Category",
        "Model ID", "Source", "Character Count", "Content Type"
      ]
      
      items.each do |item|
        csv << [
          item['history_item_id'],
          Time.at(item['date_unix']).iso8601,
          item['text'],
          item['voice_name'],
          item['voice_category'],
          item['model_id'],
          item['source'],
          item['character_count_change_to'] - item['character_count_change_from'],
          item['content_type']
        ]
      end
    end
  end

  def generate_json_export(items)
    export_data = {
      export_date: Time.current.iso8601,
      total_items: items.length,
      items: items.map do |item|
        {
          history_item_id: item['history_item_id'],
          created_at: Time.at(item['date_unix']).iso8601,
          text: item['text'],
          voice: {
            id: item['voice_id'],
            name: item['voice_name'],
            category: item['voice_category']
          },
          model_id: item['model_id'],
          source: item['source'],
          character_count: item['character_count_change_to'] - item['character_count_change_from'],
          content_type: item['content_type'],
          settings: item['settings'],
          feedback: item['feedback']
        }
      end
    }
    
    export_data.to_json
  end

  # Strong parameters for history operations
  def history_params
    params.permit(
      :page_size,
      :after,
      :voice_id,
      :search,
      :source,
      :output_format,
      :days_to_keep,
      :keep_favorites,
      :dry_run,
      :format,
      history_item_ids: []
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :admin do
#     resources :history, only: [:index, :show, :destroy] do
#       member do
#         get :download_audio
#       end
#       
#       collection do
#         post :bulk_download
#         post :bulk_delete
#         post :cleanup
#         get :analytics
#         get :export
#       end
#     end
#   end
# end

# Example usage in views:
#
# <!-- History listing with filters -->
# <%= form_with url: admin_history_index_path, method: :get, local: true do |form| %>
#   <%= form.text_field :search, placeholder: "Search history...", value: params[:search] %>
#   <%= form.select :voice_id, options_for_select([
#     ["All Voices", ""],
#     ["Rachel", "21m00Tcm4TlvDq8ikWAM"],
#     ["Josh", "TxGEqnHWrfWFTfGW9XjX"]
#   ]), { selected: params[:voice_id] } %>
#   <%= form.select :source, options_for_select([
#     ["All Sources", ""],
#     ["Text-to-Speech", "TTS"],
#     ["Speech-to-Speech", "STS"]
#   ]), { selected: params[:source] } %>
#   <%= form.number_field :page_size, placeholder: "Page size", value: params[:page_size] || 50, min: 1, max: 1000 %>
#   <%= form.submit "Filter" %>
# <% end %>
#
# <!-- Bulk operations -->
# <%= form_with url: admin_history_bulk_download_path, method: :post do |form| %>
#   <% @history["history"].each do |item| %>
#     <%= form.check_box "history_item_ids[]", { value: item["history_item_id"] }, item["history_item_id"], "" %>
#     <%= form.label "history_item_ids_#{item['history_item_id']}", item["text"][0..50] %>
#   <% end %>
#   <%= form.select :output_format, options_for_select([
#     ["MP3 (default)", "default"],
#     ["WAV", "wav"]
#   ]) %>
#   <%= form.submit "Download Selected" %>
# <% end %>
#
# <!-- Cleanup form -->
# <%= form_with url: admin_history_cleanup_path, method: :post do |form| %>
#   <%= form.number_field :days_to_keep, placeholder: "Days to keep", value: 30, min: 1 %>
#   <%= form.check_box :keep_favorites, checked: true %>
#   <%= form.label :keep_favorites, "Keep favorited items" %>
#   <%= form.check_box :dry_run, checked: true %>
#   <%= form.label :dry_run, "Dry run (preview only)" %>
#   <%= form.submit "Clean Up History" %>
# <% end %>
