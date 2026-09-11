class TenantBlueprint < Blueprinter::Base
  identifier :id

  fields :name,
         :subdomain,
         :code,
         :status,
         :address,
         :contact_email,
         :contact_phone,
         :time_zone,
         :created_at,
         :updated_at
end
