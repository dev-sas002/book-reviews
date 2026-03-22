class Book < ApplicationRecord
  include Reviewable

  belongs_to :author

  validates :title, :description, presence: true
  validate :publish_date_parses

  # `rating`, `ratings_count` and `ratings_sum` are derived from the book's
  # reviews and are never written by clients. See RefreshBookRating.
  attr_readonly :ratings_count, :ratings_sum

  private

  # A date column casts anything it cannot parse to nil, so without this an
  # update with publish_date=soon would silently erase the stored date.
  def publish_date_parses
    return if publish_date.present? || publish_date_before_type_cast.blank?

    errors.add(:publish_date, 'is not a valid date')
  end
end
