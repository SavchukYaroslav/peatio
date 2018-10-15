# encoding: UTF-8
# frozen_string_literal: true

class Ordering

  class CancelOrderError < StandardError; end

  def initialize(order_or_orders)
    @orders = Array(order_or_orders)
  end

  def submit
    ActiveRecord::Base.transaction { @orders.each(&method(:do_submit)) }

    @orders.each do |order|
      AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
    end

    true
  end

  def cancel
    @orders.each(&method(:do_cancel))
  end

  def cancel!
    ActiveRecord::Base.transaction { @orders.each(&method(:do_cancel!)) }
  end

private

  def do_submit(order)
    order.fix_number_precision # number must be fixed before computing locked
    order.locked = order.origin_locked = order.compute_locked

    # Get fee service for order submit action.
    fee_service = Peatio::FeeService.on_submit(:order, order)
    # Append fees to parent order.
    order.fees << fee_service.fees
    # Submit fees (lock_funds).
    fee_service.submit!

    order.save!
    order.hold_account!.lock_funds!(order.locked)
  end

  def do_cancel(order)
    AMQPQueue.enqueue(:matching, action: 'cancel', order: order.to_matching_attributes)
  end

  def do_cancel!(order)
    order.with_lock do
      return unless order.state == Order::WAIT

      # Get fee service for order cancel action.
      fee_service = Peatio::FeeService.on_cancel(:order, order)
      # Append fees to parent order.
      order.fees << fee_service.fees
      # Submit fees (lock_funds!).
      fee_service.submit!
      # Complete fees (unlock_and_sub_funds!, plus_funds!).
      Peatio::FeeService.new(order.fees).complete!

      order.hold_account!.unlock_funds!(order.locked)
      order.update!(state: Order::CANCEL)
    end
  end
end
