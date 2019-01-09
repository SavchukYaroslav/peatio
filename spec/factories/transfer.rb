# encoding: UTF-8
# frozen_string_literal: true

FactoryBot.define do
  sequence :transfer_key do
    Faker::Number.number(5)
  end
  sequence :transfer_kind do |n|
    %w[referral-payoff token-distribution member-transfer].sample + "-#{n}"
  end

  factory :transfer do
    key  { generate(:transfer_key) }
    kind { generate(:transfer_kind) }
    desc { "#{kind} for #{Time.now.to_date}" }

    trait :with_operations do
      # TODO: Add Transfer with operations.
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
