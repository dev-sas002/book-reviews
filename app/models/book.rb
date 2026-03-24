class Book < ApplicationRecord
  include Reviewable

  belongs_to :author

  validates :title, :description, presence: true

  # `rating`, `ratings_count` and `ratings_sum` are derived from the book's
  # reviews and are never written by clients. See RefreshBookRating.
  attr_readonly :ratings_count, :ratings_sum
end
