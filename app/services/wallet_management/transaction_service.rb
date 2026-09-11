module WalletManagement
  class InsufficientBalanceError < StandardError; end
  class DuplicateIdempotencyError < StandardError; end
  class InvalidAmountError < StandardError; end

  class TransactionService
    def self.credit(tenant:, amount:, reference: nil, idempotency_key: nil, metadata: {})
      new(tenant: tenant).process(
        transaction_type: "credit",
        amount: amount,
        reference: reference,
        idempotency_key: idempotency_key,
        metadata: metadata
      )
    end

    def self.debit(tenant:, amount:, reference: nil, idempotency_key: nil, metadata: {})
      new(tenant: tenant).process(
        transaction_type: "debit",
        amount: amount,
        reference: reference,
        idempotency_key: idempotency_key,
        metadata: metadata
      )
    end

    def initialize(tenant:)
      raise ArgumentError, "Tenant is required" if tenant.nil?

      @tenant = tenant
    end

    def process(transaction_type:, amount:, reference: nil, idempotency_key: nil, metadata: {})
      type = transaction_type.to_s.strip.downcase
      unless %w[credit debit].include?(type)
        raise ArgumentError, "Invalid transaction type: #{transaction_type}"
      end

      parsed_amount = parse_amount(amount)
      clean_idempotency_key = idempotency_key.to_s.strip.presence

      # Fast return if transaction already exists for idempotency key
      if clean_idempotency_key.present?
        existing_tx = WalletTransaction.find_by(idempotency_key: clean_idempotency_key, tenant_id: @tenant.id)
        return existing_tx if existing_tx.present?
      end

      WalletTransaction.transaction do
        # Find or create wallet for tenant and acquire row-level lock
        wallet = Wallet.find_or_create_by!(tenant_id: @tenant.id)
        wallet.lock!

        # Double-check idempotency key inside lock
        if clean_idempotency_key.present?
          existing_tx = WalletTransaction.find_by(idempotency_key: clean_idempotency_key, tenant_id: @tenant.id)
          return existing_tx if existing_tx.present?
        end

        balance_before = wallet.balance

        if type == "debit"
          if balance_before < parsed_amount
            raise InsufficientBalanceError, "Insufficient wallet balance (Current: #{balance_before.to_s('F')}, Required: #{parsed_amount.to_s('F')})"
          end

          balance_after = balance_before - parsed_amount
        else
          balance_after = balance_before + parsed_amount
        end

        tx = WalletTransaction.create!(
          wallet: wallet,
          tenant: @tenant,
          transaction_type: type,
          amount: parsed_amount,
          balance_before: balance_before,
          balance_after: balance_after,
          reference: reference.to_s.strip.presence,
          idempotency_key: clean_idempotency_key,
          metadata: metadata || {}
        )

        wallet.update!(balance: balance_after)
        tx
      end
    rescue ActiveRecord::RecordNotUnique => e
      if clean_idempotency_key.present? && e.message.include?("idempotency_key")
        WalletTransaction.find_by!(idempotency_key: clean_idempotency_key, tenant_id: @tenant.id)
      else
        raise
      end
    end

    private

    def parse_amount(amount)
      val = BigDecimal(amount.to_s)
      raise InvalidAmountError, "Amount must be greater than zero" if val <= 0

      val.round(2)
    rescue ArgumentError, TypeError
      raise InvalidAmountError, "Invalid monetary amount format"
    end
  end
end
