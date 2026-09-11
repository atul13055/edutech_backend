module Api
  module V1
    module Admin
      class BatchSchedulesController < BaseController
        before_action :set_batch
        before_action :set_schedule, only: [ :show, :update, :destroy ]

        def index
          authorize BatchSchedule

          ActsAsTenant.without_tenant do
            schedules = policy_scope(@batch.batch_schedules).order(:weekday, :start_time)
            render_success(data: BatchScheduleBlueprint.render_as_json(schedules))
          end
        end

        def show
          authorize @schedule
          render_success(data: BatchScheduleBlueprint.render_as_json(@schedule))
        end

        def create
          attrs = schedule_params
          attrs[:tenant_id] = @batch.tenant_id

          ActsAsTenant.without_tenant do
            @schedule = @batch.batch_schedules.build(attrs)
            authorize @schedule
            @schedule.save!
          end

          render_success(data: BatchScheduleBlueprint.render_as_json(@schedule), status: :created)
        end

        def update
          authorize @schedule

          attrs = schedule_params
          attrs.delete(:tenant_id)
          attrs.delete(:batch_id)

          ActsAsTenant.without_tenant do
            @schedule.update!(attrs)
          end

          render_success(data: BatchScheduleBlueprint.render_as_json(@schedule))
        end

        def destroy
          authorize @schedule
          ActsAsTenant.without_tenant do
            @schedule.destroy!
          end

          render_success(data: { message: "Batch schedule deleted successfully" })
        end

        private

        def set_batch
          ActsAsTenant.without_tenant do
            @batch = policy_scope(Batch).find(params[:batch_id])
          end
        end

        def set_schedule
          ActsAsTenant.without_tenant do
            @schedule = policy_scope(@batch.batch_schedules).find(params[:id])
          end
        end

        def schedule_params
          params.require(:batch_schedule).permit(
            :weekday,
            :start_time,
            :end_time,
            :room_name
          )
        end
      end
    end
  end
end
