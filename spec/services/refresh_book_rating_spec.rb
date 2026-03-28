require 'rails_helper'

RSpec.describe RefreshBookRating do
  let(:book) { create(:book) }

  describe '.apply_delta' do
    it 'moves the counters and derives the average from them' do
      described_class.apply_delta(book.id, count_delta: 2, sum_delta: 9)

      book.reload
      expect(book.ratings_count).to eq(2)
      expect(book.ratings_sum).to eq(9)
      expect(book.rating).to eq(BigDecimal('4.5'))
    end

    it 'clears the average when the last review goes away' do
      create(:review, reviewable: book, user: create(:user), rating: 4).destroy!

      book.reload
      expect(book.ratings_count).to eq(0)
      expect(book.ratings_sum).to eq(0)
      expect(book.rating).to be_nil
    end

    it 'is a no-op for a nil book' do
      expect { described_class.apply_delta(nil, count_delta: 1, sum_delta: 1) }.not_to raise_error
    end

    it 'refuses a non-integer delta rather than interpolating it into SQL' do
      expect { described_class.apply_delta(book.id, count_delta: '1); DROP TABLE books; --', sum_delta: 1) }
        .to raise_error(ArgumentError)
    end
  end

  describe '.recalculate!' do
    it 'repairs counters that have drifted out of step with the reviews' do
      create(:review, reviewable: book, user: create(:user), rating: 5)
      create(:review, reviewable: book, user: create(:user), rating: 3)

      corrupt(book, ratings_count: 99, ratings_sum: 0, rating: 1)

      described_class.recalculate!(book)

      book.reload
      expect(book.ratings_count).to eq(2)
      expect(book.ratings_sum).to eq(8)
      expect(book.rating).to eq(4)
    end

    it 'zeroes a book that has no reviews' do
      corrupt(book, ratings_count: 4, ratings_sum: 12, rating: 3)

      described_class.recalculate!(book.id)

      book.reload
      expect(book.ratings_count).to eq(0)
      expect(book.rating).to be_nil
    end

    it 'repairs every book when called without an argument' do
      other = create(:book)
      create(:review, reviewable: other, user: create(:user), rating: 2)
      corrupt(other, ratings_count: 0, ratings_sum: 0, rating: 'NULL')

      described_class.recalculate!

      expect(other.reload.rating).to eq(2)
    end
  end

  # The counters are attr_readonly, which is the point: nothing in the
  # application can move them except RefreshBookRating. To test the repair path
  # the drift has to be introduced the way it would happen in real life — a
  # statement issued outside Active Record.
  def corrupt(book, ratings_count:, ratings_sum:, rating:)
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE books
      SET ratings_count = #{ratings_count.to_i},
          ratings_sum = #{ratings_sum.to_i},
          rating = #{rating.nil? || rating == 'NULL' ? 'NULL' : rating.to_i}
      WHERE id = #{book.id.to_i}
    SQL
  end
end
