require "test_helper"

module Api
  module V1
    module Admin
      class StudentFeeAssignmentsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 AsgCtrl", subdomain: "b1-actrl2", code: "B1ACTRL-200", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 AsgCtrl", subdomain: "b2-actrl2", code: "B2ACTRL-200", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_actrl2@example.com", password: "password123")
          @token1 = Authentication::JwtService.issue_access_token(@admin1)

          @student1 = Student.create!(tenant: @tenant1, first_name: "Student 1", roll_number: "S201")
          @student2 = Student.create!(tenant: @tenant2, first_name: "Student 2", roll_number: "S202")

          @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan 1", total_amount: 3000.0)
          @plan2 = FeePlan.create!(tenant: @tenant2, name: "Plan 2", total_amount: 4000.0)

          @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
          @asg2 = StudentFeeAssignment.create!(tenant: @tenant2, student: @student2, fee_plan: @plan2)
        end

        test "admin can list own tenant fee assignments" do
          get api_v1_admin_student_fee_assignments_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal @asg1.id, json["data"].first["id"]
        end

        test "admin can assign fee plan to own student preserving snapshot total" do
          new_student = Student.create!(tenant: @tenant1, first_name: "New Student", roll_number: "S203")

          post api_v1_admin_student_fee_assignments_url,
               params: {
                 student_fee_assignment: {
                   student_id: new_student.id,
                   fee_plan_id: @plan1.id,
                   notes: "First year assignment"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "3000.0", json["data"]["total_amount"].to_s
          assert_equal "INR", json["data"]["currency"]
        end

        test "admin cannot assign fee plan with cross tenant student" do
          post api_v1_admin_student_fee_assignments_url,
               params: {
                 student_fee_assignment: {
                   student_id: @student2.id,
                   fee_plan_id: @plan1.id
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
        end

        test "admin cannot view another tenant fee assignment" do
          get api_v1_admin_student_fee_assignment_url(@asg2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end
      end
    end
  end
end
