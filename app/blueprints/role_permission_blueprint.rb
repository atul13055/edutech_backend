class RolePermissionBlueprint < Blueprinter::Base
  identifier :id

  fields :role_id, :permission_id, :created_at, :updated_at

  association :role, blueprint: RoleBlueprint
  association :permission, blueprint: PermissionBlueprint
end
