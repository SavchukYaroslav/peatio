class DropLegacyFees < ActiveRecord::Migration
  def change
    # Drop fees from Withdraw Order and Deposit
    # Drop account from Withdraw.
    remove_column :withdraws, :account_id
  end
end
