# Maintains the denormalised rating columns on `books`.
#
# A book's `rating` is the average of its review ratings. The obvious
# implementation — `AVG(rating)` over the book's reviews after every write —
# is correct but O(number of reviews) on the write path, so the most reviewed
# book is also the slowest one to review. Instead the book carries
# `ratings_count` and `ratings_sum`, both exact integers, and each write
# applies a delta to them in a single UPDATE. The average is derived from those
# two columns in the same statement, so it can never drift the way an
# incrementally averaged float does.
#
# `recalculate!` recomputes the counters from the reviews table. It is the
# repair path (see `lib/tasks/ratings.rake`) and is what the seeds use after
# inserting reviews in bulk.
class RefreshBookRating
  DELTA_SQL = <<~SQL.squish.freeze
    ratings_count = books.ratings_count + ?,
    ratings_sum   = books.ratings_sum + ?,
    rating = CASE
               WHEN books.ratings_count + ? > 0
               THEN (books.ratings_sum + ?)::decimal / (books.ratings_count + ?)
               ELSE NULL
             END
  SQL

  class << self
    # Applies a change of `count_delta` reviews totalling `sum_delta` rating
    # points to the book. Both deltas may be negative.
    def apply_delta(book_id, count_delta:, sum_delta:)
      return 0 if book_id.nil?

      # Coerced before anything is built: these values end up in a SQL
      # fragment, so a non-integer must fail loudly rather than be interpolated.
      count_delta = Integer(count_delta)
      sum_delta = Integer(sum_delta)
      return 0 if count_delta.zero? && sum_delta.zero?

      assignments = ActiveRecord::Base.sanitize_sql_array(
        [DELTA_SQL, count_delta, sum_delta, count_delta, sum_delta, count_delta]
      )

      Book.where(id: book_id).update_all(assignments)
    end

    # Recomputes the counters and the average from the reviews themselves.
    # Returns the number of book rows touched.
    def recalculate!(book_or_id = nil)
      scope = Book.all
      scope = scope.where(id: id_for(book_or_id)) unless book_or_id.nil?

      ActiveRecord::Base.connection.update(recalculate_sql(scope))
    end

    private

    def id_for(book_or_id)
      book_or_id.respond_to?(:id) ? book_or_id.id : book_or_id
    end

    def recalculate_sql(scope)
      <<~SQL.squish
        UPDATE books
        SET ratings_count = COALESCE(agg.count, 0),
            ratings_sum   = COALESCE(agg.sum, 0),
            rating        = agg.avg
        FROM (#{scope.select(:id).to_sql}) AS target
        LEFT JOIN LATERAL (
          SELECT COUNT(*) AS count, SUM(rating) AS sum, AVG(rating) AS avg
          FROM reviews
          WHERE reviews.reviewable_type = 'Book'
            AND reviews.reviewable_id = target.id
        ) AS agg ON TRUE
        WHERE books.id = target.id
      SQL
    end
  end
end
