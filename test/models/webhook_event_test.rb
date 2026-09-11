require "test_helper"

class WebhookEventTest < ActiveSupport::TestCase
  test "enforces uniqueness on provider_name + provider_event_id" do
    WebhookEvent.create!(
      provider_name: "razorpay",
      provider_event_id: "evt_1001",
      event_type: "payment.captured",
      payload_hash: "hash123",
      signature_verified: true
    )

    duplicate = WebhookEvent.new(
      provider_name: "razorpay",
      provider_event_id: "evt_1001",
      event_type: "payment.captured",
      payload_hash: "hash123",
      signature_verified: true
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider_event_id], "has already been taken"
  end
end
