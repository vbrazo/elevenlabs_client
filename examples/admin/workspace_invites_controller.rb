# frozen_string_literal: true

class Admin::WorkspaceInvitesController < ApplicationController
  def create
    client = ElevenlabsClient.new
    result = client.workspace_invites.invite(
      email: params[:email],
      group_ids: params[:group_ids],
      workspace_permission: params[:workspace_permission]
    )
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def create_bulk
    client = ElevenlabsClient.new
    result = client.workspace_invites.invite_bulk(
      emails: params[:emails],
      group_ids: params[:group_ids]
    )
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def destroy
    client = ElevenlabsClient.new
    result = client.workspace_invites.delete_invite(email: params[:email])
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end
end


