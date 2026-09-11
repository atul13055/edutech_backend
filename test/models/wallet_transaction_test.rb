require "test_helper"

class WalletTransactionTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Test Branch", subdomain: "test-branch-wtx-m", code: "TBWTX-100", status: "active")
    @wallet = Wallet.create!(tenant: @tenant, balance: 1000.00, currency: "INR")
  end

  test "validates transaction_type inclusion" do
    tx = WalletTransaction.new(
      wallet: @wallet,
      tenant: @tenant,
      transaction_type: "invalid_type",
      amount: 100,
      balance_before: 1000,
      balance_after: 900
    )
    assert_not tx.valid?
    assert_includes tx.errors[:transaction_type], "is not included in the list"
  end

  test "validates positive amount" do
    tx = WalletTransaction.new(
      wallet: @wallet,
      tenant: @tenant,
      transaction_type: "credit",
      amount: 0,
      balance_before: 1000,
      balance_after: 1000
    )
    assert_not tx.valid?
    assert_includes tx.errors[:amount], "must be greater than 0"
  end

  test "enforces transaction immutability on update and destroy" do
    tx = WalletTransaction.create!(
      wallet: @wallet,
      tenant: @tenant,
      transaction_type: "credit",
      amount: 500,
      balance_before: 1000,
      balance_after: 1500,
      reference: "RECHARGE_001"
    )

    assert_raises(ActiveRecord::RecordNotSaved) do
      tx.update!(reference: "MUTATED_REF")
    end

    assert_raises(ActiveRecord::RecordNotDestroyed) do
      tx.destroy!
    end

    assert_equal "RECHARGE_001", tx.reload.reference
  end
end
