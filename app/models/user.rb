class User < ApplicationRecord
  validates :first_name, :last_name, presence: true

  # reviews.user_id has no database foreign key, so without this the reviews of
  # a deleted user would be left pointing at a missing row.
  has_many :reviews, dependent: :destroy
end
