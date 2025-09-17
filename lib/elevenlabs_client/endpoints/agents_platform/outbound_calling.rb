# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class OutboundCalling
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/sip-trunk/outbound-call
        # Handle an outbound call via SIP trunk
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/sip-trunk/outbound-call
        #
        # @param agent_id [String] The agent ID to use for the call
        # @param agent_phone_number_id [String] The phone number ID to call from
        # @param to_number [String] The phone number to call
        # @param options [Hash] Optional parameters
        # @option options [Hash] :conversation_initiation_client_data Additional data for conversation initiation
        # @return [Hash] JSON response containing success status, message, conversation_id, and sip_call_id
        def sip_trunk_call(agent_id:, agent_phone_number_id:, to_number:, **options)
          endpoint = "/v1/convai/sip-trunk/outbound-call"
          request_body = {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          }.merge(options)
          
          @client.post(endpoint, request_body)
        end

        # POST /v1/convai/twilio/outbound-call
        # Handle an outbound call via Twilio
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/twilio/outbound-call
        #
        # @param agent_id [String] The agent ID to use for the call
        # @param agent_phone_number_id [String] The phone number ID to call from
        # @param to_number [String] The phone number to call
        # @param options [Hash] Optional parameters
        # @option options [Hash] :conversation_initiation_client_data Additional data for conversation initiation
        # @return [Hash] JSON response containing success status, message, conversation_id, and callSid
        def twilio_call(agent_id:, agent_phone_number_id:, to_number:, **options)
          endpoint = "/v1/convai/twilio/outbound-call"
          request_body = {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          }.merge(options)
          
          @client.post(endpoint, request_body)
        end
      end
    end
  end
end
