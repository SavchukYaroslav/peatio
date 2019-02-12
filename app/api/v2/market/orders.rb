# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Market
      class Orders < Grape::API
        helpers ::API::V2::NamedParams

        desc 'Get your orders, results is paginated.',
          is_array: true,
          success: API::V2::Entities::Order
        params do
          optional :market,
                   type: { value: String, message: 'market.market.non_string' },
                   values: { value: -> { ::Market.enabled.ids }, message: 'market.market.doesnt_exist' },
                   desc: -> { V2::Entities::Market.documentation[:id] }
          optional :state,
                   type: { value: String, message: 'market.order.non_string_state' },
                   values: { value: -> { Order.state.values } , message: 'market.order.invalid_state' },
                   desc: 'Filter order by state.'
          optional :limit,
                   type: { value: Integer, message: 'market.order.non_integer_limit' },
                   default: 100,
                   values: { value: 0..1000, message: 'market.order.invalid_limit' },
                   desc: 'Limit the number of returned orders, default to 100.'
          optional :page,
                   type: { value: Integer, message: 'market.order.non_integer_page' },
                   default: 1,
                   desc: 'Specify the page of paginated results.'
          optional :order_by,
                   type: { value: String, message: 'market.order.non_string_order_by' },
                   values: { value: %w(asc desc), message: 'market.order.invalid_order_by' },
                   default: 'desc',
                   desc: 'If set, returned orders will be sorted in specific order, default to "desc".'
        end
        get '/orders' do
          current_user.orders.order(order_param)
                      .tap { |q| q.where!(market: params[:market]) if params[:market] }
                      .tap { |q| q.where!(state: params[:state]) if params[:state] }
                      .tap { |q| present paginate(q), with: API::V2::Entities::Order }
        end

        desc 'Get information of specified order.',
          success: API::V2::Entities::Order
        params do
          use :order_id
        end
        get '/orders/:id' do
          order = current_user.orders.find_by!(id: params[:id])
          present order, with: API::V2::Entities::Order, type: :full
        end

        desc 'Create a Sell/Buy order.',
          success: API::V2::Entities::Order
        params do
          use :market, :order
        end
        post '/orders' do
          order = create_order params
          present order, with: API::V2::Entities::Order
        rescue Order::InsufficientMarketVolume => e
          error!({ errors: ['market.order.insufficient_market_volume'] }, 422)
        end

        desc 'Cancel an order.'
        params do
          use :order_id
        end
        post '/orders/:id/cancel' do
          begin
            order = current_user.orders.find(params[:id])
            Ordering.new(order).cancel
            present order, with: API::V2::Entities::Order
          rescue ActiveRecord::RecordNotFound => e
            # RecordNotFound in rescued by ExceptionsHandler.
            raise(e)
          rescue
            error!({ errors: ['market.order.cancel_error'] }, 422)
          end
        end

        desc 'Cancel all my orders.',
          success: API::V2::Entities::Order
        params do
          optional :side, type: String, values: %w(sell buy), desc: 'If present, only sell orders (asks) or buy orders (bids) will be canncelled.'
        end
        post '/orders/cancel' do
          begin
            orders = current_user.orders.with_state(:wait)
            if params[:side].present?
              type = params[:side] == 'sell' ? 'OrderAsk' : 'OrderBid'
              orders = orders.where(type: type)
            end
            orders.each {|o| Ordering.new(o).cancel }
            present orders, with: API::V2::Entities::Order
          rescue
            error!({ errors: ['market.order.cancel_error'] }, 422)
          end
        end
      end
    end
  end
end
