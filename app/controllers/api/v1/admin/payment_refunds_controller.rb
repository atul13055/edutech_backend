module Api
  module V1
    module Admin
      class PaymentRefundsController < BaseController
        before_action :set_payment_refund, only: [ :show, :approve, :process_refund ]

        def index
          authorize PaymentRefund

          ActsAsTenant.without_tenant do
            scope = policy_scope(PaymentRefund).order(created_at: :desc)

            scope = scope.where(status: params[:status]) if params[:status].present?
            scope = scope.where(fee_payment_id: params[:fee_payment_id]) if params[:fee_payment_id].present?
            scope = scope.where(student_id: params[:student_id]) if params[:student_id].present?
            scope = scope.where(student_fee_assignment_id: params[:student_fee_assignment_id]) if params[:student_fee_assignment_id].present?

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            records = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: PaymentRefundBlueprint.render_as_json(records),
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
          authorize @payment_refund
          render_success(data: PaymentRefundBlueprint.render_as_json(@payment_refund))
        end

        def create
          authorize PaymentRefund, :create?

          refund = Fees::CreateRefundService.new(
            refund_params,
            user: Current.user
          ).call

          render_success(
            data: PaymentRefundBlueprint.render_as_json(refund),
            status: :created
          )
        end

        def approve
          authorize @payment_refund, :approve?

          approved_refund = Fees::ApproveRefundService.new(
            @payment_refund.id,
            user: Current.user,
            notes: params[:notes]
          ).call

          render_success(data: PaymentRefundBlueprint.render_as_json(approved_refund))
        end

        def process_refund
          authorize @payment_refund, :process_refund?

          processed_refund = Fees::ProcessRefundService.new(
            @payment_refund.id,
            refund_reference: params[:refund_reference],
            user: Current.user
          ).call

          render_success(data: PaymentRefundBlueprint.render_as_json(processed_refund))
        end

        private

        def set_payment_refund
          ActsAsTenant.without_tenant do
            @payment_refund = policy_scope(PaymentRefund).find(params[:id])
          end
        end

        def refund_params
          params.require(:payment_refund).permit(
            :fee_payment_id,
            :amount,
            :currency,
            :reason,
            :idempotency_key,
            :notes,
            :auto_process,
            metadata: {}
          )
        end
      end
    end
  end
end
