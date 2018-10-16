# encoding: UTF-8
# frozen_string_literal: true

class WithdrawService
  class Error < StandardError
    attr_reader :action, :wrapped_exception

    def initialize(action:, ex:)
      @action = action
      @wrapped_exception = ex
      super "Can't #{action} withdrawal. Reason: #{wrapped_exception.message}"
    end
  end

  class ChangeStateError < StandardError
    def initialize(state)
      super "Update withdraw state to #{state}ed failed."
    end
  end

  attr_accessor :withdraw

  def initialize(withdraw)
    @withdraw = withdraw
  end

  def submit!
    action = :submit
    validate_action!(action)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_submit(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      Peatio::FeeService.new(withdraw.fees).submit!
      withdraw.public_send(action)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, action: action, ex: e
  end

  def complete!
    action = :success
    validate_action!(action)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_complete(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(action)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, action: :complete, ex: e
  end

  def cancel!
    action = :cancel
    validate_action!(action)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(action)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, action: action, ex: e
  end

  def reject!
    action = :reject
    validate_action!(action)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(action)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, action: action, ex: e
  end

  private
  def validate_action!(action)
    raise ChangeStateError, action unless withdraw.public_send("may_#{action}?")
  end
end
