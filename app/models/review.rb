class Review < ApplicationRecord
  # A deliberately fictional blocklist: the exercise asked for a profanity
  # filter, and a real one belongs behind a service, not in a constant.
  PROFANITY_WORDS = %w[frak storms gorram nerfherder crivens].freeze
  PROFANITY_REGEX = Regexp.new("\\b(?:#{PROFANITY_WORDS.join('|')})\\b", Regexp::IGNORECASE).freeze

  DESCRIPTION_MAX_LENGTH = 300
  RATING_RANGE = (1..5).freeze

  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  validates :rating, presence: true,
                     inclusion: { in: RATING_RANGE, message: 'rating should be in range of 1..5' }
  validates :reviewable_id, uniqueness: { scope: %i[reviewable_type user_id],
                                          message: "can't post multiple reviews" }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_nil: true

  before_validation :normalize_description

  validate :fictional_profanity

  # The rating counters on `books` are kept in step here rather than in the
  # controller so that every path that writes a review — the API, the seeds,
  # a console session, a cascading delete — keeps them correct. The policy
  # itself lives in RefreshBookRating; these are thin hooks.
  after_create :increment_rating_counters
  after_update :adjust_rating_counters, if: :saved_change_to_rating?
  after_destroy :decrement_rating_counters

  scope :descriptive_only, -> { where.not(description: [nil, '']) }

  private

  def fictional_profanity
    return if description.blank?
    return unless description.match?(PROFANITY_REGEX)

    errors.add(:description, 'cannot contain fictional profanity')
  end

  def normalize_description
    return if description.nil?

    self.description = description.strip
    self.description = nil if description.blank?
  end

  # Only books carry a rating column, so author reviews are skipped.
  def book_review?
    reviewable_type == 'Book'
  end

  def increment_rating_counters
    return unless book_review?

    RefreshBookRating.apply_delta(reviewable_id, count_delta: 1, sum_delta: rating)
  end

  def adjust_rating_counters
    return unless book_review?

    before, after = saved_change_to_rating
    RefreshBookRating.apply_delta(reviewable_id, count_delta: 0, sum_delta: after.to_i - before.to_i)
  end

  def decrement_rating_counters
    return unless book_review?
    # When the book itself is being destroyed its reviews cascade with it;
    # there is no point updating counters on a row that is about to disappear.
    return if destroyed_by_association&.active_record == Book

    RefreshBookRating.apply_delta(reviewable_id, count_delta: -1, sum_delta: -rating.to_i)
  end
end
