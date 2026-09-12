class FinanceReportBlueprint < Blueprinter::Base
  # Serializer for report payload objects returned by Finance::ReportsService
  field :report_type
  field :tenant_id
  field :currency, if: ->(_field_name, report, _options) { report.key?(:currency) }
  field :date_range, if: ->(_field_name, report, _options) { report.key?(:date_range) }
  field :report_period, if: ->(_field_name, report, _options) { report.key?(:report_period) }

  field :gross_collection, if: ->(_field_name, report, _options) { report.key?(:gross_collection) }
  field :completed_refunds, if: ->(_field_name, report, _options) { report.key?(:completed_refunds) }
  field :net_collection, if: ->(_field_name, report, _options) { report.key?(:net_collection) }
  field :completed_payments_count, if: ->(_field_name, report, _options) { report.key?(:completed_payments_count) }
  field :completed_refunds_count, if: ->(_field_name, report, _options) { report.key?(:completed_refunds_count) }
  field :payment_method_breakdown, if: ->(_field_name, report, _options) { report.key?(:payment_method_breakdown) }

  field :methods, if: ->(_field_name, report, _options) { report.key?(:methods) }
  field :assignments, if: ->(_field_name, report, _options) { report.key?(:assignments) }
  field :ledgers, if: ->(_field_name, report, _options) { report.key?(:ledgers) }
  field :status_breakdown, if: ->(_field_name, report, _options) { report.key?(:status_breakdown) }
  field :highlights, if: ->(_field_name, report, _options) { report.key?(:highlights) }
  field :daily_collections, if: ->(_field_name, report, _options) { report.key?(:daily_collections) }

  field :gross_completed_collection, if: ->(_field_name, report, _options) { report.key?(:gross_completed_collection) }
  field :refunds_completed, if: ->(_field_name, report, _options) { report.key?(:refunds_completed) }
  field :net_settlement_amount, if: ->(_field_name, report, _options) { report.key?(:net_settlement_amount) }
  field :payment_method_totals, if: ->(_field_name, report, _options) { report.key?(:payment_method_totals) }
  field :unresolved_payment_intent_amount, if: ->(_field_name, report, _options) { report.key?(:unresolved_payment_intent_amount) }
  field :unknown_payment_amount, if: ->(_field_name, report, _options) { report.key?(:unknown_payment_amount) }

  field :totals, if: ->(_field_name, report, _options) { report.key?(:totals) }
end
