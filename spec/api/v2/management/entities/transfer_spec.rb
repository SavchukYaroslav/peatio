# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Management::Entities::Transfer do
  let(:record) { create(:transfer) }
  subject { OpenStruct.new API::V2::Management::Entities::Transfer.represent(record).serializable_hash }

  it { expect(subject.key).to eq record.key }
  it { expect(subject.kind).to eq record.kind }
  it { expect(subject.desc).to eq record.desc }
end
