# frozen_string_literal: true


module Operations
  class Account < ActiveRecord::Base
    def self.table_name_prefix
      'operations_'
    end

    # Type column reserved for STI.
    self.inheritance_column = nil
  end
end

# == Schema Information
# Schema version: 20190115165813
#
# Table name: operations_accounts
#
#  id            :integer          not null, primary key
#  code          :integer          not null
#  type          :string(10)       not null
#  kind          :string(30)       not null
#  currency_type :string(10)       not null
#  description   :string(100)
#  scope         :string(10)       not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_operations_accounts_on_code                             (code) UNIQUE
#  index_operations_accounts_on_currency_type                    (currency_type)
#  index_operations_accounts_on_scope                            (scope)
#  index_operations_accounts_on_type                             (type)
#  index_operations_accounts_on_type_and_kind_and_currency_type  (type,kind,currency_type)
#
