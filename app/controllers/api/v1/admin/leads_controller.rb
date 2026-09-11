module Api
  module V1
    module Admin
      class LeadsController < BaseController
        before_action :set_lead, only: [ :show, :update, :destroy, :convert ]

        def index
          authorize Lead

          ActsAsTenant.without_tenant do
            scope = policy_scope(Lead).order(created_at: :desc)

            if params[:query].present?
              q = "%#{params[:query]}%"
              scope = scope.where("name ILIKE :q OR email ILIKE :q OR phone ILIKE :q", q: q)
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            if params[:assigned_to_id].present?
              scope = scope.where(assigned_to_id: params[:assigned_to_id])
            end

            if params[:course_id].present?
              scope = scope.where(interested_course_id: params[:course_id])
            end

            if params[:batch_id].present?
              scope = scope.where(interested_batch_id: params[:batch_id])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            leads = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: LeadBlueprint.render_as_json(leads),
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
          authorize @lead
          render_success(data: LeadBlueprint.render_as_json(@lead))
        end

        def create
          attrs = lead_params
          attrs[:tenant_id] = Current.user&.tenant_id || Current.tenant&.id

          ActsAsTenant.without_tenant do
            @lead = Lead.new(attrs)
            authorize @lead
            @lead.save!
          end

          render_success(data: LeadBlueprint.render_as_json(@lead), status: :created)
        end

        def update
          authorize @lead

          attrs = lead_params
          attrs.delete(:tenant_id)

          ActsAsTenant.without_tenant do
            @lead.update!(attrs)
          end

          render_success(data: LeadBlueprint.render_as_json(@lead))
        end

        def destroy
          authorize @lead

          ActsAsTenant.without_tenant do
            @lead.destroy!
          end

          render_success(data: { message: "Lead deleted successfully" })
        end

        def convert
          authorize @lead, :convert?

          course_id = params[:course_id] || @lead.interested_course_id
          batch_id = params[:batch_id] || @lead.interested_batch_id
          counselor_id = params[:counselor_id] || Current.user&.id
          notes = params[:notes]

          result = ActsAsTenant.without_tenant do
            Crm::LeadConversionService.call(
              lead: @lead,
              course_id: course_id,
              batch_id: batch_id,
              counselor_id: counselor_id,
              admission_date: params[:admission_date],
              notes: notes
            )
          end

          if result.success?
            render_success(
              data: {
                admission: AdmissionBlueprint.render_as_json(result.admission),
                student: StudentBlueprint.render_as_json(result.student),
                lead: LeadBlueprint.render_as_json(result.lead)
              },
              status: :created
            )
          else
            render_error(
              message: "Lead conversion failed",
              status: :unprocessable_entity,
              errors: result.errors
            )
          end
        end

        private

        def set_lead
          ActsAsTenant.without_tenant do
            @lead = policy_scope(Lead).find(params[:id])
          end
        end

        def lead_params
          params.require(:lead).permit(
            :name,
            :email,
            :phone,
            :source,
            :status,
            :notes,
            :next_follow_up_at,
            :assigned_to_id,
            :interested_course_id,
            :interested_batch_id
          )
        end
      end
    end
  end
end
