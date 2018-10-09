# encoding: UTF-8
# frozen_string_literal: true

class Fee < ActiveRecord::Base

  PLATFORM_ACCOUNT_ID = nil

  belongs_to :parent, polymorphic: true

  # source_account is nil if fees are paid from platform account.
  belongs_to :source_account, class_name: Account

  # target_account is nil if fees are paid to platform account.
  belongs_to :target_account, class_name: Account

  validates :parent, :amount, presence: true
end

# == Schema Information
# Schema version: 20180926145642
#
# Table name: fees
#
#  id                :integer          not null, primary key
#  parent_id         :integer
#  parent_type       :string(255)
#  source_account_id :integer
#  target_account_id :integer
#  amount            :decimal(32, 16)  default(0.0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_fees_on_parent_type_and_parent_id  (parent_type,parent_id)
#
