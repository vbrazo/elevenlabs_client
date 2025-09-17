# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class WorkspaceInvites
      def initialize(client)
        @client = client
      end

      # POST /v1/workspace/invites/add
      # Invite a single user
      # @param email [String]
      # @param group_ids [Array<String>, nil]
      # @param workspace_permission [String, nil]
      def invite(email:, group_ids: nil, workspace_permission: nil)
        validate_email!(email)
        body = { email: email }
        body[:group_ids] = group_ids if group_ids
        body[:workspace_permission] = workspace_permission if workspace_permission
        @client.post("/v1/workspace/invites/add", body)
      end

      # POST /v1/workspace/invites/add-bulk
      # Invite multiple users
      # @param emails [Array<String>]
      # @param group_ids [Array<String>, nil]
      def invite_bulk(emails:, group_ids: nil)
        raise ArgumentError, "emails must be a non-empty Array" unless emails.is_a?(Array) && !emails.empty?
        body = { emails: emails }
        body[:group_ids] = group_ids if group_ids
        @client.post("/v1/workspace/invites/add-bulk", body)
      end

      # DELETE /v1/workspace/invites (with body)
      # Delete an invitation by email
      def delete_invite(email:)
        validate_email!(email)
        @client.delete_with_body("/v1/workspace/invites", { email: email })
      end

      private

      attr_reader :client

      def validate_email!(email)
        raise ArgumentError, "email is required" if email.nil? || email.to_s.strip.empty?
      end
    end
  end
end


