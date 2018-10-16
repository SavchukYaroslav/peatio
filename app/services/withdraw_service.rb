# encoding: UTF-8
# frozen_string_literal: true

class WithdrawService
  class Error < StandardError
    attr_reader :action, :wrapped_exception

    def initialize(event:, ex:)
      @action = event
      @wrapped_exception = ex
      super "Can't #{event} withdrawal. Reason: #{wrapped_exception.message}"
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
    event = :submit
    validate_event!(event)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_submit(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      Peatio::FeeService.new(withdraw.fees).submit!
      withdraw.public_send(event)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, event: event, ex: e
  end

  def complete!
    event = :success
    validate_event!(event)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_complete(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(event)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, event: :complete, ex: e
  end

  def cancel!
    event = :cancel
    validate_event!(event)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(event)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, event: event, ex: e
  end

  def reject!
    event = :reject
    validate_event!(event)
    ActiveRecord::Base.transaction do
      fee_service = Peatio::FeeService.on_cancel(:withdraw, withdraw)
      withdraw.fees << fee_service.fees
      fee_service.submit!
      Peatio::FeeService.new(withdraw.fees).complete!
      withdraw.public_send(event)
      withdraw.save!
    end
  rescue StandardError => e
    raise Error, event: event, ex: e
  end

  private
  def validate_event!(event)
    raise ChangeStateError, event unless withdraw.public_send("may_#{event}?")
  end
end
