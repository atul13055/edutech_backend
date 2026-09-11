require "test_helper"

module Api
  module V1
    module Admin
      class FeePlansControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 FCtrl", subdomain: "b1-fctrl", code: "B1FCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 FCtrl", subdomain: "b2-fctrl", code: "B2FCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_fctrl@example.com", password: "password123")
          @admin2 = User.create!(tenant: @tenant2, role: @admin_role2, first_name: "Admin2", email: "admin2_fctrl@example.com", password: "password123")
          @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student1", email: "stu1_fctrl@example.com", password: "password123")

          @token1 = Authentication::JwtService.issue_access_token(@admin1)
          @token2 = Authentication::JwtService.issue_access_token(@admin2)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @course1 = Course.create!(tenant: @tenant1, name: "Course 1", code: "C1")
          @course2 = Course.create!(tenant: @tenant2, name: "Course 2", code: "C2")

          @plan1 = FeePlan.create!(tenant: @tenant1, course: @course1, name: "Plan One", total_amount: 1500.0)
          @plan2 = FeePlan.create!(tenant: @tenant2, course: @course2, name: "Plan Two", total_amount: 2500.0)
        end

        test "admin can list own tenant fee plans" do
          get api_v1_admin_fee_plans_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "Plan One", json["data"].first["name"]
        end

        test "admin can create fee plan in own tenant" do
          post api_v1_admin_fee_plans_url,
               params: {
                 fee_plan: {
                   name: "New Plan",
                   description: "Test plan",
                   total_amount: 3000.0,
                   currency: "INR",
                   installment_count: 3
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "New Plan", json["data"]["name"]
        end

        test "admin cannot create fee plan referencing cross tenant course" do
          post api_v1_admin_fee_plans_url,
               params: {
                 fee_plan: {
                   name: "Hacked Plan",
                   course_id: @course2.id,
                   total_amount: 1000.0
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
        end

        test "admin cannot view another tenant fee plan" do
          get api_v1_admin_fee_plan_url(@plan2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "student user is denied fee plan management" do
          get api_v1_admin_fee_plans_url,
              headers: { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }

          assert_response :forbidden
        end
      end
    end
  end
end
