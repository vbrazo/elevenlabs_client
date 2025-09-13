# Example Rails controller demonstrating Voice management functionality
# This controller provides endpoints for managing voices - create, read, update, delete

class VoicesController < ApplicationController
  before_action :initialize_client
  before_action :set_voice_id, only: [:show, :update, :destroy, :status]
  
  # GET /voices
  # List all voices in the account
  def index
    voices = @client.voices.list
    
    render json: {
      success: true,
      voices: format_voices_list(voices["voices"]),
      total_count: voices["voices"].length,
      categories: categorize_voices(voices["voices"])
    }
    
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Failed to retrieve voices", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # GET /voices/:id
  # Get detailed information about a specific voice
  def show
    voice = @client.voices.get(@voice_id)
    
    render json: {
      success: true,
      voice: format_voice_details(voice)
    }
    
  rescue ElevenlabsClient::ValidationError
    render json: { 
      success: false, 
      error: "Voice not found" 
    }, status: :not_found
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Failed to retrieve voice", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # POST /voices
  # Create a new voice from audio samples
  def create
    unless params[:samples].present?
      return render json: { 
        success: false, 
        error: "Audio samples are required" 
      }, status: :bad_request
    end
    
    # Process uploaded files
    sample_files = process_uploaded_samples(params[:samples])
    
    result = @client.voices.create(
      params[:name],
      sample_files,
      description: params[:description] || "",
      labels: parse_labels(params[:labels])
    )
    
    render json: {
      success: true,
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice created successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Voice creation failed", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Voice creation failed", 
      details: e.message 
    }, status: :unprocessable_entity
  ensure
    # Clean up temporary files
    sample_files&.each do |file|
      file.close if file.respond_to?(:close)
    end
  end
  
  # PATCH/PUT /voices/:id
  # Update an existing voice
  def update
    # Process uploaded files if provided
    sample_files = params[:samples].present? ? process_uploaded_samples(params[:samples]) : []
    
    result = @client.voices.edit(
      @voice_id,
      sample_files,
      name: params[:name],
      description: params[:description],
      labels: parse_labels(params[:labels])
    )
    
    render json: {
      success: true,
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice updated successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Voice update failed", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Voice update failed", 
      details: e.message 
    }, status: :unprocessable_entity
  ensure
    # Clean up temporary files
    sample_files&.each do |file|
      file.close if file.respond_to?(:close)
    end
  end
  
  # DELETE /voices/:id
  # Delete a voice from the account
  def destroy
    result = @client.voices.delete(@voice_id)
    
    render json: {
      success: true,
      message: result["message"] || "Voice deleted successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Voice deletion failed", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Voice deletion failed", 
      details: e.message 
    }, status: :unprocessable_entity
  end
  
  # GET /voices/:id/status
  # Check voice status (active, banned)
  def status
    render json: {
      success: true,
      voice_id: @voice_id,
      status: {
        is_active: @client.voices.active?(@voice_id),
        is_banned: @client.voices.banned?(@voice_id)
      }
    }
  end
  
  # POST /voices/clone_from_url
  # Create a voice by downloading audio from URLs
  def clone_from_url
    unless params[:audio_urls].present?
      return render json: { 
        success: false, 
        error: "Audio URLs are required" 
      }, status: :bad_request
    end
    
    # Download audio files from URLs
    sample_files = download_audio_samples(params[:audio_urls])
    
    result = @client.voices.create(
      params[:name],
      sample_files,
      description: params[:description] || "Voice cloned from audio URLs",
      labels: parse_labels(params[:labels])
    )
    
    render json: {
      success: true,
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice cloned successfully from URLs"
    }
    
  rescue => e
    render json: { 
      success: false, 
      error: "Voice cloning failed", 
      details: e.message 
    }, status: :unprocessable_entity
  ensure
    # Clean up downloaded files
    sample_files&.each do |file|
      file.close if file.respond_to?(:close)
      File.unlink(file.path) if File.exist?(file.path)
    end
  end
  
  # GET /voices/by_category/:category
  # Get voices filtered by category
  def by_category
    category = params[:category]
    voices = @client.voices.list
    
    filtered_voices = voices["voices"].select { |voice| voice["category"] == category }
    
    render json: {
      success: true,
      category: category,
      voices: format_voices_list(filtered_voices),
      count: filtered_voices.length
    }
  end
  
  # GET /voices/search
  # Search voices by name, labels, or description
  def search
    query = params[:q]&.downcase
    
    unless query.present?
      return render json: { 
        success: false, 
        error: "Search query is required" 
      }, status: :bad_request
    end
    
    voices = @client.voices.list
    
    matching_voices = voices["voices"].select do |voice|
      voice_text = [
        voice["name"],
        voice["description"],
        voice["labels"]&.values&.join(" ")
      ].compact.join(" ").downcase
      
      voice_text.include?(query)
    end
    
    render json: {
      success: true,
      query: params[:q],
      voices: format_voices_list(matching_voices),
      count: matching_voices.length
    }
  end
  
  # POST /voices/:id/enhance
  # Enhance a voice with additional samples
  def enhance
    unless params[:additional_samples].present?
      return render json: { 
        success: false, 
        error: "Additional audio samples are required" 
      }, status: :bad_request
    end
    
    # Get current voice details
    current_voice = @client.voices.get(@voice_id)
    
    # Process new samples
    sample_files = process_uploaded_samples(params[:additional_samples])
    
    # Update voice with new samples
    result = @client.voices.edit(
      @voice_id,
      sample_files,
      description: "#{current_voice['description']} (Enhanced with additional samples)"
    )
    
    render json: {
      success: true,
      voice: {
        id: result["voice_id"],
        name: result["name"],
        category: result["category"]
      },
      message: "Voice enhanced with #{sample_files.length} additional samples"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Voice enhancement failed", 
      details: e.message 
    }, status: :bad_request
  ensure
    sample_files&.each do |file|
      file.close if file.respond_to?(:close)
    end
  end
  
  # POST /voices/batch_create
  # Create multiple voices from a batch of sample sets
  def batch_create
    voice_data = params[:voices] || []
    results = []
    errors = []
    
    voice_data.each_with_index do |voice_params, index|
      begin
        sample_files = process_uploaded_samples(voice_params[:samples])
        
        result = @client.voices.create(
          voice_params[:name],
          sample_files,
          description: voice_params[:description] || "",
          labels: parse_labels(voice_params[:labels])
        )
        
        results << {
          index: index,
          success: true,
          voice_id: result["voice_id"],
          name: result["name"]
        }
        
      rescue ElevenlabsClient::APIError => e
        errors << {
          index: index,
          voice_name: voice_params[:name],
          error: e.message
        }
      ensure
        sample_files&.each { |file| file.close if file.respond_to?(:close) }
      end
    end
    
    render json: {
      success: errors.empty?,
      created_voices: results,
      errors: errors,
      summary: {
        total: voice_data.length,
        successful: results.length,
        failed: errors.length
      }
    }
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def set_voice_id
    @voice_id = params[:id]
  end
  
  def process_uploaded_samples(samples)
    return [] unless samples.present?
    
    Array(samples).map do |upload|
      # Validate file type
      unless audio_file?(upload)
        raise ArgumentError, "Invalid audio file: #{upload.original_filename}"
      end
      
      # Validate file size (25MB limit)
      if upload.size > 25.megabytes
        raise ArgumentError, "File too large: #{upload.original_filename} (#{upload.size} bytes)"
      end
      
      upload.tempfile
    end
  end
  
  def download_audio_samples(urls)
    require 'open-uri'
    
    Array(urls).map.with_index do |url, index|
      temp_file = Tempfile.new(["sample_#{index}", ".mp3"])
      
      URI.open(url) do |remote_file|
        temp_file.write(remote_file.read)
      end
      
      temp_file.rewind
      temp_file
    end
  end
  
  def audio_file?(upload)
    return false unless upload.respond_to?(:content_type)
    
    audio_types = [
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/wave',
      'audio/x-wav',
      'audio/flac',
      'audio/x-flac',
      'audio/mp4',
      'audio/m4a'
    ]
    
    audio_types.include?(upload.content_type&.downcase)
  end
  
  def parse_labels(labels_param)
    return {} unless labels_param.present?
    
    case labels_param
    when String
      JSON.parse(labels_param)
    when Hash
      labels_param.transform_keys(&:to_s)
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end
  
  def format_voices_list(voices)
    voices.map do |voice|
      {
        id: voice["voice_id"],
        name: voice["name"],
        category: voice["category"],
        description: voice["description"],
        labels: voice["labels"] || {},
        sample_count: voice["samples"]&.length || 0,
        preview_url: voice["preview_url"],
        is_banned: voice["safety_control"] == "BAN"
      }
    end
  end
  
  def format_voice_details(voice)
    {
      id: voice["voice_id"],
      name: voice["name"],
      category: voice["category"],
      description: voice["description"],
      labels: voice["labels"] || {},
      settings: voice["settings"],
      samples: voice["samples"]&.map do |sample|
        {
          id: sample["sample_id"],
          filename: sample["file_name"],
          size_bytes: sample["size_bytes"],
          mime_type: sample["mime_type"]
        }
      end || [],
      safety_control: voice["safety_control"],
      is_banned: voice["safety_control"] == "BAN",
      preview_url: voice["preview_url"],
      available_for_tiers: voice["available_for_tiers"],
      permission: voice["permission_on_resource"]
    }
  end
  
  def categorize_voices(voices)
    categories = voices.group_by { |voice| voice["category"] }
    categories.transform_values(&:length)
  end
