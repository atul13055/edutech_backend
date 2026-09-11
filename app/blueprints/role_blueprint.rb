class RoleBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :key, :description, :tenant_id, :created_at, :updated_at

  field :is_system do |role, _options|
    role.tenant_id.nil?
  end

  view :with_permissions do
    association :permissions, blueprint: PermissionBlueprint
  end
end
