# frozen_string_literal: true

class Admin::WorkspaceGroupsController < ApplicationController
  def index
    client = ElevenlabsClient.new
    @groups = client.workspace_groups.search(name: params[:name])
    render json: @groups
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def create_member
    client = ElevenlabsClient.new
    result = client.workspace_groups.add_member(group_id: params[:group_id], email: params[:email])
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end

  def remove_member
    client = ElevenlabsClient.new
    result = client.workspace_groups.remove_member(group_id: params[:group_id], email: params[:email])
    render json: result
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :bad_request
  end
end


