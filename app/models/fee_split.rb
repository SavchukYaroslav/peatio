# encoding: UTF-8
# frozen_string_literal: true

class FeeSplit < ApplicationRecord
  # == Constants ============================================================

  extend Enumerize

  # == Attributes ===========================================================

  # == Extensions ===========================================================

  enumerize :state, in: { active: 0, disabled: 1 }

  # == Relationships ========================================================

  belongs_to :referrer, class_name: 'Member', foreign_key: :referrer_id, required: true
  belongs_to :parent, class_name: 'Member', foreign_key: :parent_id, required: true

  # == Validations ==========================================================

  validates :percentage,
            numericality: {
              less_than_or_equal_to: ->(fs){ 100 - active.where(referrer: fs.referrer).sum(:percentage) }
            }

  # == Scopes ===============================================================

  scope :active, -> { where(state: active) }

  # == Callbacks ============================================================

  # == Class Methods ========================================================

  def apply(trades)
    # TODO
  end
  # == Instance Methods =====================================================``

  def rate
    percentage / 100
  end
end

# == Schema Information
# Schema version: 20190729134807
#
# Table name: fee_splits
#
#  id          :bigint           not null, primary key
#  referrer_id :integer          not null
#  parent_id   :integer          not null
#  percentage  :decimal(4, 2)    unsigned, not null
#  state       :integer          default("active"), unsigned, not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_fee_splits_on_parent_id    (parent_id)
#  index_fee_splits_on_referrer_id  (referrer_id)
#
