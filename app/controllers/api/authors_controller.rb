module API
  class AuthorsController < BaseController
    private

    def resource_class
      Author
    end

    def serializer_class
      AuthorSerializer
    end

    def allowed_params
      params.permit(
        :description,
        :first_name,
        :last_name,
        :website,
        genres: []
      )
    end
  end
end
