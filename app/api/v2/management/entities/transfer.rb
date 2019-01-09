# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      module Entities
        class Transfer < Base
          expose :key,
                 documentation: {
                   type: Integer,
                   desc: 'Unique Transfer Key.'
                 }

          expose :kind,
                 documentation: {
                   type: Integer,
                   desc: 'Transfer Kind.'
                 }

          expose :desc,
                 documentation: {
                   type: String,
                   desc: 'Transfer Description'
                 }

          # Expose assets, expenses, liabilities, revenues.
          ::Operation::TYPES.map(&:pluralize).each do |op_t|
            expose op_t,
                   using: Operation,
                   if: ->(transfer) { transfer.send(op_t).present? },
                   documentation: {
                     desc: "Transfer #{op_t}"
                   }
          end
        end
      end
    end
  end
end


# == Schema Information
# Schema version: 20181226170925
#
# Table name: transfers
#
#  id         :integer          not null, primary key
#  key        :integer          not null
#  kind       :string(30)       not null
#  desc       :string(255)      default("")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_transfers_on_key   (key) UNIQUE
#  index_transfers_on_kind  (kind)
#
#
