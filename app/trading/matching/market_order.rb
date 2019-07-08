# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constants'

module Matching
  class MarketOrder < AbstractOrder

    attr :id, :timestamp, :type, :locked, :market
    attr_accessor :volume

    def initialize(attrs)
      @id         = attrs[:id]
      @timestamp  = attrs[:timestamp]
      @type       = attrs[:type].to_sym
      @locked     = attrs[:locked].to_d
      @volume     = attrs[:volume].to_d
      @market     = attrs[:market]

      raise ::Matching::LegacyInvalidOrderError.new(attrs) unless valid?(attrs)
    end

    def trade_with(counter_order, counter_book)
      if counter_order.is_a?(LimitOrder)
        trade_price  = counter_order.price
        trade_volume = [volume, counter_order.volume].min
        trade_funds  = trade_price * trade_volume
        raise OrderError.new(self, 'Market order out of locked') if trade_funds > locked

        [trade_price, trade_volume, trade_funds]
      elsif price = counter_book.best_limit_price
        trade_price  = price
        trade_volume = [volume, counter_order.volume].min
        trade_funds  = trade_price * trade_volume

        raise OrderError.new(self, 'Market order out of locked') if trade_funds > locked
        raise OrderError.new(counter_order, 'Market order out of locked') if trade_funds > counter_order.locked

        [trade_price, trade_volume, trade_funds]
      end
    end

    # def trade_with(counter_order, counter_book)
    #   if counter_order.is_a?(LimitOrder)
    #     trade_price  = counter_order.price
    #     trade_volume = [volume, counter_order.volume].min.yield_self { |d| round2(d) }
    #
    #     if volume_limit(trade_price) < trade_volume
    #       trade_volume = volume_limit(trade_price).yield_self { |d| round2(d) }
    #
    #       trade_funds = locked
    #     else
    #       trade_funds = round2(trade_price * trade_volume)
    #     end
    #
    #     [trade_price, trade_volume, trade_funds]
    #   elsif price = counter_book.best_limit_price
    #     trade_price  = price
    #     trade_volume = [volume, volume_limit(trade_price), counter_order.volume, counter_order.volume_limit(trade_price)].min
    #     trade_funds  = trade_price*trade_volume
    #     [trade_price, trade_volume, trade_funds]
    #   end
    # end

    def round2(d)
      d.round(Market::DB_DECIMAL_PRECISION, BigDecimal::ROUND_DOWN)
    end

    def volume_limit(trade_price)
      type == :ask ? locked : locked/trade_price
    end

    def fill(trade_price, trade_volume, trade_funds)
      raise NotEnoughVolume if trade_volume > @volume
      @volume -= trade_volume

      funds = type == :ask ? trade_volume : trade_funds
      raise ExceedSumLimit if funds > @locked
      @locked -= funds
    end

    def filled?
      volume <= ZERO || locked <= ZERO
    end

    def label
      "%d/%s" % [id, volume.to_s('F')]
    end

    def valid?(attrs)
      return false unless [:ask, :bid].include?(type)
      return false if attrs[:price].present? # should have no limit price
      id && timestamp && market && locked > ZERO
    end

    def attributes
      { id: @id,
        timestamp: @timestamp,
        type: @type,
        locked: @locked,
        volume: @volume,
        market: @market,
        ord_type: 'market' }
    end
  end
end
