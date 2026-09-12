module Api
  module V1
    module Admin
      class FinanceReportsController < BaseController
        before_action :authorize_finance_reports

        rescue_from Finance::ReportsService::InvalidDateRangeError do |e|
          render_error(errors: [ e.message ], status: :unprocessable_entity)
        end

        rescue_from Finance::ReportsService::MissingParameterError do |e|
          render_error(errors: [ e.message ], status: :bad_request)
        end

        # GET /api/v1/admin/finance/reports/collection_summary
        def collection_summary
          report = service.collection_summary(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/payment_methods
        def payment_methods
          report = service.payment_methods_breakdown(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/outstanding_fees
        def outstanding_fees
          report = service.outstanding_fees(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/student_ledger
        def student_ledger
          report = service.student_ledger(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/refunds
        def refunds
          report = service.refunds_summary(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/payment_intents
        def payment_intents
          report = service.payment_intents_summary(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/daily_collection
        def daily_collection
          report = service.daily_collection(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        # GET /api/v1/admin/finance/reports/settlement_summary
        def settlement_summary
          report = service.settlement_summary(report_params)
          render_success(data: FinanceReportBlueprint.render_as_hash(report))
        end

        private

        def service
          @service ||= Finance::ReportsService.new(tenant: current_tenant, user: current_user)
        end

        def authorize_finance_reports
          action_symbol = "#{action_name}?".to_sym
          authorize :finance_report, action_symbol
        end

        def report_params
          params.permit(
            :from,
            :to,
            :currency,
            :payment_method,
            :student_id,
            :fee_plan_id,
            :assignment_id,
            :status,
            :outstanding_only,
            :fully_paid_only,
            :page,
            :per_page
          ).to_h.symbolize_keys
        end
      end
    end
  end
end
