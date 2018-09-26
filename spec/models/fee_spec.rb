# encoding: UTF-8
# frozen_string_literal: true

describe Fee do
  context 'validations' do

    let(:member) { create(:member, :level_3) }
    let(:account) do
      member
        .accounts
        .find_by(currency_id: :btc)
        .tap { |a| a.update_attributes(balance: 100) }
    end

    let(:order) { create(:order_bid, market_id: 'btcusd', price: '10.01'.to_d, volume: '3.11'.to_d, member: member) }

    subject { Fee.new(source_account: account, parent: order, amount: 0.01 ) }

    it 'checks valid record' do
      expect(subject).to be_valid
    end

    it 'validates parent presence' do
      subject.parent = nil
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to include 'Parent can\'t be blank'
    end

    it 'validates source_account presence' do
      subject.source_account = nil
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to include 'Source account can\'t be blank'
    end

    it 'validates amount presence' do
      subject.amount = nil
      expect(subject).to_not be_valid
      expect(subject.errors.full_messages).to include 'Amount can\'t be blank'
    end
  end
end
