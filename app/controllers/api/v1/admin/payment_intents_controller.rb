module Api
  module V1
    module Admin
      class PaymentIntentsController < BaseController
        before_action :set_payment_intent, only: [ :show, :reconcile ]

        def index
          authorize PaymentIntent

          ActsAsTenant.without_tenant do
            scope = policy_scope(PaymentIntent).order(created_at: :desc)

            scope = scope.where(status: params[:status]) if params[:status].present?
            scope = scope.where(student_id: params[:student_id]) if params[:student_id].present?
            scope = scope.where(student_fee_assignment_id: params[:student_fee_assignment_id]) if params[:student_fee_assignment_id].present?

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            records = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: PaymentIntentBlueprint.render_as_json(records),
              meta: {
                current_page: page,
                per_page: per_page,
                total_count: total_count,
                total_pages: (total_count.to_f / per_page).ceil
              }
            )
          end
        end

        def show
          authorize @payment_intent
          render_success(data: PaymentIntentBlueprint.render_as_json(@payment_intent))
        end

        def create
          authorize PaymentIntent, :create?

          intent = Payments::CreatePaymentIntentService.new(
            payment_intent_params,
            user: Current.user
          ).call

          render_success(
            data: PaymentIntentBlueprint.render_as_json(intent),
            status: :created
          )
        end

        def reconcile
          authorize @payment_intent, :reconcile?

          reconciled_intent = Payments::ReconciliationService.new(
            @payment_intent.id,
            result_status: params[:result_status],
            provider_transaction_id: params[:provider_transaction_id],
            failure_code: params[:failure_code],
            failure_message: params[:failure_message],
            notes: params[:notes],
            user: Current.user
          ).call

          render_success(data: PaymentIntentBlueprint.render_as_json(reconciled_intent))
        end

        private

        def set_payment_intent
          ActsAsTenant.without_tenant do
            @payment_intent = policy_scope(PaymentIntent).find(params[:id])
          end
        end

        def payment_intent_params
          params.require(:payment_intent).permit(
            :student_fee_assignment_id,
            :fee_installment_id,
            :amount,
            :currency,
            :payment_method,
            :provider_name,
            :provider_order_id,
            :client_reference,
            :idempotency_key,
            metadata: {}
          )
        end
      end
    end
  end
end
