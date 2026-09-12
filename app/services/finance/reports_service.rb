module Finance
  class ReportsService
    class InvalidDateRangeError < StandardError; end
    class MissingParameterError < StandardError; end

    SUPPORTED_PAYMENT_METHODS = %w[cash upi bank_transfer cheque online].freeze

    def initialize(tenant: nil, user: nil)
      @tenant = tenant || Current.tenant || user&.tenant
      raise ArgumentError, "Tenant context required for finance reports" if @tenant.nil?
    end

    # Report A: Collection Summary
    def collection_summary(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])
      payment_method = params[:payment_method].presence

      payments_scope = FeePayment.where(tenant_id: @tenant.id, status: "completed", currency: currency)
      refunds_scope = PaymentRefund.where(tenant_id: @tenant.id, status: "completed", currency: currency)

      if range
        payments_scope = payments_scope.where(paid_at: range[:start]..range[:end])
        refunds_scope = refunds_scope.where(completed_at: range[:start]..range[:end])
      end

      if payment_method
        payments_scope = payments_scope.where(payment_method: payment_method)
        refunds_scope = refunds_scope.joins(:fee_payment).where(fee_payments: { payment_method: payment_method })
      end

      gross_collection = BigDecimal(payments_scope.sum(:amount).to_s)
      completed_refunds = BigDecimal(refunds_scope.sum(:amount).to_s)
      net_collection = gross_collection - completed_refunds

      payment_count = payments_scope.count
      refund_count = refunds_scope.count

      methods_breakdown = build_methods_breakdown(range, currency)

      {
        report_type: "collection_summary",
        tenant_id: @tenant.id,
        currency: currency,
        date_range: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        gross_collection: gross_collection,
        completed_refunds: completed_refunds,
        net_collection: net_collection,
        completed_payments_count: payment_count,
        completed_refunds_count: refund_count,
        payment_method_breakdown: methods_breakdown
      }
    end

    # Report B: Payment Methods Breakdown
    def payment_methods_breakdown(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])

      methods_breakdown = build_methods_breakdown(range, currency)

      total_gross = methods_breakdown.sum { |m| m[:gross_amount] }
      total_refunded = methods_breakdown.sum { |m| m[:refunded_amount] }
      total_net = total_gross - total_refunded

      {
        report_type: "payment_methods",
        tenant_id: @tenant.id,
        currency: currency,
        date_range: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        methods: methods_breakdown,
        totals: {
          gross_amount: total_gross,
          refunded_amount: total_refunded,
          net_amount: total_net
        }
      }
    end

    # Report C: Outstanding Fees Report
    def outstanding_fees(params = {})
      range = parse_date_range(params[:from], params[:to])

      scope = StudentFeeAssignment.where(tenant_id: @tenant.id)
                                 .includes(:student, :fee_plan)

      scope = scope.where(student_id: params[:student_id]) if params[:student_id].present?
      scope = scope.where(fee_plan_id: params[:fee_plan_id]) if params[:fee_plan_id].present?
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(assigned_at: range[:start]..range[:end]) if range

      assignments = scope.to_a

      items = assignments.map do |asg|
        gross_paid = asg.total_paid_amount
        completed_refund = asg.total_refunded_amount
        net_paid = asg.net_paid_amount
        outstanding = asg.outstanding_amount

        {
          assignment_id: asg.id,
          student: {
            id: asg.student.id,
            first_name: asg.student.first_name,
            last_name: asg.student.last_name,
            roll_number: asg.student.roll_number
          },
          fee_plan: {
            id: asg.fee_plan.id,
            name: asg.fee_plan.name
          },
          total_amount: asg.total_amount,
          gross_paid: gross_paid,
          completed_refund: completed_refund,
          net_paid: net_paid,
          outstanding_amount: outstanding,
          status: asg.status,
          assigned_at: asg.assigned_at
        }
      end

      if params[:outstanding_only].to_s == "true" || params[:outstanding_only] == true
        items.select! { |i| i[:outstanding_amount] > 0 }
      elsif params[:fully_paid_only].to_s == "true" || params[:fully_paid_only] == true
        items.select! { |i| i[:outstanding_amount] == 0 }
      end

      total_assigned = items.sum { |i| i[:total_amount] }
      total_gross_paid = items.sum { |i| i[:gross_paid] }
      total_refunded = items.sum { |i| i[:completed_refund] }
      total_net_paid = items.sum { |i| i[:net_paid] }
      total_outstanding = items.sum { |i| i[:outstanding_amount] }

      {
        report_type: "outstanding_fees",
        tenant_id: @tenant.id,
        assignments: items,
        totals: {
          count: items.size,
          total_assigned: total_assigned,
          total_gross_paid: total_gross_paid,
          total_refunded: total_refunded,
          total_net_paid: total_net_paid,
          total_outstanding: total_outstanding
        }
      }
    end

    # Report D: Student Fee Ledger
    def student_ledger(params = {})
      student_id = params[:student_id].presence
      assignment_id = params[:assignment_id].presence

      if student_id.nil? && assignment_id.nil?
        raise MissingParameterError, "Either student_id or assignment_id must be provided"
      end

      scope = StudentFeeAssignment.where(tenant_id: @tenant.id).includes(:student, :fee_plan, :fee_payments, :payment_refunds)
      scope = scope.where(student_id: student_id) if student_id.present?
      scope = scope.where(id: assignment_id) if assignment_id.present?

      assignments = scope.to_a

      ledgers = assignments.map do |asg|
        payments = asg.fee_payments.where(status: "completed").map do |fp|
          {
            id: fp.id,
            amount: fp.amount,
            currency: fp.currency,
            payment_method: fp.payment_method,
            payment_reference: fp.payment_reference,
            paid_at: fp.paid_at,
            idempotency_key: fp.idempotency_key
          }
        end

        refunds = asg.payment_refunds.map do |pr|
          {
            id: pr.id,
            fee_payment_id: pr.fee_payment_id,
            amount: pr.amount,
            currency: pr.currency,
            reason: pr.reason,
            status: pr.status,
            requested_at: pr.requested_at,
            approved_at: pr.approved_at,
            completed_at: pr.completed_at,
            refund_reference: pr.refund_reference
          }
        end

        {
          assignment: {
            id: asg.id,
            student_id: asg.student_id,
            fee_plan_id: asg.fee_plan_id,
            fee_plan_name: asg.fee_plan.name,
            total_amount: asg.total_amount,
            gross_paid: asg.total_paid_amount,
            completed_refund: asg.total_refunded_amount,
            net_paid: asg.net_paid_amount,
            outstanding_amount: asg.outstanding_amount,
            status: asg.status,
            assigned_at: asg.assigned_at
          },
          payments: payments,
          refunds: refunds
        }
      end

      {
        report_type: "student_ledger",
        tenant_id: @tenant.id,
        ledgers: ledgers
      }
    end

    # Report E: Refund Summary Report
    def refunds_summary(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])

      scope = PaymentRefund.where(tenant_id: @tenant.id, currency: currency)
      scope = scope.where(created_at: range[:start]..range[:end]) if range

      statuses = PaymentRefund::ALLOWED_STATUSES
      status_matrix = {}

      statuses.each do |st|
        st_scope = scope.where(status: st)
        status_matrix[st] = {
          count: st_scope.count,
          total_amount: BigDecimal(st_scope.sum(:amount).to_s)
        }
      end

      total_count = scope.count
      total_amount = BigDecimal(scope.sum(:amount).to_s)
      completed_count = status_matrix["completed"][:count]
      completed_amount = status_matrix["completed"][:total_amount]

      {
        report_type: "refunds_summary",
        tenant_id: @tenant.id,
        currency: currency,
        date_range: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        status_breakdown: status_matrix,
        totals: {
          total_refunds_count: total_count,
          total_refunds_amount: total_amount,
          completed_refunds_count: completed_count,
          completed_refunds_amount: completed_amount
        }
      }
    end

    # Report F: Payment Intent / Reconciliation Summary
    def payment_intents_summary(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])

      scope = PaymentIntent.where(tenant_id: @tenant.id, currency: currency)
      scope = scope.where(created_at: range[:start]..range[:end]) if range

      statuses = PaymentIntent::ALLOWED_STATUSES
      status_matrix = {}

      statuses.each do |st|
        st_scope = scope.where(status: st)
        status_matrix[st] = {
          count: st_scope.count,
          total_amount: BigDecimal(st_scope.sum(:amount).to_s)
        }
      end

      intent_total_amount = BigDecimal(scope.sum(:amount).to_s)

      # Actual completed fee payment amount linked to intents
      linked_payments_scope = FeePayment.where(tenant_id: @tenant.id, status: "completed", currency: currency)
                                       .where(id: scope.where.not(fee_payment_id: nil).select(:fee_payment_id))
      actual_completed_payment_amount = BigDecimal(linked_payments_scope.sum(:amount).to_s)

      unresolved_scope = scope.where(status: %w[pending processing unknown])
      unresolved_unknown_count = unresolved_scope.count
      unresolved_unknown_amount = BigDecimal(unresolved_scope.sum(:amount).to_s)

      {
        report_type: "payment_intents_summary",
        tenant_id: @tenant.id,
        currency: currency,
        date_range: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        status_breakdown: status_matrix,
        highlights: {
          intent_total_amount: intent_total_amount,
          actual_completed_payment_amount: actual_completed_payment_amount,
          unresolved_unknown_count: unresolved_unknown_count,
          unresolved_unknown_amount: unresolved_unknown_amount
        }
      }
    end

    # Report G: Daily Collection Report
    def daily_collection(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])

      payments_scope = FeePayment.where(tenant_id: @tenant.id, status: "completed", currency: currency)
      refunds_scope = PaymentRefund.where(tenant_id: @tenant.id, status: "completed", currency: currency)

      if range
        payments_scope = payments_scope.where(paid_at: range[:start]..range[:end])
        refunds_scope = refunds_scope.where(completed_at: range[:start]..range[:end])
      end

      daily_payments = payments_scope.group("DATE(paid_at)").select("DATE(paid_at) AS day, SUM(amount) AS gross_amount, COUNT(id) AS pay_count")
      daily_refunds = refunds_scope.group("DATE(completed_at)").select("DATE(completed_at) AS day, SUM(amount) AS ref_amount, COUNT(id) AS ref_count")

      dates_hash = {}

      daily_payments.each do |dp|
        d_str = dp.day.to_s
        dates_hash[d_str] ||= { gross: BigDecimal("0.0"), refunds: BigDecimal("0.0"), pay_count: 0, ref_count: 0 }
        dates_hash[d_str][:gross] = BigDecimal(dp.gross_amount.to_s)
        dates_hash[d_str][:pay_count] = dp.pay_count.to_i
      end

      daily_refunds.each do |dr|
        next if dr.day.blank?
        d_str = dr.day.to_s
        dates_hash[d_str] ||= { gross: BigDecimal("0.0"), refunds: BigDecimal("0.0"), pay_count: 0, ref_count: 0 }
        dates_hash[d_str][:refunds] = BigDecimal(dr.ref_amount.to_s)
        dates_hash[d_str][:ref_count] = dr.ref_count.to_i
      end

      sorted_dates = dates_hash.keys.sort

      daily_list = sorted_dates.map do |d_str|
        data = dates_hash[d_str]
        gross = data[:gross]
        refs = data[:refunds]
        net = gross - refs

        {
          date: d_str,
          gross_collection: gross,
          completed_refunds: refs,
          net_collection: net,
          payment_count: data[:pay_count],
          refund_count: data[:ref_count]
        }
      end

      total_gross = daily_list.sum { |d| d[:gross_collection] }
      total_refunds = daily_list.sum { |d| d[:completed_refunds] }
      total_net = total_gross - total_refunds

      {
        report_type: "daily_collection",
        tenant_id: @tenant.id,
        currency: currency,
        date_range: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        daily_collections: daily_list,
        totals: {
          gross_collection: total_gross,
          completed_refunds: total_refunds,
          net_collection: total_net,
          payment_count: daily_list.sum { |d| d[:payment_count] },
          refund_count: daily_list.sum { |d| d[:refund_count] }
        }
      }
    end

    # Report H: Settlement Summary
    def settlement_summary(params = {})
      range = parse_date_range(params[:from], params[:to])
      currency = normalize_currency(params[:currency])

      payments_scope = FeePayment.where(tenant_id: @tenant.id, status: "completed", currency: currency)
      refunds_scope = PaymentRefund.where(tenant_id: @tenant.id, status: "completed", currency: currency)
      intents_scope = PaymentIntent.where(tenant_id: @tenant.id, currency: currency)

      if range
        payments_scope = payments_scope.where(paid_at: range[:start]..range[:end])
        refunds_scope = refunds_scope.where(completed_at: range[:start]..range[:end])
        intents_scope = intents_scope.where(created_at: range[:start]..range[:end])
      end

      gross_collection = BigDecimal(payments_scope.sum(:amount).to_s)
      completed_refunds = BigDecimal(refunds_scope.sum(:amount).to_s)
      net_settlement = gross_collection - completed_refunds

      methods_breakdown = build_methods_breakdown(range, currency)
      method_totals = {}
      methods_breakdown.each do |m|
        method_totals[m[:payment_method]] = m[:net_amount]
      end

      unresolved_intents_scope = intents_scope.where(status: %w[pending processing])
      unresolved_intent_amount = BigDecimal(unresolved_intents_scope.sum(:amount).to_s)

      unknown_intents_scope = intents_scope.where(status: "unknown")
      unknown_payment_amount = BigDecimal(unknown_intents_scope.sum(:amount).to_s)

      {
        report_type: "settlement_summary",
        tenant_id: @tenant.id,
        currency: currency,
        report_period: {
          from: range ? range[:start].iso8601 : nil,
          to: range ? range[:end].iso8601 : nil
        },
        gross_completed_collection: gross_collection,
        refunds_completed: completed_refunds,
        net_settlement_amount: net_settlement,
        payment_method_totals: method_totals,
        unresolved_payment_intent_amount: unresolved_intent_amount,
        unknown_payment_amount: unknown_payment_amount
      }
    end

    private

    def normalize_currency(curr)
      curr.presence ? curr.to_s.strip.upcase : "INR"
    end

    def parse_date_range(from_str, to_str)
      return nil if from_str.blank? && to_str.blank?

      start_time = from_str.present? ? Time.zone.parse(from_str.to_s)&.beginning_of_day : Time.at(0).in_time_zone
      end_time = to_str.present? ? Time.zone.parse(to_str.to_s)&.end_of_day : Time.current.end_of_day

      if start_time && end_time && start_time > end_time
        raise InvalidDateRangeError, "'from' date (#{from_str}) cannot be after 'to' date (#{to_str})"
      end

      { start: start_time, end: end_time }
    end

    def build_methods_breakdown(range, currency)
      SUPPORTED_PAYMENT_METHODS.map do |method_key|
        payments = FeePayment.where(tenant_id: @tenant.id, status: "completed", currency: currency, payment_method: method_key)
        refunds = PaymentRefund.where(tenant_id: @tenant.id, status: "completed", currency: currency)
                               .joins(:fee_payment)
                               .where(fee_payments: { payment_method: method_key })

        if range
          payments = payments.where(paid_at: range[:start]..range[:end])
          refunds = refunds.where(completed_at: range[:start]..range[:end])
        end

        gross = BigDecimal(payments.sum(:amount).to_s)
        ref = BigDecimal(refunds.sum(:amount).to_s)
        net = gross - ref

        {
          payment_method: method_key,
          transaction_count: payments.count,
          gross_amount: gross,
          refunded_amount: ref,
          net_amount: net
        }
      end
    end
  end
end
