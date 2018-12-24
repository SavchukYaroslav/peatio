# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Transfers

        desc 'Creates new transfer.' do
          @settings[:scope] = :write_transfers
        end
        params do
          requires :amount,
                   type: BigDecimal,
                   values: ->(v) { v.to_d.positive? },
                   desc: 'Transfer amount.'
          requires :currency,
                   type: String,
                   values: -> { ::Currency.codes(bothcase: true) },
                   desc: 'The currency code.'

          requires :from_type,
                   type: String,
                   values: Operation.TYPES,
                   desc: 'From Account type.'
          optional :from_kind,
                   type: String,
                   default: :main,
                   desc: 'From Account kind.'
          optional :from_uid,
                   type: String,
                   desc: 'Member UID for performing transfer from.'

          requires :to_type,
                   type: String,
                   values: Operation.TYPES,
                   desc: 'To Account type.'
          optional :to_kind,
                   type: String,
                   default: :main,
                   desc: 'To Account kind.'
          optional :to_uid,
                   type: String,
                   desc: 'Member UID for performing transfer to.'
        end
        post '/transfers/new' do
          currency = Currency.find(params.fetch(:currency))

          from_account_entry = Operations::Chart.entry_for(params.slice(:type, :kind).merge(currency_type: currency.type))
          to_account_entry = Operations::Chart.entry_for(params.slice(:type, :kind).merge(currency_type: currency.type))

          from_member =
            if :member.in?(from_account_entry[:scope])
              # TODO: Move this validation to params block.
              from_uid = params.fetch(:from_uid) do
                raise Grape::Exceptions::Validation, params: :from_uid, message: 'must be present.'
              end
              Member.find_by!(uid: from_uid)
            end
          to_member =
            if :member.in?(to_account_entry[:scope])
              # TODO: Move this validation to params block.
              to_uid = params.fetch(:to_uid) do
                raise Grape::Exceptions::Validation, params: :to_uid, message: 'must be present.'
              end
              Member.find_by!(uid: to_uid)
            end

          options = {
            currency_id: params[:currency],
            amount: params[:amount],
            from_code: from_account_entry[:code],
            to_code: to_account_entry[:code],
            from_member: from_member,
            to_member: to_member
          }.compact
          OpenStruct(options)
        end
      end
    end
  end
end
