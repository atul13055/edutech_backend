require "test_helper"

class FeeInstallmentTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Inst", subdomain: "b-inst", code: "BINST-100", status: "active")
    @fee_plan = FeePlan.create!(tenant: @tenant, name: "Semester Fee", total_amount: 3000.0, installment_count: 3)
  end

  test "creates installment with default name and validates installment number uniqueness within plan" do
    inst1 = FeeInstallment.create!(
      tenant: @tenant,
      fee_plan: @fee_plan,
      installment_number: 1,
      amount: 1000.0
    )

    assert_equal "Installment 1", inst1.name
    assert_equal 1000.0, inst1.amount

    duplicate_inst = FeeInstallment.new(
      tenant: @tenant,
      fee_plan: @fee_plan,
      installment_number: 1,
      amount: 1000.0
    )

    assert_not duplicate_inst.valid?
    assert_includes duplicate_inst.errors[:installment_number], "has already been taken"
  end

  test "rejects zero or negative installment amount" do
    inst = FeeInstallment.new(
      tenant: @tenant,
      fee_plan: @fee_plan,
      installment_number: 2,
      amount: 0
    )

    assert_not inst.valid?
    assert_includes inst.errors[:amount], "must be greater than 0"
  end
end
