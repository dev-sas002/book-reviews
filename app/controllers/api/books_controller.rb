module API
  class BooksController < BaseController
    private

    def resource_class
      Book
    end

    def serializer_class
      BookSerializer
    end

    # NOTE: :rating, :ratings_count and :ratings_sum are deliberately not
    # permitted. They are derived from the book's reviews and are maintained by
    # RefreshBookRating; letting a client send them would let anyone set a
    # book's score to five stars without writing a review.
    def allowed_params
      params.permit(
        :author_id,
        :description,
        :publish_date,
        :title
      )
    end
  end
end
