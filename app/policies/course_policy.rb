class CoursePolicy < ApplicationPolicy
  def index?
    super_admin? || can_manage_courses?
  end

  def show?
    super_admin? || (can_manage_courses? && (record.tenant_id.nil? || same_tenant?))
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && can_manage_courses?

    # Normal tenant users can only create custom courses belonging to their own tenant
    record.tenant_id.present? && same_tenant?
  end

  def update?
    return true if super_admin?
    return false unless authenticated? && can_manage_courses?

    # Global courses (tenant_id == nil) can only be updated by Super Admin
    return false if record.tenant_id.nil?

    return false if record.tenant_id_changed? && record.tenant_id != user.tenant_id

    same_tenant?
  end

  def destroy?
    return true if super_admin?
    return false unless authenticated? && can_manage_courses?

    # Global courses (tenant_id == nil) can only be deleted by Super Admin
    return false if record.tenant_id.nil?

    same_tenant?
  end

  private

  def can_manage_courses?
    authenticated? && (
      %w[tenant_admin branch_admin trainer counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "courses.manage")
    )
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        if Current.tenant.present?
          scope.where(tenant_id: [ Current.tenant.id, nil ])
        else
          scope.all
        end
      elsif user.present? && user.tenant_id.present?
        scope.where(tenant_id: [ user.tenant_id, nil ])
      else
        scope.none
      end
    end
  end
end
