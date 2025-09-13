# frozen_string_literal: true

# Example Rails controller showing how to use ElevenLabs Dubbing
# Place this in app/controllers/dubs_controller.rb

class DubsController < ApplicationController
  before_action :validate_dub_params, only: [:create]
  before_action :find_dub, only: [:show, :resources]

  # POST /dubs
  # Create a new dubbing job
  #
  # Parameters:
  #   - file: File (required) - Audio/video file to dub
  #   - target_languages: Array (required) - Target language codes (e.g., ["es", "pt", "fr"])
  #   - name: String (optional) - Name for the dubbing job
  #   - drop_background_audio: Boolean (optional) - Remove background audio
  #   - use_profanity_filter: Boolean (optional) - Filter profanity
  #   - highest_resolution: Boolean (optional) - Use highest resolution
  #   - dubbing_studio: Boolean (optional) - Enable dubbing studio features
  def create
    client = ElevenlabsClient.new
    
    begin
      File.open(params[:file].tempfile, "rb") do |file|
        result = client.dubs.create(
          file_io: file,
          filename: params[:file].original_filename,
          target_languages: params[:target_languages],
          name: params[:name],
          **build_dub_options
        )
        
        render json: {
          dubbing_id: result["dubbing_id"],
          status: result["status"],
          name: result["name"],
          target_languages: result["target_languages"],
          message: "Dubbing job created successfully"
        }, status: :created
      end
      
    rescue ElevenlabsClient::AuthenticationError
      render json: { 
        error: 'Authentication failed', 
        message: 'Invalid API key or authentication failed' 
      }, status: :unauthorized
      
    rescue ElevenlabsClient::RateLimitError
      render json: { 
        error: 'Rate limit exceeded', 
        message: 'Too many requests. Please try again later.' 
      }, status: :too_many_requests
      
    rescue ElevenlabsClient::ValidationError => e
      render json: { 
        error: 'Invalid parameters', 
        message: e.message 
      }, status: :bad_request
      
    rescue ElevenlabsClient::APIError => e
      render json: { 
        error: 'API error', 
        message: e.message 
      }, status: :internal_server_error
    end
  end

  # GET /dubs/:id
  # Get dubbing job details
  def show
    client = ElevenlabsClient.new
    
    begin
      result = client.dubs.get(params[:id])
      
      render json: {
        dubbing_id: result["dubbing_id"],
        status: result["status"],
        name: result["name"],
        target_languages: result["target_languages"],
        progress: result["progress"],
        results: result["results"]
      }
      
    rescue ElevenlabsClient::ValidationError
      render json: { error: 'Dubbing job not found' }, status: :not_found
      
    rescue ElevenlabsClient::APIError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # GET /dubs
  # List dubbing jobs with optional filtering
  #
  # Parameters:
  #   - dubbing_status: String (optional) - Filter by status ("dubbing", "dubbed", "failed")
  #   - page_size: Integer (optional) - Number of results per page
  #   - page: Integer (optional) - Page number
  def index
    client = ElevenlabsClient.new
    
    begin
      params_hash = {}
      params_hash[:dubbing_status] = params[:dubbing_status] if params[:dubbing_status].present?
      params_hash[:page_size] = params[:page_size].to_i if params[:page_size].present?
      params_hash[:page] = params[:page].to_i if params[:page].present?
      
      result = client.dubs.list(params_hash)
      
      render json: {
        dubs: result["dubs"],
        pagination: result["pagination"] || {},
        total_count: result["total_count"]
      }
      
    rescue ElevenlabsClient::APIError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # GET /dubs/:id/resources
  # Get dubbing resources for editing (requires dubbing_studio: true)
  def resources
    client = ElevenlabsClient.new
    
    begin
      result = client.dubs.resources(params[:id])
      
      render json: {
        dubbing_id: result["dubbing_id"],
        resources: result["resources"]
      }
      
    rescue ElevenlabsClient::ValidationError
      render json: { error: 'Dubbing job not found or resources not available' }, status: :not_found
      
    rescue ElevenlabsClient::APIError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # DELETE /dubs/:id
  # Cancel or delete a dubbing job (if supported by API)
  def destroy
    # Note: This endpoint might not be available in the ElevenLabs API
    # This is just an example of how you might implement it
    render json: { message: 'Delete functionality not yet implemented' }, status: :not_implemented
  end

  # GET /dubs/:id/download
  # Download dubbed audio/video files
  def download
    client = ElevenlabsClient.new
    
    begin
      dub_details = client.dubs.get(params[:id])
      
      if dub_details["status"] != "dubbed"
        render json: { error: 'Dubbing job is not completed yet' }, status: :unprocessable_entity
        return
      end
      
      # Extract download URLs from results
      output_files = dub_details.dig("results", "output_files") || []
      
      if output_files.empty?
        render json: { error: 'No output files available for download' }, status: :not_found
        return
      end
      
      # For this example, we'll return the download URLs
      # In a real implementation, you might proxy the downloads or save them locally
      render json: {
        dubbing_id: params[:id],
        download_urls: output_files.map do |file|
          {
            language_code: file["language_code"],
            url: file["url"],
            file_type: file["file_type"] || "mp4"
          }
        end
      }
      
    rescue ElevenlabsClient::ValidationError
      render json: { error: 'Dubbing job not found' }, status: :not_found
      
    rescue ElevenlabsClient::APIError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /dubs/batch
  # Create multiple dubbing jobs at once
  def batch_create
    unless params[:dubs].is_a?(Array)
      render json: { error: 'dubs parameter must be an array' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    results = []
    errors = []
    
    params[:dubs].each_with_index do |dub_params, index|
      begin
        next unless dub_params[:file] && dub_params[:target_languages]
        
        File.open(dub_params[:file].tempfile, "rb") do |file|
          result = client.dubs.create(
            file_io: file,
            filename: dub_params[:file].original_filename,
            target_languages: dub_params[:target_languages],
            name: dub_params[:name]
          )
          
          results << {
            index: index,
            dubbing_id: result["dubbing_id"],
            status: result["status"],
            name: result["name"]
          }
        end
        
      rescue => e
        errors << {
          index: index,
          error: e.message
        }
      end
    end
    
    render json: {
      successful: results,
      failed: errors,
      total_processed: params[:dubs].length
    }
  end

  private

  def validate_dub_params
    unless params[:file].present?
      render json: { error: 'file is required' }, status: :bad_request
      return
    end

    unless params[:target_languages].is_a?(Array) && params[:target_languages].any?
      render json: { error: 'target_languages must be a non-empty array' }, status: :bad_request
      return
    end

    # Validate file type
    allowed_extensions = %w[.mp4 .mov .avi .mkv .mp3 .wav .flac .m4a]
    file_extension = File.extname(params[:file].original_filename).downcase
    
    unless allowed_extensions.include?(file_extension)
      render json: { 
        error: 'Invalid file type', 
        allowed_types: allowed_extensions 
      }, status: :bad_request
      return
    end

    # Validate file size (adjust limit as needed)
    max_size = 100.megabytes
    if params[:file].size > max_size
      render json: { 
        error: 'File too large', 
        max_size: "#{max_size / 1.megabyte}MB" 
      }, status: :bad_request
      return
    end
  end

  def find_dub
    unless params[:id].present?
      render json: { error: 'Dubbing ID is required' }, status: :bad_request
    end
  end

  def build_dub_options
    options = {}
    
    # Boolean options
    options[:drop_background_audio] = true if params[:drop_background_audio] == 'true'
    options[:use_profanity_filter] = params[:use_profanity_filter] == 'true' if params[:use_profanity_filter].present?
    options[:highest_resolution] = true if params[:highest_resolution] == 'true'
    options[:dubbing_studio] = true if params[:dubbing_studio] == 'true'
    
    # Other options
    options[:watermark] = params[:watermark] if params[:watermark].present?
    options[:start_time] = params[:start_time].to_i if params[:start_time].present?
    options[:end_time] = params[:end_time].to_i if params[:end_time].present?
    
    options
  end
end
