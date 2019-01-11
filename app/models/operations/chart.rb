# encoding: UTF-8
# frozen_string_literal: true

# TODO: Move it to ActiveRecord model.
# TODO: Add validations:
#         * Code by numbers.
#         * Account type and currency type.
# TODO: Add member? platform? to Operations::Account and
# refactor #find_account_by usage.
module Operations
  class Chart
    CHART = Rails.configuration.x.chart_of_accounts

    class << self
      def code_for(options)
        find_account_by(options).fetch(:code)
      end

      def find_account_by(options)
        # We use #as_json to stringify hash values.
        # {type: 'asset'}.as_json == {type: :asset}.as_json #=> true
        CHART.find { |entry| entry.merge(options).as_json == entry.as_json }
      end

      def select_accounts_by(options)
        # We use #as_json to stringify hash values.
        # {type: 'asset'}.as_json == {type: :asset}.as_json #=> true
        CHART.select { |entry| entry.merge(options).as_json == entry.as_json }
      end

      def codes(options={})
        select_accounts_by(options)
          .map { |entry| entry.fetch(:code) }
      end
    end
  end
end
