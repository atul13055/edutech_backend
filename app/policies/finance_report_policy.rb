class FinanceReportPolicy < ApplicationPolicy
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

  def collection_summary?
    can_view_reports?
  end

  def payment_methods?
    can_view_reports?
  end

  def outstanding_fees?
    can_view_reports?
  end

  def student_ledger?
    can_view_reports?
  end

  def refunds?
    can_view_reports?
  end

  def payment_intents?
    can_view_reports?
  end

  def daily_collection?
    can_view_reports?
  end

  def settlement_summary?
    can_view_reports?
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

  def can_view_reports?
    return true if super_admin?
    return false unless authenticated?

    %w[tenant_admin branch_admin accountant].include?(user.role&.key) ||
      user.permissions.exists?(key: "finance.view_reports") ||
      user.permissions.exists?(key: "fees.view") ||
      user.permissions.exists?(key: "fees.read") ||
      user.permissions.exists?(key: "fees.manage")
  end

  def authenticated?
    user.present?
  end
end
