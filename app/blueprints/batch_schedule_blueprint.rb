class BatchScheduleBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :batch_id,
         :weekday,
         :start_time,
         :end_time,
         :room_name,
         :created_at,
         :updated_at

  field :weekday_name do |schedule|
    Date::DAYNAMES[schedule.weekday] rescue nil
  end
end
