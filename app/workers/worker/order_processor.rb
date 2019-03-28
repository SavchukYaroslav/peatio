# encoding: UTF-8
# frozen_string_literal: true

module Worker
  class OrderProcessor

    def process(payload)
      case payload['action']
      when 'submit'
        order = Order.find_by_id(payload.dig('order', 'id'))
        submit(order) if order
      when 'cancel'
        order = Order.find_by_id(payload.dig('order', 'id'))
        cancel(order) if order
      end
    end

  private

    def submit(order)
      order.with_lock do
        return unless order.state == Order::PENDING

        order.hold_account!.lock_funds!(order.locked)
        order.record_submit_operations!
        order.update!(state: ::Order::WAIT)

        AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
      end
    rescue e
      report_exception_to_screen(e)
    end

    def cancel(order)
      order.with_lock do
        return unless order.state == Order::WAIT
 
        order.hold_account!.unlock_funds!(order.locked)
        order.record_cancel_operations!

        order.update!(state: ::Order::CANCEL)
      end
    rescue e
      report_exception_to_screen(e)
    end
  end
end
