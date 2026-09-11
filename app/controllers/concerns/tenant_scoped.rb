module TenantScoped
  extend ActiveSupport::Concern

  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  included do
    around_action :set_tenant_context
  end

  private

  def set_tenant_context
    resolve_tenant
    if Current.tenant
      ActsAsTenant.with_tenant(Current.tenant) { yield }
    else
      yield
    end
  ensure
    Current.reset
  end

  def resolve_tenant
    header_tenant_id = request.headers["X-Tenant-ID"]

    if Current.user.present?
      if Current.user.tenant_id.present?
        # Normal Tenant User
        if header_tenant_id.present? && header_tenant_id != Current.user.tenant_id
          raise Pundit::NotAuthorizedError, "Access denied: Cannot switch tenant context"
        end

        Current.tenant = Current.user.tenant
      else
        # Super Admin User (tenant_id is nil)
        if header_tenant_id.present?
          unless header_tenant_id.match?(UUID_REGEX)
            raise ActionController::BadRequest, "Invalid X-Tenant-ID header format"
          end

          target_tenant = Tenant.find_by(id: header_tenant_id)
          raise ActiveRecord::RecordNotFound, "Requested tenant not found" unless target_tenant

          Current.tenant = target_tenant
        else
          Current.tenant = nil
        end
      end
    elsif header_tenant_id.present?
      unless header_tenant_id.match?(UUID_REGEX)
        raise ActionController::BadRequest, "Invalid X-Tenant-ID header format"
      end

      target_tenant = Tenant.find_by(id: header_tenant_id)
      raise ActiveRecord::RecordNotFound, "Requested tenant not found" unless target_tenant

      Current.tenant = target_tenant
    else
      Current.tenant = nil
    end
  end
end
