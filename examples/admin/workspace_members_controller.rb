# frozen_string_literal: true

class Admin::WorkspaceMembersController < ApplicationController
  # POST /admin/workspace_members/update
  # Updates attributes of a workspace member
  def update
    client = ElevenlabsClient.new
    
    result = client.workspace_members.update_member(
      email: params[:email],
      is_locked: params[:is_locked],
      workspace_role: params[:workspace_role]
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

  # POST /admin/workspace_members/lock
  # Lock a workspace member account
  def lock
    client = ElevenlabsClient.new
    
    result = client.workspace_members.update_member(
      email: params[:email],
      is_locked: true
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

  # POST /admin/workspace_members/unlock
  # Unlock a workspace member account
  def unlock
    client = ElevenlabsClient.new
    
    result = client.workspace_members.update_member(
      email: params[:email],
      is_locked: false
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

  # POST /admin/workspace_members/promote
  # Promote a member to workspace admin
  def promote_to_admin
    client = ElevenlabsClient.new
    
    result = client.workspace_members.update_member(
      email: params[:email],
      workspace_role: "workspace_admin"
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

  # POST /admin/workspace_members/demote
  # Demote an admin to regular member
  def demote_to_member
    client = ElevenlabsClient.new
    
    result = client.workspace_members.update_member(
      email: params[:email],
      workspace_role: "workspace_member"
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

  def workspace_member_params
    params.permit(:email, :is_locked, :workspace_role)
  end
end

# Usage Examples:
#
# 1. Update member attributes:
# POST /admin/workspace_members/update
# {
#   "email": "user@example.com",
#   "is_locked": true,
#   "workspace_role": "workspace_admin"
# }
#
# 2. Lock a member account:
# POST /admin/workspace_members/lock
# {
#   "email": "user@example.com"
# }
#
# 3. Unlock a member account:
# POST /admin/workspace_members/unlock
# {
#   "email": "user@example.com"
# }
#
# 4. Promote member to admin:
# POST /admin/workspace_members/promote
# {
#   "email": "user@example.com"
# }
#
# 5. Demote admin to member:
# POST /admin/workspace_members/demote
# {
#   "email": "user@example.com"
# }
#
# Error Responses:
# - 422 Unprocessable Entity: Invalid parameters
# - 404 Not Found: User not found in workspace
# - 403 Forbidden: Insufficient permissions
# - 400 Bad Request: Other API errors
#
# Note: This endpoint requires workspace administrator permissions.
# Only the specified attributes will be updated; others remain unchanged.
