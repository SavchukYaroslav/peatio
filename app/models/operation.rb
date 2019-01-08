# frozen_string_literal: true

# {Operation} provides generic methods for the accounting operations
# models.
# @abstract
class Operation < ActiveRecord::Base
  belongs_to :reference, polymorphic: true
  belongs_to :currency, foreign_key: :currency_id

  validates :credit, :debit, numericality: { greater_than_or_equal_to: 0 }
  validate do
    unless account.currency_type == currency.type
      errors.add(:currency, 'type and account currency type don\'t match')
    end
  end

  self.abstract_class = true

  MEMBER_TYPES = %i[liability].freeze
  PLATFORM_TYPES = %i[asset expense revenue].freeze
  TYPES = (MEMBER_TYPES + PLATFORM_TYPES).freeze

  class << self
    def operation_type
      name.demodulize.downcase.to_sym
    end

    def credit!(amount:, currency:, kind: :main, **opt)
      return if amount.zero?

      opt[:code] ||= Operations::Chart.code_for(
        type:          operation_type,
        kind:          kind,
        currency_type: currency.type
      )

      opt.merge(credit: amount, currency_id: currency.id)
         .yield_self { |attr| new(attr) }
         .tap(&:save!)
    end

    def debit!(amount:, currency:, kind: :main, **opt)
      return if amount.zero?

      opt[:code] ||= Operations::Chart.code_for(
        type:          operation_type,
        kind:          kind,
        currency_type: currency.type
      )

      opt.merge(debit: amount, currency_id: currency.id)
         .yield_self { |attr| new(attr) }
         .tap(&:save!)
    end

    def transfer!(amount:, currency:, from_kind:, to_kind:, **opt)
      params = opt.merge(amount: amount, currency: currency)

      [
        debit!(params.merge(kind: from_kind)),
        credit!(params.merge(kind: to_kind))
      ]
    end

    def balance(currency: nil, created_at_from: nil, created_at_to: nil)
      if currency.blank?
        db_balances = all
        db_balances = db_balances.where('created_at > ?', created_at_from) if created_at_from.present?
        db_balances = db_balances.where('created_at < ?', created_at_to) if created_at_to.present?
        db_balances = db_balances.group(:currency_id)
                                 .sum('credit - debit')

        Currency.ids.map(&:to_sym).each_with_object({}) do |id, memo|
          memo[id] = db_balances[id.to_s] || 0
        end
      else
        where(currency: currency).sum('credit - debit')
      end
    end
  end

  def account
    Operations::Chart.find_account_by(code: code)
                     .yield_self { |ch| OpenStruct.new(ch) }
  end
end
