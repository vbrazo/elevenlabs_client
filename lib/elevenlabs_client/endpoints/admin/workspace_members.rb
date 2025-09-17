# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class WorkspaceMembers
      def initialize(client)
        @client = client
      end

      # POST /v1/workspace/members
      # Updates attributes of a workspace member
      # Required: email
      # Optional: is_locked, workspace_role
      def update_member(email:, is_locked: nil, workspace_role: nil)
        raise ArgumentError, "email is required" if email.nil? || email.to_s.strip.empty?
        body = { email: email }
        body[:is_locked] = is_locked unless is_locked.nil?
        body[:workspace_role] = workspace_role if workspace_role
        @client.post("/v1/workspace/members", body)
      end

      alias_method :update, :update_member

      private

      attr_reader :client
    end
  end
end


