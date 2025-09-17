# frozen_string_literal: true

module ElevenlabsClient
  module Endpoints
    module AgentsPlatform
      class PhoneNumbers
        def initialize(client)
          @client = client
        end

        # POST /v1/convai/phone-numbers
        # Import Phone Number from provider configuration (Twilio or SIP trunk)
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/phone-numbers/import
        #
        # @param phone_number [String] The phone number to import
        # @param label [String] Label for the phone number
        # @param options [Hash] Provider-specific configuration
        # @option options [String] :sid Twilio Account SID (for Twilio provider)
        # @option options [String] :token Twilio Auth Token (for Twilio provider)
        # @option options [String] :provider_type Provider type ("twilio" or "sip_trunk")
        # @option options [Hash] :inbound_trunk_config Inbound trunk configuration (for SIP trunk)
        # @option options [Hash] :outbound_trunk_config Outbound trunk configuration (for SIP trunk)
        # @option options [String] :livekit_stack LiveKit stack configuration
        # @return [Hash] Created phone number with phone_number_id
        def import(phone_number:, label:, **options)
          endpoint = "/v1/convai/phone-numbers"
          request_body = {
            phone_number: phone_number,
            label: label
          }.merge(options)
          
          @client.post(endpoint, request_body)
        end

        # GET /v1/convai/phone-numbers
        # Retrieve all Phone Numbers
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/phone-numbers/list
        #
        # @return [Array<Hash>] List of phone numbers with their details
        def list
          endpoint = "/v1/convai/phone-numbers"
          @client.get(endpoint)
        end

        # GET /v1/convai/phone-numbers/{phone_number_id}
        # Retrieve Phone Number details by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/phone-numbers/get
        #
        # @param phone_number_id [String] The id of a phone number
        # @return [Hash] Phone number details including provider info and assigned agent
        def get(phone_number_id)
          endpoint = "/v1/convai/phone-numbers/#{phone_number_id}"
          @client.get(endpoint)
        end

        # PATCH /v1/convai/phone-numbers/{phone_number_id}
        # Update assigned agent of a phone number
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/phone-numbers/update
        #
        # @param phone_number_id [String] The id of a phone number
        # @param options [Hash] Update parameters
        # @option options [String] :agent_id Agent ID to assign to the phone number
        # @option options [Hash] :inbound_trunk_config Inbound trunk configuration
        # @option options [Hash] :outbound_trunk_config Outbound trunk configuration
        # @option options [String] :livekit_stack LiveKit stack configuration ("standard" or "static")
        # @return [Hash] Updated phone number details
        def update(phone_number_id, **options)
          endpoint = "/v1/convai/phone-numbers/#{phone_number_id}"
          request_body = options
          @client.patch(endpoint, request_body)
        end

        # DELETE /v1/convai/phone-numbers/{phone_number_id}
        # Delete Phone Number by ID
        # Documentation: https://elevenlabs.io/docs/api-reference/convai/phone-numbers/delete
        #
        # @param phone_number_id [String] The id of a phone number
        # @return [Hash] Empty response on success
        def delete(phone_number_id)
          endpoint = "/v1/convai/phone-numbers/#{phone_number_id}"
          @client.delete(endpoint)
        end
      end
    end
  end
end
