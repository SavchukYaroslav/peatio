class RenameMarketFeeColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :markets, :ask_fee, :taker_fee if column_exists?(:markets, :ask_fee)
    rename_column :markets, :bid_fee, :maker_fee if column_exists?(:markets, :bid_fee)
  end
end
