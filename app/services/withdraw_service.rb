# encoding: UTF-8
# frozen_string_literal: true

class WithdrawService
  Error = Class.new(StandardError)

  attr_accessor :withdraw

  def initialize(withdraw)
    @withdraw = withdraw
  end

  def submit!
    ActiveRecord::Base.transaction do
      raise Error, 'Can\'t submit withdrawal' unless withdraw.submit
      fee_service = Peatio::FeeService.on_submit(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      Peatio::FeeService.new(withdraw.fees).submit!
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, e.message
  end

  def complete!
    ActiveRecord::Base.transaction do
      raise Error, 'Can\'t complete withdrawal' unless withdraw.success
      fee_service = Peatio::FeeService.on_complete(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, e.message
  end

  def cancel!
    ActiveRecord::Base.transaction do
      raise Error, 'Can\'t cancel withdrawal' unless withdraw.cancel
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, e.message
  end

  def reject!
    ActiveRecord::Base.transaction do
      raise Error, 'Can\'t cancel withdrawal' unless withdraw.reject
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, e.message
  end
end
