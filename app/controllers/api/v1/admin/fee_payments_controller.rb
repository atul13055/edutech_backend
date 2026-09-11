module Api
  module V1
    module Admin
      class FeePaymentsController < BaseController
        before_action :set_fee_payment, only: [ :show ]

        def index
          authorize FeePayment

          ActsAsTenant.without_tenant do
            scope = policy_scope(FeePayment).order(created_at: :desc)

            if params[:student_fee_assignment_id].present?
              scope = scope.where(student_fee_assignment_id: params[:student_fee_assignment_id])
            end

            if params[:student_id].present?
              scope = scope.where(student_id: params[:student_id])
            end

            if params[:payment_method].present?
              scope = scope.where(payment_method: params[:payment_method].to_s.downcase)
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            payments = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: FeePaymentBlueprint.render_as_json(payments),
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
          authorize @fee_payment
          render_success(data: FeePaymentBlueprint.render_as_json(@fee_payment))
        end

        def create
          payload = fee_payment_params.to_h.symbolize_keys
          dummy_payment = FeePayment.new(
            tenant_id: Current.user&.tenant_id || Current.tenant&.id,
            student_fee_assignment_id: payload[:student_fee_assignment_id]
          )
          authorize dummy_payment, :create?

          payment = Fees::PaymentCollectionService.call(
            payload,
            collector: Current.user,
            tenant_id: Current.user&.tenant_id || Current.tenant&.id
          )

          render_success(data: FeePaymentBlueprint.render_as_json(payment), status: :created)
        end

        def summary
          ActsAsTenant.without_tenant do
            assignment = StudentFeeAssignment.find_by!(id: params[:id])
            authorize assignment, :show?

            total_paid = assignment.total_paid_amount
            outstanding = assignment.outstanding_amount

            render_success(
              data: {
                student_fee_assignment_id: assignment.id,
                total_amount: assignment.total_amount,
                currency: assignment.currency,
                total_paid_amount: total_paid,
                outstanding_amount: outstanding,
                status: assignment.status,
                payment_count: assignment.fee_payments.where(status: "completed").count
              }
            )
          end
        end

        private

        def set_fee_payment
          ActsAsTenant.without_tenant do
            @fee_payment = policy_scope(FeePayment).find(params[:id])
          end
        end

        def fee_payment_params
          params.require(:fee_payment).permit(
            :student_fee_assignment_id,
            :amount,
            :currency,
            :payment_method,
            :payment_reference,
            :idempotency_key,
            :paid_at,
            :notes,
            :fee_installment_id,
            metadata: {}
          )
        end
      end
    end
  end
end
