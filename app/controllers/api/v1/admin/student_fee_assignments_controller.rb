module Api
  module V1
    module Admin
      class StudentFeeAssignmentsController < BaseController
        before_action :set_assignment, only: [ :show ]

        def index
          authorize StudentFeeAssignment

          ActsAsTenant.without_tenant do
            scope = policy_scope(StudentFeeAssignment).order(created_at: :desc)

            if params[:student_id].present?
              scope = scope.where(student_id: params[:student_id])
            end

            if params[:admission_id].present?
              scope = scope.where(admission_id: params[:admission_id])
            end

            if params[:fee_plan_id].present?
              scope = scope.where(fee_plan_id: params[:fee_plan_id])
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            assignments = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: StudentFeeAssignmentBlueprint.render_as_json(assignments),
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
          authorize @assignment
          render_success(data: StudentFeeAssignmentBlueprint.render_as_json(@assignment))
        end

        def create
          attrs = assignment_params
          attrs[:tenant_id] = Current.user&.tenant_id || Current.tenant&.id
          attrs[:assigned_at] ||= Time.current

          ActsAsTenant.without_tenant do
            @assignment = StudentFeeAssignment.new(attrs)
            authorize @assignment
            @assignment.save!
          end

          render_success(data: StudentFeeAssignmentBlueprint.render_as_json(@assignment), status: :created)
        end

        private

        def set_assignment
          ActsAsTenant.without_tenant do
            @assignment = policy_scope(StudentFeeAssignment).find(params[:id])
          end
        end

        def assignment_params
          params.require(:student_fee_assignment).permit(
            :student_id,
            :admission_id,
            :fee_plan_id,
            :total_amount,
            :currency,
            :assigned_at,
            :notes
          )
        end
      end
    end
  end
end
