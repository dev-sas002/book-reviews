class AddRatingCountersToBooks < ActiveRecord::Migration[6.1]
  def up
    change_table :books, bulk: true do |t|
      t.integer :ratings_count, null: false, default: 0
      t.integer :ratings_sum, null: false, default: 0
    end

    say_with_time 'backfilling rating counters from reviews' do
      execute(<<~SQL.squish)
        UPDATE books
        SET ratings_count = COALESCE(agg.count, 0),
            ratings_sum   = COALESCE(agg.sum, 0),
            rating        = agg.avg
        FROM (SELECT id FROM books) AS target
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

  def down
    change_table :books, bulk: true do |t|
      t.remove :ratings_sum
      t.remove :ratings_count
    end
  end
end
