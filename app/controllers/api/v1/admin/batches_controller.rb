module Api
  module V1
    module Admin
      class BatchesController < BaseController
        before_action :set_batch, only: [ :show, :update, :destroy ]

        def index
          authorize Batch

          ActsAsTenant.without_tenant do
            scope = policy_scope(Batch).order(created_at: :desc)

            if params[:query].present?
              q = "%#{params[:query]}%"
              scope = scope.where("name ILIKE :q OR code ILIKE :q OR description ILIKE :q", q: q)
            end

            if params[:course_id].present?
              scope = scope.where(course_id: params[:course_id])
            end

            if params[:status].present?
              scope = scope.where(status: params[:status])
            end

            if params[:trainer_id].present?
              scope = scope.where(trainer_id: params[:trainer_id])
            end

            page = [ (params[:page] || 1).to_i, 1 ].max
            per_page = [ (params[:per_page] || 20).to_i, 100 ].min
            total_count = scope.count

            batches = scope.offset((page - 1) * per_page).limit(per_page)

            render_success(
              data: BatchBlueprint.render_as_json(batches),
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
          authorize @batch
          render_success(data: BatchBlueprint.render_as_json(@batch))
        end

        def create
          attrs = batch_params
          attrs[:tenant_id] = Current.user&.tenant_id || Current.tenant&.id

          ActsAsTenant.without_tenant do
            @batch = Batch.new(attrs)
            authorize @batch
            @batch.save!
          end

          render_success(data: BatchBlueprint.render_as_json(@batch), status: :created)
        end

        def update
          authorize @batch

          attrs = batch_params
          attrs.delete(:tenant_id)

          ActsAsTenant.without_tenant do
            @batch.update!(attrs)
          end

          render_success(data: BatchBlueprint.render_as_json(@batch))
        end

        def destroy
          authorize @batch
          ActsAsTenant.without_tenant do
            @batch.destroy!
          end

          render_success(data: { message: "Batch deleted successfully" })
        end

        private

        def set_batch
          ActsAsTenant.without_tenant do
            @batch = policy_scope(Batch).find(params[:id])
          end
        end

        def batch_params
          params.require(:batch).permit(
            :course_id,
            :trainer_id,
            :name,
            :code,
            :description,
            :capacity,
            :start_date,
            :end_date,
            :status
          )
        end
      end
    end
  end
end
