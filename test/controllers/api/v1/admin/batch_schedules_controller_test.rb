require "test_helper"

module Api
  module V1
    module Admin
      class BatchSchedulesControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 SchCtrl", subdomain: "b1-sch-ctrl", code: "B1SCHCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 SchCtrl", subdomain: "b2-sch-ctrl", code: "B2SCHCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)

          @branch_admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_schctrl@example.com", password: "password123")
          @branch_admin2 = User.create!(tenant: @tenant2, role: @admin_role2, first_name: "Admin2", email: "admin2_schctrl@example.com", password: "password123")

          @token1 = Authentication::JwtService.issue_access_token(@branch_admin1)
          @token2 = Authentication::JwtService.issue_access_token(@branch_admin2)

          @course1 = Course.create!(tenant: @tenant1, name: "Course 1", code: "C1")
          @course2 = Course.create!(tenant: @tenant2, name: "Course 2", code: "C2")

          @batch1 = Batch.create!(tenant: @tenant1, course: @course1, name: "Batch 1", code: "B1", start_date: Date.today)
          @batch2 = Batch.create!(tenant: @tenant2, course: @course2, name: "Batch 2", code: "B2", start_date: Date.today)

          @schedule1 = BatchSchedule.create!(
            tenant: @tenant1,
            batch: @batch1,
            weekday: 1,
            start_time: "09:00",
            end_time: "11:00",
            room_name: "Lab A"
          )
        end

        test "admin can list batch schedules" do
          get api_v1_admin_batch_schedules_url(@batch1.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "Lab A", json["data"].first["room_name"]
        end

        test "admin can create batch schedule" do
          post api_v1_admin_batch_schedules_url(@batch1.id),
               params: {
                 batch_schedule: {
                   weekday: 3,
                   start_time: "14:00",
                   end_time: "16:00",
                   room_name: "Lab B"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 3, json["data"]["weekday"]
          assert_equal "14:00", json["data"]["start_time"]
        end

        test "admin cannot create schedule for another tenant batch" do
          post api_v1_admin_batch_schedules_url(@batch2.id),
               params: {
                 batch_schedule: {
                   weekday: 2,
                   start_time: "10:00",
                   end_time: "12:00"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :not_found
        end

        test "admin can delete own batch schedule" do
          delete api_v1_admin_batch_schedule_url(@batch1.id, @schedule1.id),
                 headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          assert_nil BatchSchedule.find_by(id: @schedule1.id)
        end
      end
    end
  end
end
