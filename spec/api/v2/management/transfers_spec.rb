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
        { key:  42,
          kind: 'referral-payoff',
          desc: "Referral program payoffs (#{Time.now.to_date})" }
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
        before do
          data[:operations] = operations
          request
        end

        it { expect(response).to have_http_status 200 }

        it 'returns operation' do
          binding.pry
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
