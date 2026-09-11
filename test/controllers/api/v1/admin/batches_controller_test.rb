require "test_helper"

module Api
  module V1
    module Admin
      class BatchesControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 BtCtrl", subdomain: "b1-bt-ctrl", code: "B1BTCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 BtCtrl", subdomain: "b2-bt-ctrl", code: "B2BTCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @branch_admin1 = User.create!(
            email: "admin1_btctrl@example.com",
            password: "password123",
            first_name: "Admin",
            last_name: "One",
            role: @admin_role1,
            tenant: @tenant1
          )

          @branch_admin2 = User.create!(
            email: "admin2_btctrl@example.com",
            password: "password123",
            first_name: "Admin",
            last_name: "Two",
            role: @admin_role2,
            tenant: @tenant2
          )

          @student_user = User.create!(
            email: "student_btctrl@example.com",
            password: "password123",
            first_name: "Student",
            last_name: "User",
            role: @student_role,
            tenant: @tenant1
          )

          @token1 = Authentication::JwtService.issue_access_token(@branch_admin1)
          @token2 = Authentication::JwtService.issue_access_token(@branch_admin2)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @course1 = Course.create!(tenant: @tenant1, name: "Course 1", code: "C1")
          @course2 = Course.create!(tenant: @tenant2, name: "Course 2", code: "C2")
          @global_course = Course.create!(tenant: nil, name: "Global Course", code: "GC")

          @batch1 = Batch.create!(
            tenant: @tenant1,
            course: @course1,
            name: "Morning Batch 1",
            code: "MB-01",
            capacity: 20,
            start_date: Date.today
          )

          @batch2 = Batch.create!(
            tenant: @tenant2,
            course: @course2,
            name: "Evening Batch 2",
            code: "EB-02",
            capacity: 30,
            start_date: Date.today
          )
        end

        test "branch admin can list own tenant batches" do
          get api_v1_admin_batches_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "MB-01", json["data"].first["code"]
        end

        test "branch admin can view own batch" do
          get api_v1_admin_batch_url(@batch1.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @batch1.id, json["data"]["id"]
        end

        test "branch admin cannot view another tenant batch" do
          get api_v1_admin_batch_url(@batch2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "branch admin can create batch with own course or global course" do
          post api_v1_admin_batches_url,
               params: {
                 batch: {
                   course_id: @global_course.id,
                   name: "Global Course Batch",
                   code: "GCB-100",
                   capacity: 40,
                   start_date: Date.today.to_s
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "GCB-100", json["data"]["code"]
        end

        test "branch admin cannot create batch with another tenant course" do
          post api_v1_admin_batches_url,
               params: {
                 batch: {
                   course_id: @course2.id,
                   name: "Cross Tenant Batch",
                   code: "CTB-100",
                   capacity: 30,
                   start_date: Date.today.to_s
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
          json = JSON.parse(response.body)
          assert_equal false, json["success"]
          assert json["errors"].any?
        end

        test "branch admin can update own batch" do
          patch api_v1_admin_batch_url(@batch1.id),
                params: { batch: { name: "Updated Morning Batch", capacity: 35 } },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "Updated Morning Batch", json["data"]["name"]
          assert_equal 35, json["data"]["capacity"]
        end

        test "branch admin cannot update another tenant batch" do
          patch api_v1_admin_batch_url(@batch2.id),
                params: { batch: { name: "Hacked Batch" } },
                headers: { "Authorization" => "Bearer #{@token1}" },
                as: :json

          assert_response :not_found
          assert_equal "Evening Batch 2", @batch2.reload.name
        end

        test "branch admin can delete own batch" do
          delete api_v1_admin_batch_url(@batch1.id),
                 headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          assert_nil Batch.find_by(id: @batch1.id)
        end

        test "unauthorized student is denied access" do
          get api_v1_admin_batches_url,
              headers: { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }

          assert_response :forbidden
        end

        test "unauthenticated request is denied access" do
          get api_v1_admin_batches_url,
              headers: { "Accept" => "application/json" }

          assert_response :unauthorized
        end
      end
    end
  end
end
