module Crm
  class LeadConversionService
    Result = Struct.new(:success?, :admission, :student, :lead, :errors, keyword_init: true)

    def self.call(lead:, course_id:, batch_id: nil, counselor_id: nil, admission_date: nil, notes: nil)
      new(
        lead: lead,
        course_id: course_id,
        batch_id: batch_id,
        counselor_id: counselor_id,
        admission_date: admission_date,
        notes: notes
      ).call
    end

    def initialize(lead:, course_id:, batch_id: nil, counselor_id: nil, admission_date: nil, notes: nil)
      @lead = lead
      @course_id = course_id
      @batch_id = batch_id
      @counselor_id = counselor_id
      @admission_date = admission_date || Date.today
      @notes = notes
    end

    def call
      if @lead.status == "converted"
        return Result.new(
          success?: false,
          lead: @lead,
          errors: [ "Lead has already been converted to an admission" ]
        )
      end

      if @course_id.blank?
        return Result.new(
          success?: false,
          lead: @lead,
          errors: [ "Course is required for admission conversion" ]
        )
      end

      student = nil
      admission = nil

      ActiveRecord::Base.transaction do
        student = find_or_create_student!

        admission = Admission.create!(
          tenant: @lead.tenant,
          lead: @lead,
          student: student,
          course_id: @course_id,
          batch_id: @batch_id,
          counselor_id: @counselor_id || @lead.assigned_to_id,
          admission_date: @admission_date,
          status: "confirmed",
          notes: @notes || "Converted from Lead ##{@lead.id}"
        )

        @lead.update!(status: "converted")
      end

      Result.new(
        success?: true,
        admission: admission,
        student: student,
        lead: @lead,
        errors: []
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.new(
        success?: false,
        lead: @lead,
        student: student,
        admission: admission,
        errors: e.record.errors.full_messages
      )
    rescue StandardError => e
      Result.new(
        success?: false,
        lead: @lead,
        errors: [ e.message ]
      )
    end

    private

    def find_or_create_student!
      tenant_students = Student.where(tenant_id: @lead.tenant_id)

      if @lead.email.present?
        existing = tenant_students.find_by(email: @lead.email)
        return existing if existing.present?
      end

      if @lead.phone.present?
        existing = tenant_students.find_by(phone: @lead.phone)
        return existing if existing.present?
      end

      names = @lead.name.to_s.split(" ", 2)
      first_name = names[0].presence || "Lead"
      last_name = names[1].presence

      roll_prefix = "STU-#{Time.current.strftime('%Y%m')}"
      random_roll = "#{roll_prefix}-#{SecureRandom.alphanumeric(4).upcase}"

      Student.create!(
        tenant: @lead.tenant,
        first_name: first_name,
        last_name: last_name,
        email: @lead.email,
        phone: @lead.phone,
        roll_number: random_roll,
        status: "active"
      )
    end
  end
end
