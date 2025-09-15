# frozen_string_literal: true

module ElevenlabsClient
  module Admin
    class Usage
      def initialize(client)
        @client = client
      end

      # GET /v1/usage/character-stats
      # Gets character usage metrics for the current user or workspace
      # Documentation: https://elevenlabs.io/docs/api-reference/usage/get-character-stats
      #
      # @param start_unix [Integer] UTC Unix timestamp for the start of the usage window (in milliseconds)
      # @param end_unix [Integer] UTC Unix timestamp for the end of the usage window (in milliseconds)
      # @param include_workspace_metrics [Boolean] Whether to include the statistics of the entire workspace (defaults to false)
      # @param breakdown_type [String] How to break down the information. Cannot be "user" if include_workspace_metrics is false
      # @param aggregation_interval [String] How to aggregate usage data over time ("hour", "day", "week", "month", or "cumulative")
      # @param aggregation_bucket_size [Integer, nil] Aggregation bucket size in seconds. Overrides the aggregation interval
      # @param metric [String] Which metric to aggregate
      # @return [Hash] The JSON response containing time axis and usage data
      def get_character_stats(start_unix:, end_unix:, include_workspace_metrics: nil, breakdown_type: nil, aggregation_interval: nil, aggregation_bucket_size: nil, metric: nil)
        endpoint = "/v1/usage/character-stats"
        
        params = {
          start_unix: start_unix,
          end_unix: end_unix
        }
        
        params[:include_workspace_metrics] = include_workspace_metrics unless include_workspace_metrics.nil?
        params[:breakdown_type] = breakdown_type if breakdown_type
        params[:aggregation_interval] = aggregation_interval if aggregation_interval
        params[:aggregation_bucket_size] = aggregation_bucket_size if aggregation_bucket_size
        params[:metric] = metric if metric
        
        @client.get(endpoint, params)
      end

      alias_method :character_stats, :get_character_stats

      private

      attr_reader :client
    end
  end
end
