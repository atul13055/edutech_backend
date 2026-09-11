module Api
  module V1
    module Admin
      class CoursesController < BaseController
        before_action :set_course, only: [ :show, :update, :destroy ]

        def index
          authorize Course

          ActsAsTenant.without_tenant do
            scope = policy_scope(Course).order(created_at: :desc)

            if params[:query].present?
              q = "%#{params[:query]}%"
              scope = scope.where("name ILIKE :q OR code ILIKE :q OR description ILIKE :q", q: q)
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            if params[:is_global].present?
              is_global = ActiveModel::Type::Boolean.new.cast(params[:is_global])
              scope = is_global ? scope.where(tenant_id: nil) : scope.where.not(tenant_id: nil)
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            courses = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: CourseBlueprint.render_as_json(courses),
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
          authorize @course
          render_success(data: CourseBlueprint.render_as_json(@course))
        end

        def create
          attrs = course_params

          if Current.user&.tenant_id.present?
            # Normal tenant users create branch-scoped courses
            attrs[:tenant_id] = Current.user.tenant_id
          elsif Current.tenant.present?
            attrs[:tenant_id] = Current.tenant.id
          elsif attrs[:is_global] == true && Current.user&.role&.key == "super_admin"
            attrs[:tenant_id] = nil
          end

          attrs.delete(:is_global)

          ActsAsTenant.without_tenant do
            @course = Course.new(attrs)
            authorize @course
            @course.save!
          end

          render_success(data: CourseBlueprint.render_as_json(@course), status: :created)
        end

        def update
          authorize @course

          attrs = course_params
          attrs.delete(:tenant_id)
          attrs.delete(:is_global)

          ActsAsTenant.without_tenant do
            @course.update!(attrs)
          end

          render_success(data: CourseBlueprint.render_as_json(@course))
        end

        def destroy
          authorize @course
          ActsAsTenant.without_tenant do
            @course.destroy!
          end

          render_success(data: { message: "Course deleted successfully" })
        end

        private

        def set_course
          ActsAsTenant.without_tenant do
            @course = policy_scope(Course).find(params[:id])
          end
        end

        def course_params
          params.require(:course).permit(
            :name,
            :code,
            :description,
            :duration_months,
            :base_fee,
            :status,
            :is_global
          )
        end
      end
    end
  end
end
