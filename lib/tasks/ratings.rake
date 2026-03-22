namespace :ratings do
  desc 'Recompute books.rating, ratings_count and ratings_sum from the reviews table'
  task recalculate: :environment do
    updated = RefreshBookRating.recalculate!
    puts "Recalculated rating counters for #{updated} book(s)."
  end
end
