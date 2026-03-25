class AddFilterAndSortIndexesToReviews < ActiveRecord::Migration[6.1]
  # The reviews index endpoint always narrows to one reviewable and then
  # filters by rating and/or sorts. These two composite indexes let Postgres
  # answer both shapes from the index instead of scanning the reviewable's
  # rows and sorting them. `id` is the tie-breaker the query object always
  # appends, so including it keeps the ordering index-only.
  def change
    add_index :reviews,
              %i[reviewable_type reviewable_id rating id],
              name: 'index_reviews_on_reviewable_and_rating'

    add_index :reviews,
              %i[reviewable_type reviewable_id created_at id],
              name: 'index_reviews_on_reviewable_and_created_at'

    # Redundant now: both indexes above start with the same two columns, so
    # anything this could serve they can serve too, and every insert was
    # paying for it.
    remove_index :reviews,
                 column: %i[reviewable_type reviewable_id],
                 name: 'index_reviews_on_reviewable'
  end
end
