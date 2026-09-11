module Api
  module V1
    module Admin
      class LeadFollowUpsController < BaseController
        before_action :set_lead
        before_action :set_follow_up, only: [ :show, :update, :destroy ]

        def index
          authorize LeadFollowUp

          ActsAsTenant.without_tenant do
            follow_ups = policy_scope(@lead.follow_ups).order(follow_up_at: :desc)
            render_success(data: LeadFollowUpBlueprint.render_as_json(follow_ups))
          end
        end

        def show
          authorize @follow_up
          render_success(data: LeadFollowUpBlueprint.render_as_json(@follow_up))
        end

        def create
          attrs = follow_up_params
          attrs[:tenant_id] = @lead.tenant_id
          attrs[:user_id] ||= Current.user&.id

          ActsAsTenant.without_tenant do
            @follow_up = @lead.follow_ups.build(attrs)
            authorize @follow_up
            @follow_up.save!
          end

          render_success(data: LeadFollowUpBlueprint.render_as_json(@follow_up), status: :created)
        end

        def update
          authorize @follow_up

          attrs = follow_up_params
          attrs.delete(:tenant_id)
          attrs.delete(:lead_id)

          ActsAsTenant.without_tenant do
            @follow_up.update!(attrs)
          end

          render_success(data: LeadFollowUpBlueprint.render_as_json(@follow_up))
        end

        def destroy
          authorize @follow_up

          ActsAsTenant.without_tenant do
            @follow_up.destroy!
          end

          render_success(data: { message: "Follow-up deleted successfully" })
        end

        private

        def set_lead
          ActsAsTenant.without_tenant do
            @lead = policy_scope(Lead).find(params[:lead_id])
          end
        end

        def set_follow_up
          ActsAsTenant.without_tenant do
            @follow_up = policy_scope(@lead.follow_ups).find(params[:id])
          end
        end

        def follow_up_params
          params.require(:follow_up).permit(
            :user_id,
            :follow_up_at,
            :completed_at,
            :status,
            :notes,
            :outcome
          )
        end
      end
    end
  end
end
