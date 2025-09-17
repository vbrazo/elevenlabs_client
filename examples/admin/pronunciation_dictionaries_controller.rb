# frozen_string_literal: true

class Admin::PronunciationDictionariesController < ApplicationController
  def create_from_file
    client = ElevenlabsClient.new

    io = params[:file]&.tempfile
    filename = params[:file]&.original_filename

    result = client.pronunciation_dictionaries.add_from_file(
      name: params[:name],
      file_io: io,
      filename: filename,
      description: params[:description],
      workspace_access: params[:workspace_access]
    )

    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def create_from_rules
    client = ElevenlabsClient.new

    result = client.pronunciation_dictionaries.add_from_rules(
      name: params[:name],
      rules: params[:rules],
      description: params[:description],
      workspace_access: params[:workspace_access]
    )

    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def show
    client = ElevenlabsClient.new
    result = client.pronunciation_dictionaries.get(params[:id])
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def update
    client = ElevenlabsClient.new
    result = client.pronunciation_dictionaries.update(params[:id], **update_params)
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def download_version
    client = ElevenlabsClient.new
    body = client.pronunciation_dictionaries.download_pronunciation_dictionary_version(
      dictionary_id: params[:dictionary_id],
      version_id: params[:version_id]
    )
    send_data body, filename: "dictionary_#{params[:dictionary_id]}_#{params[:version_id]}.pls", type: "application/pls+xml"
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def index
    client = ElevenlabsClient.new
    result = client.pronunciation_dictionaries.list_pronunciation_dictionaries(
      cursor: params[:cursor],
      page_size: params[:page_size],
      sort: params[:sort],
      sort_direction: params[:sort_direction]
    )
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def update_params
    params.permit(:archived, :name, :description, :workspace_access).to_h.symbolize_keys
  end
end
