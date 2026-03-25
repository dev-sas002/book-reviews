# Creates a review against a book or an author.
#
# The controller's job is HTTP: find the reviewable, permit parameters, choose
# a status code. Deciding what "creating a review" means — including that a
# duplicate lost at the database index is the same 422 as a duplicate caught by
# the validation — is this object's job.
class CreateReview
  DUPLICATE_MESSAGE = "Reviewable can't post multiple reviews".freeze

  def initialize(reviewable, attributes)
    @reviewable = reviewable
    @attributes = attributes
  end

  def call
    review = @reviewable.reviews.new(@attributes)

    return ServiceResult.success(review) if review.save

    ServiceResult.failure(review.errors.full_messages, review)
  rescue ActiveRecord::RecordNotUnique
    # Two concurrent requests can both pass the uniqueness validation; the
    # unique index is the real guard, so translate it into the same 422 the
    # validation would have produced.
    ServiceResult.failure([DUPLICATE_MESSAGE])
  end
end
