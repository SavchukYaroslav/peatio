# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Transfers < Grape::API

        desc 'Creates new transfer.' do
          @settings[:scope] = :write_transfers
        end
        params do
          requires :key,
                   type: Integer,
                   desc: 'Unique Transfer Key.'
          requires :kind,
                   type: String,
                   desc: 'Transfer Kind.'
          requires :desc,
                   type: String,
                   desc: 'Transfer Description.'

          requires(:operations, type: Array) do
            requires :currency,
                     type: String,
                     values: -> { Currency.codes(bothcase: true) },
                     desc: 'Operation currency.'
            requires :amount,
                     type: BigDecimal,
                     values: ->(v) { v.to_d.positive? },
                     desc: 'Operation amount.'

            requires :account_src, type: Hash do
              requires :code,
                       type: Integer,
                       values: -> { ::Operations::Chart.codes },
                       desc: 'Source Account code.'
              given code: ->(code) { ::Operations::Chart.find_account_by(code: code).fetch(:scope) == 'member' } do
                requires :uid,
                         type: String,
                         desc: 'Source Account User ID (for accounts with member scope).'
              end
            end

            requires :account_dst, type: Hash do
              requires :code,
                       type: Integer,
                       values: -> { ::Operations::Chart.codes },
                       desc: 'Destination Account code.'
              given code: ->(code) { ::Operations::Chart.find_account_by(code: code).fetch(:scope) == 'member' } do
                requires :uid,
                         type: String,
                         desc: 'Destination Account User ID (for accounts with member scope).'
              end
            end
          end
        end
        post '/transfers/new' do
          declared_params = declared(params)
          declared_params
          # currency = Currency.find(params.fetch(:currency))
          #
          # from_account_entry = Operations::Chart.entry_for(params.slice(:type, :kind).merge(currency_type: currency.type))
          # to_account_entry = Operations::Chart.entry_for(params.slice(:type, :kind).merge(currency_type: currency.type))
          #
          # from_member =
          #   if :member.in?(from_account_entry[:scope])
          #     # TODO: Move this validation to params block.
          #     from_uid = params.fetch(:from_uid) do
          #       raise Grape::Exceptions::Validation, params: :from_uid, message: 'must be present.'
          #     end
          #     Member.find_by!(uid: from_uid)
          #   end
          # to_member =
          #   if :member.in?(to_account_entry[:scope])
          #     # TODO: Move this validation to params block.
          #     to_uid = params.fetch(:to_uid) do
          #       raise Grape::Exceptions::Validation, params: :to_uid, message: 'must be present.'
          #     end
          #     Member.find_by!(uid: to_uid)
          #   end
          #
          # options = {
          #   currency_id: params[:currency],
          #   amount: params[:amount],
          #   from_code: from_account_entry[:code],
          #   to_code: to_account_entry[:code],
          #   from_member: from_member,
          #   to_member: to_member
          # }.compact
          # OpenStruct(options)
        end
      end
    end
  end
end
