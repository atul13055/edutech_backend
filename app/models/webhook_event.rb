class WebhookEvent < ApplicationRecord
  acts_as_tenant :tenant, optional: true

  ALLOWED_PROCESSING_STATUSES = %w[received processed failed ignored].freeze

  belongs_to :tenant, optional: true
  belongs_to :payment_intent, optional: true

  before_validation :normalize_attributes

  validates :provider_name, presence: true
  validates :provider_event_id, presence: true, uniqueness: { scope: :provider_name }
  validates :event_type, presence: true
  validates :payload_hash, presence: true
  validates :processing_status, presence: true, inclusion: { in: ALLOWED_PROCESSING_STATUSES }

  private

  def normalize_attributes
    self.provider_name = provider_name.to_s.strip.downcase if provider_name.present?
    self.event_type = event_type.to_s.strip if event_type.present?
    self.processing_status = "received" if processing_status.blank?
  end
end
