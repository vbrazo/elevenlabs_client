# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class WorkspaceGroups
      def initialize(client)
        @client = client
      end

      # GET /v1/workspace/groups/search
      # Searches for user groups in the workspace by name
      # @param name [String] Group name to search
      # @return [Array<Hash>] List of matching groups
      def search(name:)
        raise ArgumentError, "name is required" if name.nil? || name.to_s.strip.empty?

        @client.get("/v1/workspace/groups/search", { name: name })
      end

      # POST /v1/workspace/groups/:group_id/members
      # Adds a member to the specified group
      # @param group_id [String] The group ID
      # @param email [String] The member email to add
      # @return [Hash] { "status" => "ok" }
      def add_member(group_id:, email:)
        validate_group_and_email!(group_id, email)

        endpoint = "/v1/workspace/groups/#{group_id}/members"
        @client.post(endpoint, { email: email })
      end

      # POST /v1/workspace/groups/:group_id/members/remove
      # Removes a member from the specified group
      # @param group_id [String] The group ID
      # @param email [String] The member email to remove
      # @return [Hash] { "status" => "ok" }
      def remove_member(group_id:, email:)
        validate_group_and_email!(group_id, email)

        endpoint = "/v1/workspace/groups/#{group_id}/members/remove"
        @client.post(endpoint, { email: email })
      end

      private

      attr_reader :client

      def validate_group_and_email!(group_id, email)
        raise ArgumentError, "group_id is required" if group_id.nil? || group_id.to_s.strip.empty?
        raise ArgumentError, "email is required" if email.nil? || email.to_s.strip.empty?
      end
    end
  end
end


