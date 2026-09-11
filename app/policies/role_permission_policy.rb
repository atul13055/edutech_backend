class RolePermissionPolicy < ApplicationPolicy
  def index?
    super_admin? || (authenticated? && role_accessible?)
  end

  def show?
    super_admin? || (authenticated? && role_accessible?)
  end

  def create?
    return true if super_admin? && !record.role&.tenant_id.nil?
    return false unless authenticated? && same_tenant?(record.role)

    !record.role&.tenant_id.nil?
  end

  def update?
    return true if super_admin? && !record.role&.tenant_id.nil?
    return false unless authenticated? && same_tenant?(record.role)

    !record.role&.tenant_id.nil?
  end

  def destroy?
    return true if super_admin? && !record.role&.tenant_id.nil?
    return false unless authenticated? && same_tenant?(record.role)

    !record.role&.tenant_id.nil?
  end

  private

  def role_accessible?
    return false unless record&.role

    record.role.tenant_id.nil? || same_tenant?(record.role)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      elsif user.present? && user.tenant_id.present?
        scope.joins(:role).where(roles: { tenant_id: [ nil, user.tenant_id ] })
      else
        scope.none
      end
    end
  end
end
