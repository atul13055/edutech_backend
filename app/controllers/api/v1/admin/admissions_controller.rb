module Api
  module V1
    module Admin
      class AdmissionsController < BaseController
        before_action :set_admission, only: [ :show, :update, :destroy ]

        def index
          authorize Admission

          ActsAsTenant.without_tenant do
            scope = policy_scope(Admission).order(created_at: :desc)

            if params[:query].present?
              q = "%#{params[:query]}%"
              scope = scope.joins(:student).where(
                "admissions.admission_number ILIKE :q OR students.first_name ILIKE :q OR students.last_name ILIKE :q OR students.email ILIKE :q",
                q: q
              )
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            if params[:course_id].present?
              scope = scope.where(course_id: params[:course_id])
            end

            if params[:batch_id].present?
              scope = scope.where(batch_id: params[:batch_id])
            end

            if params[:student_id].present?
              scope = scope.where(student_id: params[:student_id])
            end

            if params[:counselor_id].present?
              scope = scope.where(counselor_id: params[:counselor_id])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            admissions = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: AdmissionBlueprint.render_as_json(admissions),
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
          authorize @admission
          render_success(data: AdmissionBlueprint.render_as_json(@admission))
        end

        def create
          attrs = admission_params
          attrs[:tenant_id] = Current.user&.tenant_id || Current.tenant&.id

          ActsAsTenant.without_tenant do
            @admission = Admission.new(attrs)
            authorize @admission
            @admission.save!
          end

          render_success(data: AdmissionBlueprint.render_as_json(@admission), status: :created)
        end

        def update
          authorize @admission

          attrs = admission_params
          attrs.delete(:tenant_id)
          attrs.delete(:admission_number)

          ActsAsTenant.without_tenant do
            @admission.update!(attrs)
          end

          render_success(data: AdmissionBlueprint.render_as_json(@admission))
        end

        def destroy
          authorize @admission

          ActsAsTenant.without_tenant do
            @admission.destroy!
          end

          render_success(data: { message: "Admission deleted successfully" })
        end

        private

        def set_admission
          ActsAsTenant.without_tenant do
            @admission = policy_scope(Admission).find(params[:id])
          end
        end

        def admission_params
          params.require(:admission).permit(
            :lead_id,
            :student_id,
            :course_id,
            :batch_id,
            :counselor_id,
            :admission_number,
            :admission_date,
            :status,
            :notes
          )
        end
      end
    end
  end
end
