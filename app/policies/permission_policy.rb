class PermissionPolicy < ApplicationPolicy
  def index?
    super_admin? || authenticated?
  end

  def show?
    super_admin? || authenticated?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if authenticated?
        scope.all
      else
        scope.none
      end
    end
  end
end
