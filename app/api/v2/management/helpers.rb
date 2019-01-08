# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Helpers
        def create_operation!(attrs)
          account = ::Operations::Chart.find_account_by(code: attrs.fetch(:code))
          if 'member' == account.fetch(:scope)
            create_member_operation!(attrs)
          else
            create_platform_operation!(attrs)
          end
        end

        private

        def create_platform_operation!(attrs)
          currency = Currency.find(attrs.fetch(:currency))
          klass = attrs.delete(:type)
                       .yield_self { |type| "operations/#{type}" }
                       .camelize
                       .constantize

          if attrs[:credit].present?
            klass.credit!(amount: attrs.fetch(:credit),
                          code: attrs.fetch(:code),
                          currency: currency)
          elsif attrs[:debit].present?
            klass.debit!(amount: attrs.fetch(:debit),
                         code: attrs.fetch(:code),
                         currency: currency)
          end
        end

        def create_member_operation!(attrs)
          member = Member.find_by!(uid: attrs.fetch(:uid))
          currency = Currency.find(attrs.fetch(:currency))
          klass = attrs.delete(:type)
                       .yield_self { |type| "operations/#{type}" }
                       .camelize
                       .constantize

          if attrs[:credit].present?
            amount = attrs.fetch(:credit)
            op = klass.credit!(amount: amount,
                               member_id: member.id,
                               code: attrs.fetch(:code),
                               currency: currency)

            credit_legacy_balance!(amount: amount,
                                   member: member,
                                   currency: currency,
                                   kind: op.account.kind)
            op
          elsif attrs[:debit].present?
            amount = attrs.fetch(:debit)

            op = klass.debit!(amount: amount,
                              member_id: member.id,
                              code: attrs.fetch(:code),
                              currency: currency)

            debit_legacy_balance!(amount: amount,
                                  member: member,
                                  currency: currency,
                                  kind: op.account.kind)
            op
          end
        end

        # @deprecated
        def credit_legacy_balance!(amount:, member:, currency:, kind:)
          kind ||= ::Operations::Chart.find_account_by(code: code).fetch(:kind)

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
