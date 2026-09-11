class FeePaymentPolicy < ApplicationPolicy
  def index?
    super_admin? || can_access_fee_payments?
  end

  def show?
    super_admin? || (same_tenant? && can_access_fee_payments?)
  end

  def summary?
    index?
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && can_collect_fee_payments?

    record.tenant_id.nil? || same_tenant?
  end

  def update?
    false
  end

  def destroy?
    false
  end

  private

  def can_access_fee_payments?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.collect") ||
      user.permissions.exists?(key: "fees.manage") ||
      user.permissions.exists?(key: "fees.read") ||
      user.permissions.exists?(key: "fees.view")
    )
  end

  def can_collect_fee_payments?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.collect") ||
      user.permissions.exists?(key: "fees.manage")
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
