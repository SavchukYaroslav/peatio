# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Helpers
        def create_operation!(attributes)
          if attributes.fetch(:type).in Operation::MEMBER_TYPES \
            && attributes.present?(:uid)
            create_member_operation!(attributes)
          else
            create_platform_operation!(attributes)
          end
        end

        private

        def create_platform_operation!(attributes)

        end

        def create_member_operation!(attributes)
          op =
            if params[:credit].present?
              # Update legacy account balance.
              member.ac(currency).plus_funds(params.fetch(:credit))
              klass.credit!(
                amount: params.fetch(:credit),
                currency: currency,
                member_id: member.id
              )
            else
              # Update legacy account balance.
              member.ac(currency).sub_funds(params.fetch(:debit))
              klass.debit!(
                amount: params.fetch(:debit),
                currency: currency,
                member_id: member.id
              )
            end
        end
      end
    end
  end
end
