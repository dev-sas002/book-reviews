class BookSerializer < ApplicationSerializer
  RATING_DECIMAL_PLACES = 2

  def as_json
    {
      id: record.id,
      title: record.title,
      description: record.description,
      publish_date: record.publish_date,
      # `rating` is the average of the book's review ratings and is maintained
      # by the application (see RefreshBookRating); clients cannot write it.
      #
      # The column is an unconstrained `numeric`, which Rails renders as a JSON
      # *string* of every digit Postgres produced ("4.6666666666666667"). The
      # wire format is this layer's decision, not the column type's: an average
      # of a 1-5 scale is published as a number rounded to two places. The
      # exact values stay in `ratings_sum` and `ratings_count`.
      rating: record.rating&.round(RATING_DECIMAL_PLACES)&.to_f,
      ratings_count: record.ratings_count,
      author_id: record.author_id,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
