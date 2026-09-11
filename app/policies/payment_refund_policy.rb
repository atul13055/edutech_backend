class PaymentRefundPolicy < ApplicationPolicy
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

  def index?
    super_admin? || can_access_refunds?
  end

  def show?
    super_admin? || (same_tenant? && can_access_refunds?)
  end

  def create?
    return true if super_admin?
    return false unless authenticated? && can_create_refunds?

    record.nil? || record.is_a?(Class) || record.tenant_id.nil? || same_tenant?
  end

  def approve?
    return true if super_admin?
    return false unless authenticated? && can_manage_refunds?

    same_tenant?
  end

  def process_refund?
    return true if super_admin?
    return false unless authenticated? && can_manage_refunds?

    same_tenant?
  end

  def update?
    false
  end

  def destroy?
    false
  end

  private

  def can_access_refunds?
    authenticated? && (
      %w[tenant_admin branch_admin receptionist counselor].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.collect") ||
      user.permissions.exists?(key: "fees.manage") ||
      user.permissions.exists?(key: "fees.read") ||
      user.permissions.exists?(key: "fees.view") ||
      user.permissions.exists?(key: "fees.refund")
    )
  end

  def can_create_refunds?
    authenticated? && (
      %w[tenant_admin branch_admin].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.manage") ||
      user.permissions.exists?(key: "fees.refund")
    )
  end

  def can_manage_refunds?
    authenticated? && (
      %w[tenant_admin branch_admin].include?(user.role&.key) ||
      user.permissions.exists?(key: "fees.manage")
    )
  end

  def same_tenant?
    return true if super_admin? && Current.tenant.nil?
    user.present? && record.present? && record.respond_to?(:tenant_id) && record.tenant_id == user.tenant_id
  end

  def authenticated?
    user.present?
  end
end
