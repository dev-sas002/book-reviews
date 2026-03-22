module API
  class ReviewsController < ApplicationController
    before_action :set_reviewable

    def index
      page = paginate(ReviewsQuery.new(@reviewable, index_params).relation)

      render json: {
        reviews: ReviewSerializer.many(page.records),
        meta: page.to_h
      }, status: :ok
    end

    def create
      result = CreateReview.new(@reviewable, review_params).call

      if result.success?
        render json: { message: 'success' }, status: :created
      else
        render_errors(result.errors)
      end
    end

    private

    def set_reviewable
      # Dispatch on the nested route segment only. Falling back to the other
      # id would let `/api/books/<missing>/reviews?author_id=1` operate on an
      # author, which is not what the URL says.
      @reviewable =
        if params[:book_id].present?
          Book.find(params[:book_id])
        elsif params[:author_id].present?
          Author.find(params[:author_id])
        end

      raise ActiveRecord::RecordNotFound unless @reviewable
    end

    def index_params
      params.permit(*ReviewFilters.param_names, :sort_by, :order)
    end

    def review_params
      params.permit(
        :user_id,
        :rating,
        :description
      )
    end
  end
end
