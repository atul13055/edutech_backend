# app/services/tenant_management/lifecycle_service.rb
module TenantManagement
  class LifecycleService
    def self.handle_status_change(tenant)
      new(tenant).handle_status_change
    end

    def initialize(tenant)
      @tenant = tenant
    end

    def handle_status_change
      return unless @tenant.saved_change_to_status?

      if %w[suspended inactive].include?(@tenant.status)
        revoke_all_tenant_user_sessions
      end
    end

    def suspend!
      @tenant.update!(status: "suspended")
      revoke_all_tenant_user_sessions
    end

    def activate!
      @tenant.update!(status: "active")
    end

    def deactivate!
      @tenant.update!(status: "inactive")
      revoke_all_tenant_user_sessions
    end

    private

    def revoke_all_tenant_user_sessions
      user_ids = User.where(tenant_id: @tenant.id).pluck(:id)
      return if user_ids.empty?

      RefreshToken.where(user_id: user_ids, revoked_at: nil).update_all(revoked_at: Time.current)
    end
  end
end
