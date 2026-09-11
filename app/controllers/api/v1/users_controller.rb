module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show, :update, :destroy ]

      def index
        authorize User
        users = policy_scope(User)
        render_success(data: UserBlueprint.render_as_hash(users, view: :with_associations))
      end

      def show
        authorize @user
        render_success(data: UserBlueprint.render_as_hash(@user, view: :with_associations))
      end

      def create
        attrs = user_params
        attrs[:tenant_id] = Current.user.tenant_id if Current.user&.tenant_id.present?

        @user = User.new(attrs)
        authorize @user
        @user.save!
        render_success(data: UserBlueprint.render_as_hash(@user, view: :with_associations), status: :created)
      end

      def update
        attrs = user_params
        attrs.delete(:tenant_id) if Current.user&.tenant_id.present?

        @user.assign_attributes(attrs)
        authorize @user
        @user.save!
        render_success(data: UserBlueprint.render_as_hash(@user, view: :with_associations))
      end

      def destroy
        authorize @user
        @user.destroy!
        render_success(data: { message: "User deleted successfully" })
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :password,
          :phone,
          :status,
          :role_id,
          :tenant_id
        )
      end
    end
  end
end
