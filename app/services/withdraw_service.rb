# encoding: UTF-8
# frozen_string_literal: true

class WithdrawService
  Error = Class.new(StandardError)

  attr_accessor :withdraw

  def initialize(withdraw)
    @withdraw = withdraw
  end

  def submit
    submit!
  rescue Error
    false
  end

  def submit!
    ActiveRecord::Base.transaction do
      binding.pry
      # We save withdraw and fees in single transaction.
      fee_service = Peatio::FeeService.on_submit(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      binding.pry
      withdraw.save!
      binding.pry
      fee_service.submit!
      withdraw.submit!
    end
  # TODO: Beautiful exceptions handling.
  rescue StandardError => e
    raise Error, e.message
  end

  def complete!
    ActiveRecord::Base.transaction do
      binding.pry
      # We save withdraw and fees in single transaction.
      fee_service = Peatio::FeeService.on_complete(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      binding.pry
      withdraw.save!
      binding.pry
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.success!
    end
      # TODO: Beautiful exceptions handling.
  rescue StandardError => e
    raise Error, e.message
  end

  def cancel!
    ActiveRecord::Base.transaction do
      binding.pry
      # We save withdraw and fees in single transaction.
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      binding.pry
      withdraw.save!
      binding.pry
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.cancel!
    end
      # TODO: Beautiful exceptions handling.
  rescue StandardError => e
    raise Error, e.message
  end

  def reject!
    ActiveRecord::Base.transaction do
      binding.pry
      # We save withdraw and fees in single transaction.
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      binding.pry
      withdraw.save!
      binding.pry
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.reject!
    end
      # TODO: Beautiful exceptions handling.
  rescue StandardError => e
    raise Error, e.message
  end
end
