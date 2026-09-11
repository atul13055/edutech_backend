class LeadFollowUpPolicy < ApplicationPolicy
  def index?
    super_admin? || can_access_leads?
  end

  def show?
    super_admin? || (same_tenant? && can_access_leads?)
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && can_access_leads?

    record.tenant_id.nil? || same_tenant?
  end

  def update?
    return true if super_admin?
    return false unless authenticated? && same_tenant? && can_access_leads?

    return false if record.tenant_id_changed? && record.tenant_id != user.tenant_id

    true
  end

  def destroy?
    super_admin? || (same_tenant? && can_access_leads?)
  end

  private

  def can_access_leads?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "leads.manage") ||
      user.permissions.exists?(key: "leads.read")
    )
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        if Current.tenant.present?
          scope.where(tenant_id: Current.tenant.id)
        else
          scope.all
        end
      elsif user.present? && user.tenant_id.present?
        scope.where(tenant_id: user.tenant_id)
      else
        scope.none
      end
    end
  end
end
