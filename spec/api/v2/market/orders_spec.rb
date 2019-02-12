# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Market::Orders, type: :request do
  let(:member) { create(:member, :level_3) }
  let(:level_0_member) { create(:member, :level_0) }
  let(:token) { jwt_for(member) }
  let(:level_0_member_token) { jwt_for(level_0_member) }

  describe 'GET /api/v2/market/orders' do
    before do
      create(:order_bid, :btcusd, price: '11'.to_d, volume: '123.123456789', member: member)
      create(:order_bid, :dashbtc, price: '11'.to_d, volume: '123.123456789', member: member)
      create(:order_bid, :btcusd, price: '12'.to_d, volume: '123.123456789', member: member, state: Order::CANCEL)
      create(:order_ask, :btcusd, price: '13'.to_d, volume: '123.123456789', member: member, state: Order::WAIT)
      create(:order_ask, :btcusd, price: '14'.to_d, volume: '123.123456789', member: member, state: Order::DONE)
    end

    it 'requires authentication' do
      get '/api/v2/market/orders', market: 'btcusd'
      expect(response.code).to eq '401'
    end

    it 'validates market param' do
      api_get '/api/v2/market/orders', params: { market: 'usdusd' }, token: token
      expect(response).to have_http_status 422
      expect(response).to include_api_error('market.market.doesnt_exist')
    end

    it 'validates state param' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd', state: 'test' }, token: token
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.invalid_state')
    end

    it 'validates limit param' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd', limit: -1 }, token: token
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.invalid_limit')
    end

    it 'returns all order history' do
      api_get '/api/v2/market/orders', token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(response.headers.fetch('Total')).to eq '5'
      expect(result.size).to eq 5
    end

    it 'returns all my orders for btcusd market' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd' }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(response.headers.fetch('Total')).to eq '4'
      expect(result.size).to eq 4
    end

    it 'returns orders with state done' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd', state: Order::DONE }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(response.headers.fetch('Total')).to eq '1'
      expect(result.size).to eq 1
      expect(result.first['state']).to eq Order::DONE
    end

    it 'returns paginated orders' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd', limit: 1, page: 1 }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(response.headers.fetch('Total')).to eq '4'
      expect(result.first['price']).to eq '14.0'

      api_get '/api/v2/market/orders', params: { market: 'btcusd', limit: 1, page: 2 }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(response.headers.fetch('Total')).to eq '4'
      expect(result.first['price']).to eq '13.0'
    end

    it 'returns sorted orders' do
      api_get '/api/v2/market/orders', params: { market: 'btcusd', order_by: 'asc' }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(result.first['id']).to be < result.second['id']

      api_get '/api/v2/market/orders', params: { market: 'btcusd', order_by: 'desc' }, token: token
      result = JSON.parse(response.body)

      expect(response).to be_success
      expect(result.first['id']).to be > result.second['id']
    end

    it 'denies access to unverified member' do
      api_get '/api/v2/market/orders', token: level_0_member_token
      expect(response.code).to eq '403'
      expect(response).to include_api_error('market.trade.not_permitted')
    end

    it 'removes whitespace from query params and returns all orders' do
      api_get '/api/v2/market/orders', token: token, params: { market: ' btcusd ' }

      expect(response).to have_http_status 200
      expect(response.headers.fetch('Total')).to eq '4'
    end
  end

  describe 'GET /api/v2/market/orders/:id' do
    let(:order)  { create(:order_bid, :btcusd, price: '12.326'.to_d, volume: '3.14', origin_volume: '12.13', member: member, trades_count: 1) }
    let!(:trade) { create(:trade, :btcusd, bid: order) }

    it 'should get specified order' do
      api_get "/api/v2/market/orders/#{order.id}", token: token
      expect(response).to be_success

      result = JSON.parse(response.body)
      expect(result['id']).to eq order.id
      expect(result['executed_volume']).to eq '8.99'
    end

    it 'should include related trades' do
      api_get "/api/v2/market/orders/#{order.id}", token: token

      result = JSON.parse(response.body)
      expect(result['trades_count']).to eq 1
      expect(result['trades'].size).to eq 1
      expect(result['trades'].first['id']).to eq trade.id
      expect(result['trades'].first['side']).to eq 'buy'
    end

    it 'should get 404 error when order doesn\'t exist' do
      api_get '/api/v2/market/orders/1234', token: token
      expect(response.code).to eq '404'
      expect(response).to include_api_error('record.not_found')
    end
  end

  describe 'POST /api/v2/market/orders' do
    it 'creates a sell order' do
      member.get_account(:btc).update_attributes(balance: 100)

      expect do
        api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: '12.13', price: '2014' }
        expect(response).to be_success
        expect(JSON.parse(response.body)['id']).to eq OrderAsk.last.id
      end.to change(OrderAsk, :count).by(1)
    end

    it 'creates a buy order' do
      member.get_account(:usd).update_attributes(balance: 100_000)

      expect do
        api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'buy', volume: '12.13', price: '2014' }
        expect(response).to be_success
        expect(JSON.parse(response.body)['id']).to eq OrderBid.last.id
      end.to change(OrderBid, :count).by(1)
    end

    it 'validates volume positiveness' do
      old_count = OrderAsk.count
      api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: '-1.1', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.negative_volume')
      expect(OrderAsk.count).to eq old_count
    end

    it 'validates volume to be a number' do
      api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: 'test', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.non_decimal_volume')
    end

    it 'validates enough funds' do
      old_count = OrderAsk.count
      api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: '12.13', price: '2014' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.account.not_enough_funds')
      expect(OrderAsk.count).to eq old_count
    end

    it 'validates price positiveness' do
      api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: '12.13', price: '-1.1' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.negative_price')
    end

    it 'validates price to be a number' do
      api_post '/api/v2/market/orders', token: token, params: { market: 'btcusd', side: 'sell', volume: '12.13', price: 'test' }
      expect(response.code).to eq '422'
      expect(response).to include_api_error('market.order.non_decimal_price')
    end
  end

  describe 'POST /api/v2/market/orders/:id/cancel' do
    let!(:order) { create(:order_bid, :btcusd, price: '12.326'.to_d, volume: '3.14', origin_volume: '12.13', locked: '20.1082', origin_locked: '38.0882', member: member) }

    context 'succesful' do
      before do
        member.get_account(:usd).update_attributes(locked: order.price * order.volume)
      end

      it 'should cancel specified order' do
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: order.to_matching_attributes)
        expect do
          api_post "/api/v2/market/orders/#{order.id}/cancel", token: token
          expect(response).to be_success
          expect(JSON.parse(response.body)['id']).to eq order.id
        end.not_to change(Order, :count)
      end
    end

    context 'failed' do
      it 'should return order not found error' do
        api_post '/api/v2/market/orders/0/cancel', token: token
        expect(response.code).to eq '404'
        expect(response).to include_api_error('record.not_found')
      end
    end
  end

  describe 'POST /api/v2/market/orders/cancel' do
    before do
      create(:order_ask, :btcusd, price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)
      create(:order_bid, :btcusd, price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)

      member.get_account(:btc).update_attributes(locked: '5')
      member.get_account(:usd).update_attributes(locked: '50')
    end

    it 'should cancel all my orders' do
      member.orders.each do |o|
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect do
        api_post '/api/v2/market/orders/cancel', token: token
        expect(response).to be_success

        result = JSON.parse(response.body)
        expect(result.size).to eq 2
      end.not_to change(Order, :count)
    end

    it 'should cancel all my asks' do
      member.orders.where(type: 'OrderAsk').each do |o|
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect do
        api_post '/api/v2/market/orders/cancel', token: token, params: { side: 'sell' }
        expect(response).to be_success

        result = JSON.parse(response.body)
        expect(result.size).to eq 1
        expect(result.first['id']).to eq member.orders.where(type: 'OrderAsk').first.id
      end.not_to change(Order, :count)
    end

    it 'strips leading and trailing whitespace from params' do
      member.orders.where(type: 'OrderAsk').each do |o|
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect do
        api_post '/api/v2/market/orders/cancel', token: token, params: { side: 'sell ' }
        expect(response).to be_success
      end.not_to change(Order, :count)
    end
  end
end
