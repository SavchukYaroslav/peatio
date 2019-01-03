# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Helpers
        def create_operation!(attributes)
          if attributes.fetch(:type).in Operation::MEMBER_TYPES \
            && attributes[:uid].present?
            create_member_operation!(attributes)
          else
            create_platform_operation!(attributes)
          end
        end

        private

        def create_platform_operation!(attributes)

        end

        def create_member_operation!(attributes)
          member = Member.find_by!(uid: attributes.fetch(:uid))

          op =
            if params[:credit].present?
              amount = params.fetch(:credit)
              # Update legacy account balance.
              member.ac(currency).plus_funds(amount)
              attributes.slice(:currency, :code, :kind)
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
