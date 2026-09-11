module ApiResponseHandler
  extend ActiveSupport::Concern

  private

  def render_success(data: nil, meta: nil, status: :ok)
    payload = { success: true }
    payload[:data] = data unless data.nil?
    payload[:meta] = meta unless meta.nil?

    render json: payload, status: status
  end

  def render_error(errors:, status: :unprocessable_entity)
    error_list = if errors.is_a?(Array)
                   errors
    elsif errors.respond_to?(:to_a)
                   errors.to_a
    else
                   [ errors.to_s ]
    end

    render json: { success: false, errors: error_list }, status: status
  end
end
