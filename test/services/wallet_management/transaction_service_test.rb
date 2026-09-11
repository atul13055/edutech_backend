require "test_helper"

module WalletManagement
  class TransactionServiceTest < ActiveSupport::TestCase
    def setup
      # Trigger autoload of WalletManagement module and error classes
      ::WalletManagement::TransactionService
      @tenant = Tenant.create!(name: "Test Branch Service", subdomain: "test-branch-svc", code: "TBSVC-100", status: "active")
      @wallet = Wallet.find_or_create_by!(tenant_id: @tenant.id)
      @wallet.update!(balance: 1000.00)
    end

    test "credits wallet balance atomically" do
      tx = TransactionService.credit(
        tenant: @tenant,
        amount: 250.50,
        reference: "CREDIT_TEST_001"
      )

      assert_equal "credit", tx.transaction_type
      assert_equal BigDecimal("250.50"), tx.amount
      assert_equal BigDecimal("1000.00"), tx.balance_before
      assert_equal BigDecimal("1250.50"), tx.balance_after
      assert_equal BigDecimal("1250.50"), @wallet.reload.balance
    end

    test "debits wallet balance atomically" do
      tx = TransactionService.debit(
        tenant: @tenant,
        amount: 400.00,
        reference: "DEBIT_TEST_001"
      )

      assert_equal "debit", tx.transaction_type
      assert_equal BigDecimal("400.00"), tx.amount
      assert_equal BigDecimal("1000.00"), tx.balance_before
      assert_equal BigDecimal("600.00"), tx.balance_after
      assert_equal BigDecimal("600.00"), @wallet.reload.balance
    end

    test "raises InsufficientBalanceError when debit exceeds balance" do
      assert_raises(::WalletManagement::InsufficientBalanceError) do
        TransactionService.debit(
          tenant: @tenant,
          amount: 1500.00
        )
      end

      assert_equal BigDecimal("1000.00"), @wallet.reload.balance
    end

    test "raises InvalidAmountError for negative or zero amounts" do
      assert_raises(::WalletManagement::InvalidAmountError) do
        TransactionService.credit(tenant: @tenant, amount: 0)
      end

      assert_raises(::WalletManagement::InvalidAmountError) do
        TransactionService.debit(tenant: @tenant, amount: -50)
      end
    end

    test "enforces idempotency key protection and prevents duplicate transactions" do
      key = "IDEMPOTENT_KEY_999"

      tx1 = TransactionService.credit(
        tenant: @tenant,
        amount: 100.00,
        idempotency_key: key
      )

      tx2 = TransactionService.credit(
        tenant: @tenant,
        amount: 100.00,
        idempotency_key: key
      )

      assert_equal tx1.id, tx2.id
      assert_equal BigDecimal("1100.00"), @wallet.reload.balance
      assert_equal 1, WalletTransaction.where(idempotency_key: key).count
    end

    test "supports concurrent operations without balance corruption" do
      threads = []
      5.times do |i|
        threads << Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            TransactionService.credit(tenant: @tenant, amount: 100.00, reference: "TH_#{i}")
          end
        end
      end
      threads.each(&:join)

      assert_equal BigDecimal("1500.00"), @wallet.reload.balance
    end
  end
end
