# encoding: UTF-8
# frozen_string_literal: true

class Job < ApplicationRecord
  def self.trigger_compactor
    ActiveRecord::Base.connection.execute("CALL compactor()")
  end

  STATES = %w[created succeed failed].freeze

  validates :state, inclusion: { in: STATES }

  # Allows to dynamically check value of state.
  #
  # failed? # true if code equals to "failed".
  # succeed? # true if code equals to "succeed".
  # created? # true if code equals to "created".
  STATES.each do |s|
    define_method(:"#{s}?") do
      state == s
    end
  end
end

# == Schema Information
# Schema version: 20190723202251
#
# Table name: jobs
#
#  id         :bigint           not null, primary key
#  rows       :integer          default(0), not null
#  name       :string(255)
#  state      :string(30)       default("created"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
