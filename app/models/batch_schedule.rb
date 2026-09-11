class BatchSchedule < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :batch

  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :start_time, presence: true, format: { with: /\A([01]\d|2[0-3]):[0-5]\d\z/, message: "must be in HH:MM 24-hour format" }
  validates :end_time, presence: true, format: { with: /\A([01]\d|2[0-3]):[0-5]\d\z/, message: "must be in HH:MM 24-hour format" }
  validates :room_name, length: { maximum: 255 }, allow_blank: true

  validate :validate_end_time_after_start_time

  private

  def validate_end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
