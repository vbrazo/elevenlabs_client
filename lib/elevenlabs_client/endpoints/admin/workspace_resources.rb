# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class WorkspaceResources
      def initialize(client)
        @client = client
      end

      # GET /v1/workspace/resources/:resource_id
      # params: resource_type (required)
      def get_resource(resource_id:, resource_type:)
        raise ArgumentError, "resource_id is required" if resource_id.nil? || resource_id.to_s.strip.empty?
        raise ArgumentError, "resource_type is required" if resource_type.nil? || resource_type.to_s.strip.empty?
        @client.get("/v1/workspace/resources/#{resource_id}", { resource_type: resource_type })
      end

      # POST /v1/workspace/resources/:resource_id/share
      # body: role (required), resource_type (required), optional: user_email, group_id, workspace_api_key_id
      def share(resource_id:, role:, resource_type:, user_email: nil, group_id: nil, workspace_api_key_id: nil)
        validate_resource!(resource_id, resource_type)
        raise ArgumentError, "role is required" if role.nil? || role.to_s.strip.empty?
        body = { role: role, resource_type: resource_type }
        body[:user_email] = user_email if user_email
        body[:group_id] = group_id if group_id
        body[:workspace_api_key_id] = workspace_api_key_id if workspace_api_key_id
        @client.post("/v1/workspace/resources/#{resource_id}/share", body)
      end

      # POST /v1/workspace/resources/:resource_id/unshare
      # body: resource_type (required), optional: user_email, group_id, workspace_api_key_id
      def unshare(resource_id:, resource_type:, user_email: nil, group_id: nil, workspace_api_key_id: nil)
        validate_resource!(resource_id, resource_type)
        body = { resource_type: resource_type }
        body[:user_email] = user_email if user_email
        body[:group_id] = group_id if group_id
        body[:workspace_api_key_id] = workspace_api_key_id if workspace_api_key_id
        @client.post("/v1/workspace/resources/#{resource_id}/unshare", body)
      end

      private

      attr_reader :client

      def validate_resource!(resource_id, resource_type)
        raise ArgumentError, "resource_id is required" if resource_id.nil? || resource_id.to_s.strip.empty?
        raise ArgumentError, "resource_type is required" if resource_type.nil? || resource_type.to_s.strip.empty?
      end
    end
  end
end


