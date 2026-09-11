module Api
  module V1
    module Admin
      class FeePlansController < BaseController
        before_action :set_fee_plan, only: [ :show, :update, :destroy ]

        def index
          authorize FeePlan

          ActsAsTenant.without_tenant do
            scope = policy_scope(FeePlan).order(created_at: :desc)

            if params[:query].present?
              q = "%#{params[:query]}%"
              scope = scope.where("name ILIKE :q OR description ILIKE :q", q: q)
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            if params[:course_id].present?
              scope = scope.where(course_id: params[:course_id])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            fee_plans = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: FeePlanBlueprint.render_as_json(fee_plans),
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
          authorize @fee_plan
          render_success(data: FeePlanBlueprint.render_as_json(@fee_plan))
        end

        def create
          attrs = fee_plan_params
          attrs[:tenant_id] = Current.user&.tenant_id || Current.tenant&.id

          ActsAsTenant.without_tenant do
            @fee_plan = FeePlan.new(attrs)
            authorize @fee_plan
            @fee_plan.save!
          end

          render_success(data: FeePlanBlueprint.render_as_json(@fee_plan), status: :created)
        end

        def update
          authorize @fee_plan

          attrs = fee_plan_params
          attrs.delete(:tenant_id)

          ActsAsTenant.without_tenant do
            @fee_plan.update!(attrs)
          end

          render_success(data: FeePlanBlueprint.render_as_json(@fee_plan))
        end

        def destroy
          authorize @fee_plan

          ActsAsTenant.without_tenant do
            @fee_plan.destroy!
          end

          render_success(data: { message: "Fee plan deleted successfully" })
        end

        private

        def set_fee_plan
          ActsAsTenant.without_tenant do
            @fee_plan = policy_scope(FeePlan).find(params[:id])
          end
        end

        def fee_plan_params
          params.require(:fee_plan).permit(
            :course_id,
            :name,
            :description,
            :total_amount,
            :currency,
            :installment_count,
            :status
          )
        end
      end
    end
  end
end
