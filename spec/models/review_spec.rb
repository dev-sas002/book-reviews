require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'validations' do
    it 'requires rating in the range 1..5' do
      book = create(:book)
      user = create(:user)

      review = build(:review, reviewable: book, user: user, rating: 0, description: 'Nice')

      review.valid?

      expect(review.errors[:rating]).to include('rating should be in range of 1..5')
    end

    it 'requires a rating' do
      review = build(:review, reviewable: create(:book), user: create(:user), rating: nil)

      review.valid?

      expect(review.errors[:rating]).to be_present
    end

    it 'rejects ratings above 5' do
      review = build(:review, reviewable: create(:book), user: create(:user), rating: 6)

      review.valid?

      expect(review.errors[:rating]).to include('rating should be in range of 1..5')
    end

    it 'accepts every whole rating from 1 to 5' do
      book = create(:book)

      (1..5).each do |rating|
        review = build(:review, reviewable: book, user: create(:user), rating: rating)

        expect(review).to be_valid, "expected rating #{rating} to be valid"
      end
    end

    it 'allows a nil description' do
      review = build(:review, reviewable: create(:book), user: create(:user), rating: 3, description: nil)

      expect(review).to be_valid
    end

    it 'allows a description of exactly 300 characters' do
      review = build(
        :review,
        reviewable: create(:book),
        user: create(:user),
        rating: 3,
        description: 'a' * 300
      )

      expect(review).to be_valid
    end

    it 'validates description max length (300 chars)' do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: 'a' * 301
      )

      review.valid?

      expect(review.errors[:description]).to include('is too long (maximum is 300 characters)')
    end
  end

  describe 'description normalization' do
    it 'turns whitespace-only descriptions into nil' do
      book = create(:book)
      user = create(:user)

      review = build(:review, reviewable: book, user: user, rating: 3, description: '   ')
      review.valid?

      expect(review.description).to be_nil
      expect(review).to be_valid
    end
  end

  describe 'fictional profanity validation' do
    it 'rejects fictional profanity case-insensitively with punctuation' do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: 'I shouted Frak, loudly.'
      )

      review.valid?

      expect(review.errors[:description]).to include('cannot contain fictional profanity')
    end

    it 'rejects every configured profanity word' do
      book = create(:book)

      Review::PROFANITY_WORDS.each do |word|
        review = build(
          :review,
          reviewable: book,
          user: create(:user),
          rating: 3,
          description: "That is #{word} awful"
        )

        review.valid?

        expect(review.errors[:description])
          .to include('cannot contain fictional profanity'), "expected #{word} to be rejected"
      end
    end

    it 'allows words that only contain the profanity fragment' do
      book = create(:book)
      user = create(:user)

      review = build(
        :review,
        reviewable: book,
        user: user,
        rating: 3,
        description: 'This is fraking behavior, not fraking itself.'
      )

      expect(review).to be_valid
    end
  end

  describe 'callbacks' do
    it 'updates the average rating for books after creating a review' do
      book = create(:book, rating: nil)
      user_1 = create(:user)
      user_2 = create(:user)

      create(:review, reviewable: book, user: user_1, rating: 2, description: 'Good')
      expect(book.reload.rating.to_d).to eq(2.to_d)

      create(:review, reviewable: book, user: user_2, rating: 4, description: 'Great')
      expect(book.reload.rating.to_d).to eq(3.to_d)
    end

    it 'recomputes the average from the reviews even when the stored rating is stale' do
      book = create(:book, rating: nil)

      create(:review, reviewable: book, user: create(:user), rating: 1, description: 'Bad')
      book.update!(rating: 5) # stale value written outside of the review flow

      create(:review, reviewable: book, user: create(:user), rating: 1, description: 'Also bad')

      expect(book.reload.rating).to eq(1)
    end

    it 'does not accumulate rounding error across non-terminating averages' do
      book = create(:book, rating: nil)

      [1, 2, 4].each { |rating| create(:review, reviewable: book, user: create(:user), rating: rating) }
      expect(book.reload.rating.round(4)).to eq(BigDecimal('2.3333'))

      create(:review, reviewable: book, user: create(:user), rating: 5)

      expect(book.reload.rating).to eq(3)
    end

    it 'does not attempt to store a rating for author reviews' do
      author = create(:author)

      expect { create(:review, reviewable: author, user: create(:user), rating: 4) }
        .not_to raise_error

      expect(author.reviews.count).to eq(1)
    end
  end

  describe 'uniqueness' do
    it 'allows only one review per user per reviewable' do
      book = create(:book)
      user = create(:user)

      create(:review, reviewable: book, user: user, rating: 3, description: 'Nice')

      duplicate = build(:review, reviewable: book, user: user, rating: 4, description: 'Another')
      duplicate.valid?

      expect(duplicate).to be_invalid
      expect(duplicate.errors.full_messages.join(' ')).to include("can't post multiple reviews")
    end

    it 'lets the same user review a book and an author with the same id' do
      user = create(:user)
      book = create(:book)
      author = create(:author)

      create(:review, reviewable: book, user: user, rating: 3)
      author_review = build(:review, reviewable: author, user: user, rating: 3)

      expect(author_review).to be_valid
    end

    it 'lets the same user review two different books' do
      user = create(:user)
      create(:review, reviewable: create(:book), user: user, rating: 3)

      expect(build(:review, reviewable: create(:book), user: user, rating: 5)).to be_valid
    end
  end

  describe 'rating counters' do
    it 'keeps ratings_count and ratings_sum in step with the reviews' do
      book = create(:book)

      create(:review, reviewable: book, user: create(:user), rating: 5)
      create(:review, reviewable: book, user: create(:user), rating: 2)

      book.reload
      expect(book.ratings_count).to eq(2)
      expect(book.ratings_sum).to eq(7)
      expect(book.rating).to eq(BigDecimal('3.5'))
    end

    it "adjusts the average when a review's rating is changed" do
      book = create(:book)
      review = create(:review, reviewable: book, user: create(:user), rating: 1)

      review.update!(rating: 5)

      book.reload
      expect(book.ratings_count).to eq(1)
      expect(book.ratings_sum).to eq(5)
      expect(book.rating).to eq(5)
    end

    it 'leaves the counters alone when a review is edited without touching the rating' do
      book = create(:book)
      review = create(:review, reviewable: book, user: create(:user), rating: 4)

      review.update!(description: 'Revised thoughts')

      expect(book.reload.ratings_sum).to eq(4)
    end

    it 'removes a destroyed review from the average' do
      book = create(:book)
      kept = create(:review, reviewable: book, user: create(:user), rating: 2)
      create(:review, reviewable: book, user: create(:user), rating: 4).destroy!

      book.reload
      expect(book.ratings_count).to eq(1)
      expect(book.rating).to eq(kept.rating)
    end

    it "removes a user's reviews from the average when the user is deleted" do
      book = create(:book)
      user = create(:user)
      create(:review, reviewable: book, user: user, rating: 1)
      create(:review, reviewable: book, user: create(:user), rating: 5)

      user.destroy!

      book.reload
      expect(book.ratings_count).to eq(1)
      expect(book.rating).to eq(5)
    end

    it 'does not touch counters for author reviews' do
      book = create(:book)
      create(:review, reviewable: book, user: create(:user), rating: 3)
      author = create(:author)

      expect do
        create(:review, reviewable: author, user: create(:user), rating: 4)
      end.not_to(change { book.reload.attributes.values_at('rating', 'ratings_count', 'ratings_sum') })
    end
  end
end
