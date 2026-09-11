class TenantPolicy < ApplicationPolicy
  def index?
    super_admin?
  end

  def show?
    super_admin? || same_tenant?
  end

  def create?
    super_admin?
  end

  def update?
    return true if super_admin?
    return false unless authenticated? && same_tenant? && tenant_admin?

    # Branch Admin cannot alter core tenant identity or lifecycle status
    if record.subdomain_changed? || record.code_changed? || record.status_changed?
      return false
    end

    true
  end

  def destroy?
    super_admin?
  end

  private

  def tenant_admin?
    user.present? && %w[tenant_admin branch_admin].include?(user.role&.key)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      elsif user.present? && user.tenant_id.present?
        scope.where(id: user.tenant_id)
      else
        scope.none
      end
    end
  end
end
