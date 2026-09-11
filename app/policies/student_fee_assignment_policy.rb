class StudentFeeAssignmentPolicy < ApplicationPolicy
  def index?
    super_admin? || can_access_fee_assignments?
  end

  def show?
    super_admin? || (same_tenant? && can_access_fee_assignments?)
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && can_manage_fee_assignments?

    record.tenant_id.nil? || same_tenant?
  end

  def update?
    return true if super_admin?
    return false unless authenticated? && same_tenant? && can_manage_fee_assignments?

    return false if record.tenant_id_changed? && record.tenant_id != user.tenant_id

    true
  end

  def destroy?
    super_admin? || (same_tenant? && can_manage_fee_assignments?)
  end

  private

  def can_access_fee_assignments?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.manage") ||
      user.permissions.exists?(key: "fees.read") ||
      user.permissions.exists?(key: "fee_plans.manage") ||
      user.permissions.exists?(key: "fee_plans.read")
    )
  end

  def can_manage_fee_assignments?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.manage") ||
      user.permissions.exists?(key: "fee_plans.manage")
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
