require 'rails_helper'

RSpec.describe 'serializers' do
  describe ApplicationSerializer do
    it 'serializes nil to nil' do
      expect(described_class.one(nil)).to be_nil
    end

    it 'refuses to serialize without a subclass implementation' do
      expect { described_class.one(build(:user)) }.to raise_error(NotImplementedError)
    end
  end

  describe BookSerializer do
    it 'exposes exactly the book attributes the API documents' do
      book = create(:book, publish_date: '1968-11-01')

      expect(described_class.one(book).keys).to eq(
        %i[id title description publish_date rating ratings_count author_id created_at updated_at]
      )
    end

    it 'does not leak the ratings_sum implementation detail' do
      expect(described_class.one(create(:book))).not_to have_key(:ratings_sum)
    end

    it 'publishes the average rating as a number rounded to two places' do
      book = create(:book)
      3.times { |i| create(:review, reviewable: book, user: create(:user), rating: [5, 5, 4][i]) }

      payload = described_class.one(book.reload)

      # Not the raw numeric column, which renders as the string "4.6666666666666667".
      expect(payload[:rating]).to eq(4.67)
      expect(payload[:rating]).to be_a(Float)
    end

    it 'publishes a nil rating for a book with no reviews' do
      expect(described_class.one(create(:book))[:rating]).to be_nil
    end
  end

  describe ReviewSerializer do
    it 'embeds a compact user rather than the whole record' do
      review = create(:review)

      payload = described_class.one(review)

      expect(payload[:user]).to eq(
        id: review.user.id,
        first_name: review.user.first_name,
        last_name: review.user.last_name
      )
      expect(payload[:user]).not_to have_key(:created_at)
    end
  end

  describe UserSerializer do
    it 'summarises a nil user as nil' do
      expect(described_class.summary(nil)).to be_nil
    end
  end

  describe AuthorSerializer do
    it 'exposes the author attributes the API documents' do
      author = create(:author, genres: %w[fantasy])

      expect(described_class.one(author)).to include(
        genres: %w[fantasy],
        first_name: author.first_name
      )
    end
  end
end
