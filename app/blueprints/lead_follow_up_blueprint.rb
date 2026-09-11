class LeadFollowUpBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :lead_id,
         :user_id,
         :follow_up_at,
         :completed_at,
         :status,
         :notes,
         :outcome,
         :created_at,
         :updated_at

  field :user_name do |follow_up|
    follow_up.user ? "#{follow_up.user.first_name} #{follow_up.user.last_name}".strip : nil
  end
end
