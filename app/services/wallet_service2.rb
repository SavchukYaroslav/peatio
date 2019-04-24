class WalletService2
  attr_reader :wallet, :adapter

  def initialize(wallet)
    @wallet = wallet
    @adapter = Peatio::WalletAPI.adapter_for(wallet.gateway)
    @adapter.configure(wallet: @wallet.to_wallet_api_settings,
                       currency: @wallet.currency.to_blockchain_api_settings)
  end

  def create_address!(account)
    @adapter.create_address!(uid: account.member.uid)
  end

  def build_withdrawal!(withdrawal)
    transaction = Peatio::Transaction.new(address: withdrawal.rid,
                                          amount: withdrawal.amount)
    @adapter.create_transaction!(transaction)
  end

  def spread_deposit(deposit)
    destination_wallets =
      Wallet.active.withdraw.ordered
        .where(currency_id: deposit.currency_id)
        .map do |w|
        # TODO: What if we can't load current_balance ?
        # NOTE: Consider min_collection_amount is defined per wallet.
        #       For now min_collection_amount is currency config.
        { address:     w.address,
          balance:     w.current_balance,
          max_balance: w.max_balance,
          min_collection_amount: @wallet.currency.min_collection_amount }
      end

    spread_between_wallets(deposit.amount, destination_wallets)
  end

  def collect_deposit!(deposit, deposit_spread)
    pa = deposit.account.payment_address
    # NOTE: Deposit wallet configuration is tricky because wallet UIR
    #       is saved on Wallet model but wallet address and secret
    #       are saved in PaymentAddress.
    @adapter.configure(wallet: @wallet.to_wallet_api_settings
                                 .merge(address: pa.address, secret: pa.secret))

    deposit_spread.map { |t| @adapter.create_transaction!(t) }
  end

  def deposit_collection_fees!(deposit, deposit_spread)
    deposit_transaction = Peatio::Transaction.new(to_address:  deposit.address,
                                                  amount:      deposit.amount,
                                                  currency_id: deposit.currency_id)
    @adapter.prepare_deposit_collection!(deposit_transaction, deposit_spread)
  end

  private

  # @return [Array<Peatio::Transaction>] result of spread in form of
  # transactions array with amount and to_address defined.
  def spread_between_wallets(original_amount, destination_wallets)
    left_amount = original_amount

    destination_wallets.map do |dw|
      break if left_amount == 0

      amount_for_wallet = [dw[:max_balance] - dw[:balance], left_amount].min

      # If free amount for current wallet too small we will not able to collect it.
      # So we try to collect it to next wallets.
      next if amount_for_wallet < dw[:min_collection_amount]

      left_amount -= amount_for_wallet

      # If amount left is too small we will not able to collect it.
      # So we collect everything to current wallet.
      if left_amount < dw[:min_collection_amount]
        amount_for_wallet += left_amount
        left_amount = 0
      end

      Peatio::Transaction.new(to_address:   dw[:address],
                              amount:       amount_for_wallet,
                              currency_id:  @wallet.currency_id)
    rescue => e
      # If have exception skip wallet.
      report_exception(e)
    end.tap do |spread|
      if left_amount > 0
        # If deposit doesn't fit to any wallet collect it to last wallet.
        # Since the last wallet is considered to be the most secure.
        spread.last.amount += left_amount
        left_amount += 0
      end

      unless spread.map(&:amount).sum == original_amount
        raise Error, "Deposit spread failed deposit.amount != collection_spread.values.sum"
      end
    end
  end
end
