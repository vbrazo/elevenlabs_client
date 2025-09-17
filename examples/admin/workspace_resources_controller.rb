# frozen_string_literal: true

class Admin::WorkspaceResourcesController < ApplicationController
  # GET /admin/workspace_resources/:resource_id
  # Gets the metadata of a resource by ID
  def show
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.get_resource(
      resource_id: params[:resource_id],
      resource_type: params[:resource_type]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/share
  # Grants a role on a workspace resource to a user or group
  def share
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.share(
      resource_id: params[:resource_id],
      role: params[:role],
      resource_type: params[:resource_type],
      user_email: params[:user_email],
      group_id: params[:group_id],
      workspace_api_key_id: params[:workspace_api_key_id]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/unshare
  # Removes any existing role on a workspace resource from a user, group, or API key
  def unshare
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.unshare(
      resource_id: params[:resource_id],
      resource_type: params[:resource_type],
      user_email: params[:user_email],
      group_id: params[:group_id],
      workspace_api_key_id: params[:workspace_api_key_id]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/share_with_user
  # Convenience method to share resource with a specific user
  def share_with_user
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.share(
      resource_id: params[:resource_id],
      role: params[:role],
      resource_type: params[:resource_type],
      user_email: params[:user_email]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/share_with_group
  # Convenience method to share resource with a specific group
  def share_with_group
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.share(
      resource_id: params[:resource_id],
      role: params[:role],
      resource_type: params[:resource_type],
      group_id: params[:group_id]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/share_with_api_key
  # Convenience method to share resource with a workspace API key
  def share_with_api_key
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.share(
      resource_id: params[:resource_id],
      role: params[:role],
      resource_type: params[:resource_type],
      workspace_api_key_id: params[:workspace_api_key_id]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/unshare_from_user
  # Convenience method to unshare resource from a specific user
  def unshare_from_user
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.unshare(
      resource_id: params[:resource_id],
      resource_type: params[:resource_type],
      user_email: params[:user_email]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /admin/workspace_resources/:resource_id/unshare_from_group
  # Convenience method to unshare resource from a specific group
  def unshare_from_group
    client = ElevenlabsClient.new
    
    result = client.workspace_resources.unshare(
      resource_id: params[:resource_id],
      resource_type: params[:resource_type],
      group_id: params[:group_id]
    )
    
    render json: result
  rescue ElevenlabsClient::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ElevenlabsClient::NotFoundError => e
    render json: { error: e.message }, status: :not_found
  rescue ElevenlabsClient::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def resource_params
    params.permit(:resource_id, :resource_type, :role, :user_email, :group_id, :workspace_api_key_id)
  end
end

# Usage Examples:
#
# 1. Get resource metadata:
# GET /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc?resource_type=voice
#
# 2. Share resource with user:
# POST /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc/share
# {
#   "role": "editor",
#   "resource_type": "voice",
#   "user_email": "user@example.com"
# }
#
# 3. Share resource with group:
# POST /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc/share
# {
#   "role": "viewer",
#   "resource_type": "voice",
#   "group_id": "group_123"
# }
#
# 4. Share resource with API key:
# POST /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc/share
# {
#   "role": "admin",
#   "resource_type": "voice",
#   "workspace_api_key_id": "api_key_123"
# }
#
# 5. Unshare resource from user:
# POST /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc/unshare
# {
#   "resource_type": "voice",
#   "user_email": "user@example.com"
# }
#
# 6. Unshare resource from group:
# POST /admin/workspace_resources/4ZUqyldxf71HqUbcP2Lc/unshare
# {
#   "resource_type": "voice",
#   "group_id": "group_123"
# }
#
# Supported Resource Types:
# - voice
# - model
# - project
# - pronunciation_dictionary
# - sound_effect
# - music
# - dataset
# - and more...
#
# Supported Roles:
# - admin: Full access to the resource
# - editor: Can modify the resource
# - viewer: Read-only access to the resource
#
# Error Responses:
# - 422 Unprocessable Entity: Invalid parameters or resource type
# - 404 Not Found: Resource not found
# - 403 Forbidden: Insufficient permissions to share/unshare
# - 400 Bad Request: Other API errors
#
# Notes:
# - You must have admin access to the resource to share or unshare it
# - You cannot remove permissions from the user who created the resource
# - To target default permissions, use group_id: "default"
