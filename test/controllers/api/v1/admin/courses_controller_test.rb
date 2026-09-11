require "test_helper"

module Api
  module V1
    module Admin
      class CoursesControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 CrsCtrl", subdomain: "b1-crs-ctrl", code: "B1CRSCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 CrsCtrl", subdomain: "b2-crs-ctrl", code: "B2CRSCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant: nil)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @branch_admin1 = User.create!(
            email: "branch_admin1_crs@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin1",
            role: @admin_role1,
            tenant: @tenant1
          )

          @branch_admin2 = User.create!(
            email: "branch_admin2_crs@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin2",
            role: @admin_role2,
            tenant: @tenant2
          )

          @super_admin = User.create!(
            email: "super_admin_crs@example.com",
            password: "password123",
            first_name: "Super",
            last_name: "Admin",
            role: @super_admin_role,
            tenant: nil
          )

          @student_user = User.create!(
            email: "student_user_crs@example.com",
            password: "password123",
            first_name: "Student",
            last_name: "User",
            role: @student_role,
            tenant: @tenant1
          )

          @token1 = Authentication::JwtService.issue_access_token(@branch_admin1)
          @token2 = Authentication::JwtService.issue_access_token(@branch_admin2)
          @super_token = Authentication::JwtService.issue_access_token(@super_admin)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @global_course = Course.create!(
            tenant: nil,
            name: "Global DCA",
            code: "GDCA-100",
            duration_months: 6,
            base_fee: 5000.0
          )

          @course1 = Course.create!(
            tenant: @tenant1,
            name: "Branch 1 Spoken English",
            code: "B1ENG-101",
            duration_months: 2,
            base_fee: 2000.0
          )

          @course2 = Course.create!(
            tenant: @tenant2,
            name: "Branch 2 Python",
            code: "B2PY-101",
            duration_months: 4,
            base_fee: 6000.0
          )
        end

        test "branch admin can list global courses and own tenant courses" do
          get api_v1_admin_courses_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 2, json["data"].length
          codes = json["data"].map { |c| c["code"] }
          assert_includes codes, "GDCA-100"
          assert_includes codes, "B1ENG-101"
          assert_not_includes codes, "B2PY-101"
        end

        test "branch admin can view a global course" do
          get api_v1_admin_course_url(@global_course.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @global_course.id, json["data"]["id"]
          assert_equal true, json["data"]["is_global"]
        end

        test "branch admin cannot view another tenant's custom course" do
          get api_v1_admin_course_url(@course2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "branch admin can create a custom course for own tenant" do
          post api_v1_admin_courses_url,
               params: {
                 course: {
                   name: "Web Design",
                   code: "WD-101",
                   duration_months: 3,
                   base_fee: 3500.0
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "WD-101", json["data"]["code"]
          assert_equal false, json["data"]["is_global"]
        end

        test "branch admin cannot create a global course" do
          post api_v1_admin_courses_url,
               params: {
                 course: {
                   name: "Fake Global",
                   code: "FGL-101",
                   is_global: true
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          # Should force tenant_id to branch_admin's tenant_id
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal false, json["data"]["is_global"]
        end

        test "super admin can create a global course" do
          post api_v1_admin_courses_url,
               params: {
                 course: {
                   name: "Master AI Course",
                   code: "AI-900",
                   duration_months: 12,
                   base_fee: 15000.0,
                   is_global: true
                 }
               },
               headers: { "Authorization" => "Bearer #{@super_token}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_nil json["data"]["tenant_id"]
          assert_equal true, json["data"]["is_global"]
        end

        test "returns 422 for invalid course params" do
          post api_v1_admin_courses_url,
               params: { course: { name: "", code: "" } },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
          json = JSON.parse(response.body)
          assert_equal false, json["success"]
          assert json["errors"].any?
        end

        test "branch admin can update own course" do
          patch api_v1_admin_course_url(@course1.id),
                params: { course: { name: "Advanced Spoken English", base_fee: 2500.0 } },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "Advanced Spoken English", json["data"]["name"]
          assert_equal 2500.0, json["data"]["base_fee"].to_f
        end

        test "branch admin cannot update a global course" do
          patch api_v1_admin_course_url(@global_course.id),
                params: { course: { name: "Hacked Global Course" } },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :forbidden
          assert_equal "Global DCA", @global_course.reload.name
        end

        test "branch admin cannot delete another tenant's custom course" do
          delete api_v1_admin_course_url(@course2.id),
                 headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
          assert_not_nil Course.find_by(id: @course2.id)
        end

        test "unauthorized student user is denied course endpoint access" do
          get api_v1_admin_courses_url,
              headers: { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }

          assert_response :forbidden
        end

        test "unauthenticated request is denied access" do
          get api_v1_admin_courses_url,
              headers: { "Accept" => "application/json" }

          assert_response :unauthorized
        end
      end
    end
  end
end
