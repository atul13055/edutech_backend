module Api
  module V1
    class WebhooksController < ApplicationController
      skip_before_action :authenticate_user!, raise: false
      skip_after_action :verify_authorized, raise: false

      def receive
        provider_name = params[:provider_name] || request.headers["X-Provider-Name"] || "generic"
        provider_event_id = params[:provider_event_id] || request.headers["X-Provider-Event-ID"] || SecureRandom.hex(12)
        event_type = params[:event_type] || "payment.notification"
        signature_verified = request.headers["X-Webhook-Signature-Verified"] == "true" || params[:signature_verified] == true

        unless signature_verified
          render_error(
            errors: [ "Unverified webhook event signature" ],
            status: :bad_request
          )
          return
        end

        event = Payments::WebhookEventProcessor.new({
          provider_name: provider_name,
          provider_event_id: provider_event_id,
          event_type: event_type,
          payload: params[:payload] || params.except(:controller, :action, :provider_name, :provider_event_id, :event_type, :signature_verified),
          signature_verified: signature_verified,
          tenant_id: request.headers["X-Tenant-ID"]
        }).call

        render_success(
          data: WebhookEventBlueprint.render_as_json(event),
          status: :ok
        )
      rescue Payments::WebhookEventProcessor::SignatureVerificationError => e
        render_error(errors: [ e.message ], status: :bad_request)
      rescue Payments::WebhookEventProcessor::MismatchError => e
        render_error(errors: [ e.message ], status: :unprocessable_entity)
      rescue ActiveRecord::RecordNotFound => e
        render_error(errors: [ e.message ], status: :not_found)
      rescue StandardError => e
        render_error(errors: [ e.message ], status: :unprocessable_entity)
      end
    end
  end
end
