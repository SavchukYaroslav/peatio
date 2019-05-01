# encoding: UTF-8
# frozen_string_literal: true

describe Worker::DepositCollectionFees do
  let(:deposit) do
    create(:deposit, :deposit_trst).tap { |d| d.accept! }
  end
  let(:wallet) { Wallet.find_by_blockchain_key('eth-rinkeby') }
  let(:wallet_service) { WalletService2.new(wallet) }
  let(:txid) { Faker::Lorem.characters(64) }
  let(:spread) do
    [{ to_address: 'to-address', amount: 0.1 }]
  end

  before do
    spread_deposit_res = spread.map { |s| Peatio::Transaction.new(s) }
    WalletService2.any_instance
                  .expects(:spread_deposit)
                  .with(deposit, anything)
                  .returns(spread_deposit_res)

    deposit_collection_fees_res = [Peatio::Transaction.new(amount: 1, currency_id: :bbtc, hash: 'hash')]
    WalletService2.any_instance
                  .expects(:deposit_collection_fees!)
                  .with(deposit, anything)
                  .returns(deposit_collection_fees_res)
  end

  it 'calls spread_between_wallets!' do
    expect(deposit.spread).to eq([])
    expect(Worker::DepositCollectionFees.new.process(deposit)).to be_truthy
    expect(deposit.reload.spread).to eq(spread)
  end

  # it 'collect deposit and update spread' do
  #   expect(deposit.spread).to eq(spread)
  #   expect(deposit.collected?).to be_falsey
  #   expect{ Worker::DepositCollection.new.process(deposit) }.to change{ deposit.reload.spread }
  #   expect(deposit.spread).to eq(collected_spread)
  #   expect(deposit.collected?).to be_truthy
  # end
end
