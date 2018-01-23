module Deposits
  class Bank < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Bankable
    include ::FundSourceable

    def charge!(txid)
      binding.pry
      with_lock do
        submit!
        accept!
        touch(:done_at)
        update_attribute(:txid, txid)
      end
    end

  end
end
