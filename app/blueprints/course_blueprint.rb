class CourseBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :name,
         :code,
         :description,
         :duration_months,
         :base_fee,
         :status,
         :created_at,
         :updated_at

  field :is_global do |course|
    course.tenant_id.nil?
  end
end
