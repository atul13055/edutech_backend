require "test_helper"

module Api
  module V1
    module Admin
      class StudentsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 StuCtrl", subdomain: "b1-stu-ctrl", code: "B1STUCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 StuCtrl", subdomain: "b2-stu-ctrl", code: "B2STUCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant: nil)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @branch_admin1 = User.create!(
            email: "branch_admin1_stu@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin1",
            role: @admin_role1,
            tenant: @tenant1
          )

          @branch_admin2 = User.create!(
            email: "branch_admin2_stu@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin2",
            role: @admin_role2,
            tenant: @tenant2
          )

          @super_admin = User.create!(
            email: "super_admin_stu@example.com",
            password: "password123",
            first_name: "Super",
            last_name: "Admin",
            role: @super_admin_role,
            tenant: nil
          )

          @student_user = User.create!(
            email: "student_user_stu@example.com",
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

          @student1 = Student.create!(
            tenant: @tenant1,
            first_name: "John",
            last_name: "Doe",
            roll_number: "STU-001",
            email: "john@example.com",
            status: "active"
          )

          @student2 = Student.create!(
            tenant: @tenant1,
            first_name: "Jane",
            last_name: "Smith",
            roll_number: "STU-002",
            email: "jane@example.com",
            status: "inactive"
          )

          @student_other = Student.create!(
            tenant: @tenant2,
            first_name: "Bob",
            last_name: "Other",
            roll_number: "STU-003",
            email: "bob@example.com",
            status: "active"
          )
        end

        test "branch admin can list own tenant students with pagination" do
          get api_v1_admin_students_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 2, json["data"].length
          assert_equal 2, json["meta"]["total_count"]
          assert_equal 1, json["meta"]["current_page"]
        end

        test "branch admin can filter students by query and status" do
          get api_v1_admin_students_url,
              params: { query: "John", status: "active" },
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "STU-001", json["data"].first["roll_number"]
        end

        test "branch admin can view specific student details" do
          get api_v1_admin_student_url(@student1.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @student1.id, json["data"]["id"]
          assert_equal "John", json["data"]["first_name"]
          assert_equal "John Doe", json["data"]["full_name"]
        end

        test "branch admin cannot view student belonging to another tenant" do
          get api_v1_admin_student_url(@student_other.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "branch admin can create student for own tenant ignoring client-supplied tenant_id" do
          post api_v1_admin_students_url,
               params: {
                 student: {
                   first_name: "Charlie",
                   last_name: "Brown",
                   roll_number: "STU-004",
                   email: "charlie@example.com",
                   tenant_id: @tenant2.id
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "STU-004", json["data"]["roll_number"]
        end

        test "returns 422 for invalid student creation params" do
          post api_v1_admin_students_url,
               params: { student: { first_name: "", roll_number: "" } },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
          json = JSON.parse(response.body)
          assert_equal false, json["success"]
          assert json["errors"].any?
        end

        test "branch admin can update own student and cannot change tenant_id" do
          patch api_v1_admin_student_url(@student1.id),
                params: {
                  student: {
                    first_name: "Johnny",
                    tenant_id: @tenant2.id
                  }
                },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "Johnny", json["data"]["first_name"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal @tenant1.id, @student1.reload.tenant_id
        end

        test "branch admin cannot update student belonging to another tenant" do
          patch api_v1_admin_student_url(@student_other.id),
                params: { student: { first_name: "Hacked" } },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :not_found
          assert_equal "Bob", @student_other.reload.first_name
        end

        test "branch admin can delete own student" do
          delete api_v1_admin_student_url(@student1.id),
                 headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          assert_nil Student.find_by(id: @student1.id)
        end

        test "branch admin cannot delete student belonging to another tenant" do
          delete api_v1_admin_student_url(@student_other.id),
                 headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
          assert_not_nil Student.find_by(id: @student_other.id)
        end

        test "super admin can access students across tenants with X-Tenant-ID header" do
          get api_v1_admin_students_url,
              headers: {
                "Authorization" => "Bearer #{@super_token}",
                "X-Tenant-ID" => @tenant2.id,
                "Accept" => "application/json"
              }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal @tenant2.id, json["data"].first["tenant_id"]
        end

        test "unauthorized user with student role is denied access" do
          get api_v1_admin_students_url,
              headers: { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }

          assert_response :forbidden
        end

        test "unauthenticated request is denied access" do
          get api_v1_admin_students_url,
              headers: { "Accept" => "application/json" }

          assert_response :unauthorized
        end
      end
    end
  end
end
