class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :first_name, :last_name, :email, :status, :tenant_id, :role_id, :created_at, :updated_at

  view :with_associations do
    association :tenant, blueprint: TenantBlueprint
    association :role, blueprint: RoleBlueprint
  end
end
