module API
  class UsersController < BaseController
    private

    def resource_class
      User
    end

    def serializer_class
      UserSerializer
    end

    def allowed_params
      params.permit(
        :first_name,
        :last_name
      )
    end
  end
end
