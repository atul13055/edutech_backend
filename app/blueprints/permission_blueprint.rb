class PermissionBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :key, :module_name, :description, :created_at, :updated_at
end
