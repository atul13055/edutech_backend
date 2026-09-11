module Api
  module V1
    class TenantsController < BaseController
      before_action :set_tenant, only: [ :show, :update, :destroy ]

      def index
        authorize Tenant
        tenants = policy_scope(Tenant)

        if params[:status].present? && %w[active suspended inactive].include?(params[:status])
          tenants = tenants.where(status: params[:status])
        end

        if params[:search].present?
          term = "%#{Tenant.sanitize_sql_like(params[:search].to_s.strip)}%"
          tenants = tenants.where("name ILIKE :term OR subdomain ILIKE :term OR code ILIKE :term", term: term)
        end

        page = [ params[:page].to_i, 1 ].max
        per_page = params[:per_page].present? ? [ [ params[:per_page].to_i, 1 ].max, 100 ].min : 25
        total_count = tenants.count
        total_pages = (total_count.to_f / per_page).ceil

        paginated_tenants = tenants.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

        render_success(
          data: TenantBlueprint.render_as_hash(paginated_tenants),
          meta: {
            page: page,
            per_page: per_page,
            total_pages: total_pages,
            total_count: total_count
          }
        )
      end

      def show
        authorize @tenant
        render_success(data: TenantBlueprint.render_as_hash(@tenant))
      end

      def create
        @tenant = Tenant.new(tenant_params)
        authorize @tenant
        @tenant.save!
        render_success(data: TenantBlueprint.render_as_hash(@tenant), status: :created)
      end

      def update
        @tenant.assign_attributes(tenant_params)
        authorize @tenant
        @tenant.save!
        TenantManagement::LifecycleService.handle_status_change(@tenant)
        render_success(data: TenantBlueprint.render_as_hash(@tenant))
      end

      def destroy
        authorize @tenant
        @tenant.destroy!
        render_success(data: { message: "Tenant deleted successfully" })
      end

      private

      def set_tenant
        @tenant = Tenant.find(params[:id])
      end

      def tenant_params
        allowed = [ :name, :address, :contact_email, :contact_phone, :time_zone ]
        allowed += [ :subdomain, :code, :status ] if current_user&.role&.key == "super_admin"
        params.require(:tenant).permit(allowed)
      end
    end
  end
end
