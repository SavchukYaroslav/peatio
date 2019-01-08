# encoding: UTF-8
# frozen_string_literal: true

# TODO: Move it to ActiveRecord model.
module Operations
  class Chart
    CHART = Rails.configuration.x.chart_of_accounts

    class << self
      def code_for(options)
        entry_for(options).fetch(:code)
      end

      def entry_for(options)
        # We use #as_json to stringify hash values.
        # {type: 'asset'}.as_json == {type: :asset}.as_json #=> true
        CHART
          .find { |entry| entry.merge(options).as_json == entry.as_json }
          .tap do |entry|
            if entry.blank?
              raise StandardError, "Account for #{options} doesn't exists."\
            end
          end
      end

      def find_chart(code)
        CHART.find { |entry| entry.fetch(:code) == code }
      end

      def codes
        CHART.map { |entry| entry.fetch(:code) }
      end
    end
  end
end
