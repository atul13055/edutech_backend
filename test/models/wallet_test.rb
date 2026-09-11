require "test_helper"

class WalletTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Test Branch", subdomain: "test-branch-wallet-m", code: "TBW-100", status: "active")
  end

  test "validates balance non-negativity" do
    wallet = Wallet.new(tenant: @tenant, balance: -10.00, currency: "INR")
    assert_not wallet.valid?
    assert_includes wallet.errors[:balance], "must be greater than or equal to 0"
  end

  test "validates presence of currency" do
    wallet = Wallet.new(tenant: @tenant, balance: 100.00, currency: nil)
    assert_not wallet.valid?
    assert_includes wallet.errors[:currency], "can't be blank"
  end

  test "belongs to tenant and has many wallet_transactions" do
    wallet = Wallet.create!(tenant: @tenant, balance: 500.00, currency: "INR")
    assert_equal @tenant, wallet.tenant
    assert_respond_to wallet, :wallet_transactions
  end
end
