module Api
  module V1
    module Admin
      class StudentsController < BaseController
        before_action :set_student, only: [ :show, :update, :destroy ]

        def index
          authorize Student

          scope = policy_scope(Student).order(created_at: :desc)

          if params[:query].present?
            q = "%#{params[:query]}%"
            scope = scope.where("first_name ILIKE :q OR last_name ILIKE :q OR roll_number ILIKE :q OR email ILIKE :q", q: q)
          end

          if params[:status].present?
            scope = scope.where(status: params[:status])
          end

          page = [ (params[:page] || 1).to_i, 1 ].max
          per_page = [ (params[:per_page] || 20).to_i, 100 ].min
          total_count = scope.count

          students = scope.offset((page - 1) * per_page).limit(per_page)

          render_success(
            data: StudentBlueprint.render_as_json(students),
            meta: {
              current_page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          )
        end

        def show
          authorize @student
          render_success(data: StudentBlueprint.render_as_json(@student))
        end

        def create
          attrs = student_params

          if Current.user&.tenant_id.present?
            attrs[:tenant_id] = Current.user.tenant_id
          elsif Current.tenant.present?
            attrs[:tenant_id] = Current.tenant.id
          end

          @student = Student.new(attrs)
          authorize @student
          @student.save!

          render_success(data: StudentBlueprint.render_as_json(@student), status: :created)
        end

        def update
          authorize @student

          attrs = student_params
          attrs.delete(:tenant_id)

          @student.update!(attrs)

          render_success(data: StudentBlueprint.render_as_json(@student))
        end

        def destroy
          authorize @student
          @student.destroy!

          render_success(data: { message: "Student deleted successfully" })
        end

        private

        def set_student
          @student = policy_scope(Student).find(params[:id])
        end

        def student_params
          params.require(:student).permit(
            :roll_number,
            :first_name,
            :last_name,
            :email,
            :phone,
            :date_of_birth,
            :gender,
            :address,
            :guardian_name,
            :guardian_phone,
            :status,
            :user_id
          )
        end
      end
    end
  end
end
