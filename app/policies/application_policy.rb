class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  def super_admin?
    user.present? && user.tenant_id.nil? && user.role&.key == "super_admin"
  end

  def authenticated?
    user.present?
  end

  def same_tenant?(other_record = record)
    return false unless user.present? && other_record.present?
    return false unless user.tenant_id.present?

    target_tenant_id = if other_record.respond_to?(:tenant_id)
                         other_record.tenant_id
    elsif other_record.is_a?(Tenant)
                         other_record.id
    end

    user.tenant_id == target_tenant_id
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    def super_admin?
      user.present? && user.tenant_id.nil? && user.role&.key == "super_admin"
    end
  end
end
