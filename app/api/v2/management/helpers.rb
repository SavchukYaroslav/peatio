# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Helpers
        def create_operation!(attr)
          if attr.fetch(:type).in?(Operation::MEMBER_TYPES) \
            && attr[:uid].present?
            create_member_operation!(attr)
          else
            create_platform_operation!(attr)
          end
        end

        private

        def create_platform_operation!(attr)
          currency = Currency.find(attr.fetch(:currency))
          klass = attr.delete(:type)
                      .yield_self { |type| "operations/#{type}" }
                      .camelize
                      .constantize

          if attr[:credit].present?
            klass.credit!(amount: attr.fetch(:credit),
                          currency: currency,
                          **attr.slice(:kind, :code))
          elsif attr[:debit].present?
            klass.debit!(amount: attr.fetch(:debit),
                         currency: currency,
                         **attr.slice(:kind, :code))
          end
        end

        def create_member_operation!(attr)
          member = Member.find_by!(uid: attr.fetch(:uid))
          currency = Currency.find(attr.fetch(:currency))
          klass = attr.delete(:type)
                      .yield_self { |type| "operations/#{type}" }
                      .camelize
                      .constantize

          if attr[:credit].present?
            amount = attr.fetch(:credit)

            op = klass.credit!(amount: amount,
                               member_id: member.id,
                               currency: currency,
                               **attr.slice(:kind, :code))

            credit_legacy_balance!(amount: amount,
                                   member: member,
                                   currency: currency,
                                   kind: op.chart.kind)
            op
          elsif attr[:debit].present?
            amount = attr.fetch(:debit)

            op = klass.debit!(amount: amount,
                              member_id: member.id,
                              currency: currency,
                              **attr.slice(:kind, :code))

            debit_legacy_balance!(amount: amount,
                                  member: member,
                                  currency: currency,
                                  kind: op.chart.kind)
            op
          end
        end

        # @deprecated
        def credit_legacy_balance!(amount:, member:, currency:, kind:)
          kind ||= ::Operations::Chart.find_chart(code)[:kind]

          if kind.to_s == 'main'
            member.ac(currency).plus_funds(amount)
          elsif kind.to_s == 'locked'
            member.ac(currency).plus_funds(amount)
            member.ac(currency).lock_funds(amount)
          end
        end

        # @deprecated
        def debit_legacy_balance!(amount:, member:, currency:, kind:)

          if kind.to_s == 'main'
            member.ac(currency).sub_funds(amount)
          elsif kind.to_s == 'locked'
            member.ac(currency).unlock_and_sub_funds(amount)
          end
        end
      end
    end
  end
end
