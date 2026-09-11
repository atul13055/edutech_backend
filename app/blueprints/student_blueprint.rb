class StudentBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :user_id,
         :roll_number,
         :first_name,
         :last_name,
         :email,
         :phone,
         :date_of_birth,
         :gender,
         :address,
         :guardian_name,
         :guardian_phone,
         :status,
         :created_at,
         :updated_at

  field :full_name do |student|
    [ student.first_name, student.last_name ].compact.join(" ")
  end

  view :with_user do
    association :user, blueprint: UserBlueprint
  end
end
