class UserPolicy < ApplicationPolicy
  def index?
    super_admin? || authenticated?
  end

  def show?
    super_admin? || same_tenant?
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && same_tenant?

    # Prevent normal tenant users from assigning super_admin role
    target_role_key = record.role&.key || Role.find_by(id: record.role_id)&.key
    target_role_key != "super_admin"
  end

  def update?
    return true if super_admin?
    return false unless authenticated? && same_tenant?

    # Prevent self-promotion to super_admin or switching user's tenant
    if record.role_id_changed?
      target_role_key = Role.find_by(id: record.role_id)&.key || record.role&.key
      return false if target_role_key == "super_admin"
    end
    return false if record.tenant_id_changed? && record.tenant_id != user.tenant_id

    true
  end

  def destroy?
    return false if record.id == user&.id # Prevent self-deletion

    if super_admin?
      true
    else
      same_tenant? && record.role&.key != "super_admin"
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      elsif user.present? && user.tenant_id.present?
        scope.where(tenant_id: user.tenant_id)
      else
        scope.none
      end
    end
  end
end
