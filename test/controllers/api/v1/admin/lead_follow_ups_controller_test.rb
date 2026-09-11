require "test_helper"

module Api
  module V1
    module Admin
      class LeadFollowUpsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 FLCtrl", subdomain: "b1-flctrl", code: "B1FLCTRL-100", status: "active")
          @counselor_role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant1)
          @counselor = User.create!(tenant: @tenant1, role: @counselor_role, first_name: "C1", email: "c1_flctrl@example.com", password: "password123")
          @token = Authentication::JwtService.issue_access_token(@counselor)

          @lead = Lead.create!(tenant: @tenant1, name: "Lead Alpha")
          @flw = LeadFollowUp.create!(tenant: @tenant1, lead: @lead, user: @counselor, follow_up_at: 1.day.from_now, notes: "Initial call")
        end

        test "counselor can list and create follow ups" do
          get api_v1_admin_lead_follow_ups_url(@lead.id),
              headers: { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length

          post api_v1_admin_lead_follow_ups_url(@lead.id),
               params: {
                 follow_up: {
                   follow_up_at: 2.days.from_now.iso8601,
                   notes: "Second call"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token}" },
               as: :json

          assert_response :created
          json2 = JSON.parse(response.body)
          assert json2["success"]
          assert_equal "Second call", json2["data"]["notes"]
        end
      end
    end
  end
end
