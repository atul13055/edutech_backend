class RolePolicy < ApplicationPolicy
  def index?
    super_admin? || authenticated?
  end

  def show?
    super_admin? || record.tenant_id.nil? || same_tenant?
  end

  def create?
    return true if super_admin? && record.key != "super_admin"
    return false unless authenticated? && same_tenant?

    record.key != "super_admin"
  end

  def update?
    return false if record.tenant_id.nil?

    if super_admin?
      true
    else
      same_tenant? && record.key != "super_admin"
    end
  end

  def destroy?
    return false if record.tenant_id.nil?

    if super_admin?
      true
    else
      same_tenant?
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      elsif user.present? && user.tenant_id.present?
        scope.where(tenant_id: [ nil, user.tenant_id ])
      else
        scope.none
      end
    end
  end
end
