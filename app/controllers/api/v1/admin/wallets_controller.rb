module Api
  module V1
    module Admin
      class WalletsController < BaseController
        before_action :set_wallet, only: [ :show, :debit ]

        def show
          authorize @wallet
          render_success(data: WalletBlueprint.render_as_json(@wallet))
        end

        def credit
          target_tenant = resolve_target_tenant
          @wallet = Wallet.find_or_create_by!(tenant_id: target_tenant.id)
          authorize @wallet, :credit?

          tx = WalletManagement::TransactionService.credit(
            tenant: target_tenant,
            amount: wallet_params[:amount],
            reference: wallet_params[:reference],
            idempotency_key: wallet_params[:idempotency_key],
            metadata: wallet_params[:metadata]
          )

          @wallet.reload
          render_success(
            data: {
              wallet: WalletBlueprint.render_as_json(@wallet),
              transaction: WalletTransactionBlueprint.render_as_json(tx)
            },
            status: :created
          )
        end

        def debit
          authorize @wallet, :debit?

          tx = WalletManagement::TransactionService.debit(
            tenant: current_tenant,
            amount: wallet_params[:amount],
            reference: wallet_params[:reference],
            idempotency_key: wallet_params[:idempotency_key],
            metadata: wallet_params[:metadata]
          )

          @wallet.reload
          render_success(
            data: {
              wallet: WalletBlueprint.render_as_json(@wallet),
              transaction: WalletTransactionBlueprint.render_as_json(tx)
            },
            status: :created
          )
        end

        private

        def set_wallet
          @wallet = Wallet.find_or_create_by!(tenant_id: current_tenant.id)
        end

        def resolve_target_tenant
          if params[:tenant_id].present? && current_user.tenant_id.nil? && current_user.role&.key == "super_admin"
            Tenant.find(params[:tenant_id])
          else
            current_tenant
          end
        end

        def wallet_params
          params.permit(:amount, :reference, :idempotency_key, :tenant_id, metadata: {})
        end
      end
    end
  end
end
