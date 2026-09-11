class BatchBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :course_id,
         :trainer_id,
         :name,
         :code,
         :description,
         :capacity,
         :start_date,
         :end_date,
         :status,
         :created_at,
         :updated_at

  association :course, blueprint: CourseBlueprint
  association :batch_schedules, blueprint: BatchScheduleBlueprint

  field :trainer_name do |batch|
    batch.trainer ? "#{batch.trainer.first_name} #{batch.trainer.last_name}".strip : nil
  end
end