end

# Example routes for config/routes.rb:
#
# Rails.application.routes.draw do
#   resources :voices do
#     member do
#       get :status
#       post :enhance
#     end
#     
#     collection do
#       post :clone_from_url
#       post :batch_create
#       get :search
#       get 'by_category/:category', to: :by_category
#     end
#   end
# end

# Example usage in JavaScript:
#
# // List all voices
# fetch('/voices')
#   .then(response => response.json())
#   .then(data => {
#     console.log('Voices:', data.voices);
#     console.log('Categories:', data.categories);
#   });
#
# // Create a voice
# const formData = new FormData();
# formData.append('name', 'My Custom Voice');
# formData.append('description', 'A professional narrator voice');
# formData.append('samples[]', audioFile1);
# formData.append('samples[]', audioFile2);
# formData.append('labels', JSON.stringify({
#   accent: 'american',
#   gender: 'female',
#   use_case: 'narration'
# }));
#
# fetch('/voices', {
#   method: 'POST',
#   body: formData
# })
# .then(response => response.json())
# .then(data => {
#   if (data.success) {
#     console.log('Voice created:', data.voice);
#   } else {
#     console.error('Error:', data.error);
#   }
# });
#
# // Search voices
# fetch('/voices/search?q=narrator')
#   .then(response => response.json())
#   .then(data => {
#     console.log('Search results:', data.voices);
#   });
#
# // Check voice status
# fetch('/voices/voice_id_here/status')
#   .then(response => response.json())
#   .then(data => {
#     console.log('Voice active:', data.status.is_active);
#     console.log('Voice banned:', data.status.is_banned);
#   });
