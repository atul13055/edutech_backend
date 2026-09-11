module Api
  module V1
    module Admin
      class FeeInstallmentsController < BaseController
        before_action :set_fee_plan
        before_action :set_installment, only: [ :show, :update, :destroy ]

        def index
          authorize FeeInstallment

          ActsAsTenant.without_tenant do
            installments = policy_scope(@fee_plan.fee_installments).order(:installment_number)
            render_success(data: FeeInstallmentBlueprint.render_as_json(installments))
          end
        end

        def show
          authorize @installment
          render_success(data: FeeInstallmentBlueprint.render_as_json(@installment))
        end

        def create
          attrs = installment_params
          attrs[:tenant_id] = @fee_plan.tenant_id

          ActsAsTenant.without_tenant do
            @installment = @fee_plan.fee_installments.build(attrs)
            authorize @installment
            @installment.save!
          end

          render_success(data: FeeInstallmentBlueprint.render_as_json(@installment), status: :created)
        end

        def update
          authorize @installment

          attrs = installment_params
          attrs.delete(:tenant_id)
          attrs.delete(:fee_plan_id)

          ActsAsTenant.without_tenant do
            @installment.update!(attrs)
          end

          render_success(data: FeeInstallmentBlueprint.render_as_json(@installment))
        end

        def destroy
          authorize @installment

          ActsAsTenant.without_tenant do
            @installment.destroy!
          end

          render_success(data: { message: "Fee installment deleted successfully" })
        end

        private

        def set_fee_plan
          ActsAsTenant.without_tenant do
            @fee_plan = policy_scope(FeePlan).find(params[:fee_plan_id])
          end
        end

        def set_installment
          ActsAsTenant.without_tenant do
            @installment = policy_scope(@fee_plan.fee_installments).find(params[:id])
          end
        end

        def installment_params
          params.require(:installment).permit(
            :installment_number,
            :name,
            :amount,
            :due_days_offset,
            :status
          )
        end
      end
    end
  end
end
