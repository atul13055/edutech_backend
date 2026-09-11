require "test_helper"

module Api
  module V1
    module Admin
      class LeadsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 LCtrl", subdomain: "b1-lctrl", code: "B1LCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 LCtrl", subdomain: "b2-lctrl", code: "B2LCTRL-100", status: "active")

          @counselor_role1 = Role.create!(name: "Counselor 1", key: "counselor", tenant: @tenant1)
          @counselor_role2 = Role.create!(name: "Counselor 2", key: "counselor", tenant: @tenant2)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @counselor1 = User.create!(tenant: @tenant1, role: @counselor_role1, first_name: "C1", email: "c1_lctrl@example.com", password: "password123")
          @counselor2 = User.create!(tenant: @tenant2, role: @counselor_role2, first_name: "C2", email: "c2_lctrl@example.com", password: "password123")
          @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "S1", email: "s1_lctrl@example.com", password: "password123")

          @token1 = Authentication::JwtService.issue_access_token(@counselor1)
          @token2 = Authentication::JwtService.issue_access_token(@counselor2)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @course1 = Course.create!(tenant: @tenant1, name: "Course 1", code: "C1")
          @course2 = Course.create!(tenant: @tenant2, name: "Course 2", code: "C2")

          @lead1 = Lead.create!(tenant: @tenant1, name: "Lead One", email: "l1@example.com", interested_course: @course1, assigned_to: @counselor1)
          @lead2 = Lead.create!(tenant: @tenant2, name: "Lead Two", email: "l2@example.com", interested_course: @course2, assigned_to: @counselor2)
        end

        test "counselor can list own tenant leads" do
          get api_v1_admin_leads_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "Lead One", json["data"].first["name"]
        end

        test "counselor can create lead in own tenant" do
          post api_v1_admin_leads_url,
               params: {
                 lead: {
                   name: "New Prospect",
                   email: "prospect@example.com",
                   phone: "9998887770",
                   interested_course_id: @course1.id
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "New Prospect", json["data"]["name"]
        end

        test "counselor cannot create lead with cross tenant course" do
          post api_v1_admin_leads_url,
               params: {
                 lead: {
                   name: "Hacked Prospect",
                   interested_course_id: @course2.id
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
        end

        test "counselor can convert lead to admission" do
          post convert_api_v1_admin_lead_url(@lead1.id),
               params: {
                 course_id: @course1.id
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "converted", json["data"]["lead"]["status"]
          assert_not_nil json["data"]["admission"]
          assert_not_nil json["data"]["student"]
        end

        test "counselor cannot view another tenant lead" do
          get api_v1_admin_lead_url(@lead2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "student is denied access" do
          get api_v1_admin_leads_url,
              headers: { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }

          assert_response :forbidden
        end
      end
    end
  end
end
