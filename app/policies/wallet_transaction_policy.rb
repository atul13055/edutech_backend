class WalletTransactionPolicy < ApplicationPolicy
  def index?
    super_admin? || can_manage_wallet?
  end

  def show?
    super_admin? || (same_tenant? && can_manage_wallet?)
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  private

  def can_manage_wallet?
    authenticated? && tenant_admin?
  end

  def tenant_admin?
    user.present? && %w[tenant_admin branch_admin].include?(user.role&.key)
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

    private

    def super_admin?
      user.present? && user.tenant_id.nil? && user.role&.key == "super_admin"
    end
  end
end
