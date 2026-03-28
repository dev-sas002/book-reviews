require 'rails_helper'

RSpec.describe ReviewsQuery do
  let(:book) { create(:book) }
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }

  def create_review(user:, rating:, description:)
    create(
      :review,
      reviewable: book,
      user: user,
      rating: rating,
      description: description
    )
  end

  def query(params = {})
    described_class.new(book, params).relation
  end

  describe '#relation' do
    it 'filters reviews to only those with descriptions when description_only is truthy' do
      create_review(user: user_1, rating: 3, description: nil)
      create_review(user: user_2, rating: 4, description: '')
      descriptive = create_review(user: user_3, rating: 5, description: 'Great book')

      expect(query(description_only: 'true')).to contain_exactly(descriptive)
    end

    it 'filters by exact rating when rating filter is provided' do
      create_review(user: user_1, rating: 2, description: 'Bad')
      create_review(user: user_2, rating: 4, description: 'Okay')
      create_review(user: user_3, rating: 4, description: 'Good')

      results = query(rating: 4)

      expect(results.pluck(:rating)).to all(eq(4))
      expect(results.count).to eq(2)
    end

    it 'sorts safely by whitelisted columns' do
      create_review(user: user_1, rating: 2, description: 'Low')
      create_review(user: user_2, rating: 5, description: 'High')
      create_review(user: user_3, rating: 3, description: 'Mid')

      results = query(sort_by: 'rating', order: 'desc').to_a

      expect(results.map(&:rating)).to eq([5, 3, 2])
    end

    it 'defaults to ascending order for invalid order directions' do
      create_review(user: user_1, rating: 1, description: 'One')
      create_review(user: user_2, rating: 5, description: 'Five')

      results = query(sort_by: 'rating', order: 'DESC;DROP TABLE reviews').to_a

      expect(results.map(&:rating)).to eq([1, 5])
    end

    it 'does not apply sorting when sort_by is not whitelisted (SQL injection safe)' do
      r1 = create_review(user: user_1, rating: 1, description: 'One')
      r2 = create_review(user: user_2, rating: 5, description: 'Five')

      results = query(sort_by: 'rating); DROP TABLE reviews; --', order: 'desc')

      # Without a whitelisted sort column, results should be the same record set
      # as the underlying association scope.
      expect(results.pluck(:id)).to match_array(book.reviews.pluck(:id))
      expect(results.pluck(:id)).to contain_exactly(r1.id, r2.id)
    end

    it 'returns reviews in a deterministic order when no sort is requested' do
      r1 = create_review(user: user_1, rating: 5, description: 'One')
      r2 = create_review(user: user_2, rating: 5, description: 'Two')
      r3 = create_review(user: user_3, rating: 5, description: 'Three')

      expect(query.to_a.map(&:id)).to eq([r1.id, r2.id, r3.id].sort)
    end

    it 'breaks ties on id so equal ratings come back in a stable order' do
      r1 = create_review(user: user_1, rating: 4, description: 'One')
      r2 = create_review(user: user_2, rating: 4, description: 'Two')

      results = query(sort_by: 'rating', order: 'desc').to_a

      expect(results.map(&:id)).to eq([r1.id, r2.id])
    end

    it 'sorts by created_at ascending by default for a whitelisted column' do
      older = create_review(user: user_1, rating: 2, description: 'Older')
      newer = create_review(user: user_2, rating: 5, description: 'Newer')
      older.update_column(:created_at, 2.days.ago)
      newer.update_column(:created_at, 1.day.ago)

      results = query(sort_by: 'created_at').to_a

      expect(results.map(&:id)).to eq([older.id, newer.id])
    end

    it 'does not filter when description_only is falsey' do
      create_review(user: user_1, rating: 3, description: nil)
      create_review(user: user_2, rating: 4, description: 'Has one')

      expect(query(description_only: 'false').count).to eq(2)
    end

    it 'ignores a non-numeric rating filter' do
      create_review(user: user_1, rating: 3, description: 'Ok')
      create_review(user: user_2, rating: 4, description: 'Good')

      expect(query(rating: 'not-a-number').count).to eq(2)
    end

    it 'ignores an out-of-range rating filter' do
      create_review(user: user_1, rating: 3, description: 'Ok')

      expect(query(rating: '9').count).to eq(1)
    end

    it 'accepts a zero padded rating and treats it as base 10' do
      create_review(user: user_1, rating: 3, description: 'Ok')
      four = create_review(user: user_2, rating: 4, description: 'Good')

      expect(query(rating: '04').pluck(:id)).to eq([four.id])
    end

    it 'combines description_only, rating and sorting' do
      create_review(user: user_1, rating: 4, description: nil)
      kept = create_review(user: user_2, rating: 4, description: 'Kept')
      create_review(user: user_3, rating: 2, description: 'Wrong rating')

      results = query(sort_by: 'rating', order: 'desc', description_only: 'true', rating: 4)

      expect(results.pluck(:id)).to eq([kept.id])
    end

    it 'accepts ActionController::Parameters as well as a hash' do
      create_review(user: user_1, rating: 2, description: 'Low')
      high = create_review(user: user_2, rating: 5, description: 'High')

      params = ActionController::Parameters.new(rating: '5').permit(:rating)

      expect(described_class.new(book, params).relation.pluck(:id)).to eq([high.id])
    end

    it 'only issues one query for the users of a page of reviews' do
      3.times { create(:review, reviewable: book, user: create(:user), rating: 4) }

      queries = count_queries { described_class.new(book, {}).relation.map { |r| r.user.first_name } }

      # One SELECT for the reviews, one for the users.
      expect(queries).to eq(2)
    end
  end

  describe '#applied_sort' do
    it 'reports the default sort' do
      expect(described_class.new(book, {}).applied_sort).to eq([:id, 'asc'])
    end

    it 'reports a requested sort' do
      expect(described_class.new(book, sort_by: 'rating', order: 'desc').applied_sort)
        .to eq([:rating, 'desc'])
    end
  end

  describe 'the filter registry' do
    after { ReviewFilters.reset! }

    it 'applies a filter registered at runtime without changing the query object' do
      low = create_review(user: user_1, rating: 1, description: 'Low')
      create_review(user: user_2, rating: 5, description: 'High')

      minimum_rating = Class.new do
        def param_name
          :max_rating
        end

        def apply(scope, value)
          value.present? ? scope.where(reviews: { rating: ..value.to_i }) : scope
        end
      end

      ReviewFilters.register(minimum_rating.new)

      expect(ReviewFilters.param_names).to include(:max_rating)
      expect(query(max_rating: 2).pluck(:id)).to eq([low.id])
    end

    it 'rejects an object that does not implement the filter interface' do
      expect { ReviewFilters.register(Object.new) }.to raise_error(ArgumentError)
    end
  end

  def count_queries(&block)
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION CACHE])
    end

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
    count
  end
end
