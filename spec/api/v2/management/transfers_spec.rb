# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Management::Transfers, type: :request do
  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
      read_transfers:  { permitted_signers: %i[alex jeff],       mandatory_signers: %i[alex] },
      write_transfers: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
    }
  end

  describe 'create operation' do
    def request
      post_json '/api/v2/management/transfers/new', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:currency) { Currency.coins.sample }
    let(:signers) { %i[alex jeff] }
    let(:data) do
      { key:  generate(:transfer_key),
        kind: generate(:transfer_kind),
        desc: "Referral program payoffs (#{Time.now.to_date})",
        operations: operations}
    end
    let(:valid_operation) do
      { currency: :btc,
        amount:   0.0001,
        account_src: {
          code: 102
        },
        account_dst: {
          code: 102,
        }
      }
    end

    context 'empty key' do
      let(:operations) {[valid_operation]}

      before do
        data.delete(:key)
        request
      end

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/key is missing/i) }
    end

    context 'empty kind' do
      let(:operations) {[valid_operation]}

      before do
        data.delete(:kind)
        request
      end

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/kind is missing/i) }
    end

    context 'empty desc' do
      let(:operations) {[valid_operation]}

      before do
        data.delete(:desc)
        request
      end

      it { expect(response).to have_http_status(200) }
    end

    context 'empty operations' do
      let(:operations) {[]}

      before { request }

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/operations is empty/i) }
    end

    context 'invalid account code' do
      let(:operations) do
        valid_operation[:account_src][:code] = 999
        [valid_operation]
      end
      before { request }

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/does not have a valid value/i) }
    end

    context 'invalid currency' do
      let(:operations) do
        valid_operation[:currency] = :neo
        [valid_operation]
      end
      before { request }

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/does not have a valid value/i) }
    end

    context 'invalid amount' do
      let(:operations) do
        valid_operation[:amount] = -1
        [valid_operation]
      end
      before { request }

      it { expect(response).to have_http_status(422) }
      it { expect(response.body).to match(/does not have a valid value/i) }
    end

    context 'credit' do
      let(:dst_member) { create(:member, :barong) }

      # TODO: Remove hardcode from operations.
      let(:operations) do
        [
          {
            currency: :btc,
            amount:   0.0001,
            account_src: {
              code: 302
            },
            account_dst: {
              code: 202,
              uid: dst_member.uid
            }
          }
        ]
      end
      before { request }

      it { expect(response).to have_http_status 200 }

      it 'returns operation' do
        # binding.pry
        # expect(JSON.parse(response.body)['currency']).to eq currency.code.to_s
        # expect(JSON.parse(response.body)['credit'].to_d).to eq amount
        # expect(JSON.parse(response.body)['code']).to \
        #   eq Operations::Chart.code_for(type: op_type,
        #                                 kind: :main,
        #                                 currency_type: currency.type)
      end

      # it 'saves operation' do
      #   op_klass = "operations/#{op_type}"
      #                .camelize
      #                .constantize
      #   expect { request }.to \
      #     change(op_klass, :count).by(1)
      # end
    end
  end
end
