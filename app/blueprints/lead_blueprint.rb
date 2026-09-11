class LeadBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :assigned_to_id,
         :interested_course_id,
         :interested_batch_id,
         :name,
         :email,
         :phone,
         :source,
         :status,
         :notes,
         :next_follow_up_at,
         :created_at,
         :updated_at

  association :interested_course, blueprint: CourseBlueprint
  association :interested_batch, blueprint: BatchBlueprint
  association :follow_ups, blueprint: LeadFollowUpBlueprint

  field :assigned_to_name do |lead|
    lead.assigned_to ? "#{lead.assigned_to.first_name} #{lead.assigned_to.last_name}".strip : nil
  end
end
