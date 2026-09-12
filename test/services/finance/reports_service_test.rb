require "test_helper"

module Finance
  class ReportsServiceTest < ActiveSupport::TestCase
    setup do
      @tenant = Tenant.create!(name: "Finance Tenant Service", subdomain: "fin-srv", code: "FIN-SRV-100", status: "active")
      @other_tenant = Tenant.create!(name: "Other Tenant Service", subdomain: "oth-srv", code: "OTH-SRV-100", status: "active")

      @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
      @user = User.create!(tenant: @tenant, role: @role, first_name: "Admin", email: "admin_fin_srv@example.com", password: "password123")
      @student = Student.create!(tenant: @tenant, first_name: "Frank", roll_number: "STU-FIN-SRV-1")

      @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan Fin Srv", total_amount: BigDecimal("10000.00"), currency: "INR")
      @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan, total_amount: BigDecimal("10000.00"))

      # Completed Fee Payment 1: 5000 INR via UPI
      @payment1 = FeePayment.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @assignment,
        amount: BigDecimal("5000.00"),
        currency: "INR",
        payment_method: "upi",
        status: "completed",
        idempotency_key: "fp-fin-srv-1",
        paid_at: Time.zone.parse("2026-09-01 10:00:00")
      )

      # Completed Fee Payment 2: 3000 INR via Cash
      @payment2 = FeePayment.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @assignment,
        amount: BigDecimal("3000.00"),
        currency: "INR",
        payment_method: "cash",
        status: "completed",
        idempotency_key: "fp-fin-srv-2",
        paid_at: Time.zone.parse("2026-09-02 11:00:00")
      )

      # Completed Refund on Payment 1: 1500 INR
      @refund1 = PaymentRefund.create!(
        tenant: @tenant,
        fee_payment: @payment1,
        student: @student,
        student_fee_assignment: @assignment,
        requested_by: @user,
        approved_by: @user,
        amount: BigDecimal("1500.00"),
        currency: "INR",
        reason: "Partial refund test",
        status: "completed",
        idempotency_key: "pr-fin-srv-1",
        requested_at: Time.zone.parse("2026-09-02 12:00:00"),
        completed_at: Time.zone.parse("2026-09-02 13:00:00")
      )

      # Non-completed Refund (rejected): 500 INR - must NOT reduce collection
      @refund_rejected = PaymentRefund.create!(
        tenant: @tenant,
        fee_payment: @payment1,
        student: @student,
        student_fee_assignment: @assignment,
        requested_by: @user,
        amount: BigDecimal("500.00"),
        currency: "INR",
        reason: "Rejected refund test",
        status: "rejected",
        idempotency_key: "pr-fin-srv-rej",
        requested_at: Time.zone.parse("2026-09-02 14:00:00")
      )

      Current.tenant = @tenant
      @service = ReportsService.new(tenant: @tenant, user: @user)
    end

    test "collection_summary calculates gross, completed refunds, and net collection accurately using BigDecimal" do
      report = @service.collection_summary

      assert_equal "collection_summary", report[:report_type]
      assert_equal BigDecimal("8000.00"), report[:gross_collection]
      assert_equal BigDecimal("1500.00"), report[:completed_refunds]
      assert_equal BigDecimal("6500.00"), report[:net_collection]
      assert_equal 2, report[:completed_payments_count]
      assert_equal 1, report[:completed_refunds_count]
    end

    test "collection_summary filters correctly by date range" do
      report_sep1 = @service.collection_summary(from: "2026-09-01", to: "2026-09-01")

      assert_equal BigDecimal("5000.00"), report_sep1[:gross_collection]
      assert_equal BigDecimal("0.00"), report_sep1[:completed_refunds]
      assert_equal BigDecimal("5000.00"), report_sep1[:net_collection]
      assert_equal 1, report_sep1[:completed_payments_count]
    end

    test "raises InvalidDateRangeError if from date is after to date" do
      assert_raises(ReportsService::InvalidDateRangeError) do
        @service.collection_summary(from: "2026-09-10", to: "2026-09-01")
      end
    end

    test "payment_methods_breakdown groups totals correctly by method" do
      report = @service.payment_methods_breakdown

      upi_method = report[:methods].find { |m| m[:payment_method] == "upi" }
      cash_method = report[:methods].find { |m| m[:payment_method] == "cash" }

      assert_equal BigDecimal("5000.00"), upi_method[:gross_amount]
      assert_equal BigDecimal("1500.00"), upi_method[:refunded_amount]
      assert_equal BigDecimal("3500.00"), upi_method[:net_amount]

      assert_equal BigDecimal("3000.00"), cash_method[:gross_amount]
      assert_equal BigDecimal("0.00"), cash_method[:refunded_amount]
      assert_equal BigDecimal("3000.00"), cash_method[:net_amount]

      assert_equal BigDecimal("8000.00"), report[:totals][:gross_amount]
      assert_equal BigDecimal("1500.00"), report[:totals][:refunded_amount]
      assert_equal BigDecimal("6500.00"), report[:totals][:net_amount]
    end

    test "outstanding_fees report calculates student assignment net paid and outstanding correctly" do
      report = @service.outstanding_fees

      assert_equal 1, report[:assignments].size
      item = report[:assignments].first

      assert_equal BigDecimal("10000.00"), item[:total_amount]
      assert_equal BigDecimal("8000.00"), item[:gross_paid]
      assert_equal BigDecimal("1500.00"), item[:completed_refund]
      assert_equal BigDecimal("6500.00"), item[:net_paid]
      assert_equal BigDecimal("3500.00"), item[:outstanding_amount]
    end

    test "student_ledger raises MissingParameterError when neither student_id nor assignment_id is supplied" do
      assert_raises(ReportsService::MissingParameterError) do
        @service.student_ledger
      end
    end

    test "student_ledger returns payment and refund history for student" do
      report = @service.student_ledger(student_id: @student.id)

      assert_equal 1, report[:ledgers].size
      ledger = report[:ledgers].first

      assert_equal 2, ledger[:payments].size
      assert_equal 2, ledger[:refunds].size
    end

    test "refunds_summary groups by refund status correctly" do
      report = @service.refunds_summary

      assert_equal 1, report[:status_breakdown]["completed"][:count]
      assert_equal BigDecimal("1500.00"), report[:status_breakdown]["completed"][:total_amount]

      assert_equal 1, report[:status_breakdown]["rejected"][:count]
      assert_equal BigDecimal("500.00"), report[:status_breakdown]["rejected"][:total_amount]

      assert_equal BigDecimal("1500.00"), report[:totals][:completed_refunds_amount]
    end

    test "payment_intents_summary separates intent status amounts and highlights unresolved unknown amounts" do
      PaymentIntent.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @assignment,
        amount: BigDecimal("2000.00"),
        currency: "INR",
        payment_method: "upi",
        status: "unknown",
        idempotency_key: "pi-fin-srv-unk"
      )

      report = @service.payment_intents_summary

      assert_equal 1, report[:status_breakdown]["unknown"][:count]
      assert_equal BigDecimal("2000.00"), report[:status_breakdown]["unknown"][:total_amount]
      assert_equal 1, report[:highlights][:unresolved_unknown_count]
      assert_equal BigDecimal("2000.00"), report[:highlights][:unresolved_unknown_amount]
    end

    test "daily_collection aggregates collections and refunds by date" do
      report = @service.daily_collection

      assert_equal 2, report[:daily_collections].size

      day1 = report[:daily_collections].find { |d| d[:date] == "2026-09-01" }
      day2 = report[:daily_collections].find { |d| d[:date] == "2026-09-02" }

      assert_equal BigDecimal("5000.00"), day1[:gross_collection]
      assert_equal BigDecimal("0.00"), day1[:completed_refunds]
      assert_equal BigDecimal("5000.00"), day1[:net_collection]

      assert_equal BigDecimal("3000.00"), day2[:gross_collection]
      assert_equal BigDecimal("1500.00"), day2[:completed_refunds]
      assert_equal BigDecimal("1500.00"), day2[:net_collection]
    end

    test "settlement_summary returns internal accounting view of net collection and unresolved amounts" do
      report = @service.settlement_summary

      assert_equal BigDecimal("8000.00"), report[:gross_completed_collection]
      assert_equal BigDecimal("1500.00"), report[:refunds_completed]
      assert_equal BigDecimal("6500.00"), report[:net_settlement_amount]
      assert_equal BigDecimal("3500.00"), report[:payment_method_totals]["upi"]
      assert_equal BigDecimal("3000.00"), report[:payment_method_totals]["cash"]
    end
  end
end
