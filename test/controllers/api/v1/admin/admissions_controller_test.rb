require "test_helper"

module Api
  module V1
    module Admin
      class AdmissionsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 ACtrl", subdomain: "b1-actrl", code: "B1ACTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 ACtrl", subdomain: "b2-actrl", code: "B2ACTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_actrl@example.com", password: "password123")
          @token1 = Authentication::JwtService.issue_access_token(@admin1)

          @student1 = Student.create!(tenant: @tenant1, first_name: "Student 1", roll_number: "S101")
          @student2 = Student.create!(tenant: @tenant2, first_name: "Student 2", roll_number: "S102")

          @course1 = Course.create!(tenant: @tenant1, name: "Course 1", code: "C1")
          @course2 = Course.create!(tenant: @tenant2, name: "Course 2", code: "C2")

          @admission1 = Admission.create!(tenant: @tenant1, student: @student1, course: @course1, admission_date: Date.today)
          @admission2 = Admission.create!(tenant: @tenant2, student: @student2, course: @course2, admission_date: Date.today)
        end

        test "admin can list own tenant admissions" do
          get api_v1_admin_admissions_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal @admission1.id, json["data"].first["id"]
        end

        test "admin can create admission for own student and course" do
          new_student = Student.create!(tenant: @tenant1, first_name: "New Student", roll_number: "S103")

          post api_v1_admin_admissions_url,
               params: {
                 admission: {
                   student_id: new_student.id,
                   course_id: @course1.id,
                   admission_date: Date.today.to_s,
                   status: "confirmed"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "confirmed", json["data"]["status"]
        end

        test "admin cannot create admission with student from another tenant" do
          post api_v1_admin_admissions_url,
               params: {
                 admission: {
                   student_id: @student2.id,
                   course_id: @course1.id,
                   admission_date: Date.today.to_s
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
        end

        test "admin cannot view another tenant admission" do
          get api_v1_admin_admission_url(@admission2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end
      end
    end
  end
end
