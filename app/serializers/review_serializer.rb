class ReviewSerializer < ApplicationSerializer
  def as_json
    {
      id: record.id,
      rating: record.rating,
      description: record.description,
      reviewable_type: record.reviewable_type,
      reviewable_id: record.reviewable_id,
      user_id: record.user_id,
      user: UserSerializer.summary(record.user),
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
