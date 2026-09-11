module Api
  module V1
    module Admin
      class WalletTransactionsController < BaseController
        def index
          authorize WalletTransaction

          scope = policy_scope(WalletTransaction).order(created_at: :desc)
          scope = scope.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?

          page = [ (params[:page] || 1).to_i, 1 ].max
          per_page = [ (params[:per_page] || 20).to_i, 100 ].min
          total_count = scope.count

          transactions = scope.offset((page - 1) * per_page).limit(per_page)

          render_success(
            data: WalletTransactionBlueprint.render_as_json(transactions),
            meta: {
              current_page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          )
        end

        def show
          transaction = policy_scope(WalletTransaction).find(params[:id])
          authorize transaction

          render_success(data: WalletTransactionBlueprint.render_as_json(transaction))
        end
      end
    end
  end
end
