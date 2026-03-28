require 'rails_helper'

RSpec.describe CreateReview do
  let(:book) { create(:book) }
  let(:user) { create(:user) }

  it 'creates the review and returns it on success' do
    result = described_class.new(book, user_id: user.id, rating: 4, description: 'Good').call

    expect(result).to be_success
    expect(result.value).to be_persisted
    expect(result.value.reviewable).to eq(book)
    expect(result.errors).to be_empty
  end

  it 'returns the validation messages on failure without persisting' do
    result = nil

    expect do
      result = described_class.new(book, user_id: user.id, rating: 9).call
    end.not_to change(Review, :count)

    expect(result).to be_failure
    expect(result.errors).to include('Rating rating should be in range of 1..5')
  end

  it 'translates a unique index violation into the same duplicate message' do
    allow_any_instance_of(Review).to receive(:save).and_raise(
      ActiveRecord::RecordNotUnique.new('duplicate key value violates unique constraint')
    )

    result = described_class.new(book, user_id: user.id, rating: 4).call

    expect(result).to be_failure
    expect(result.errors).to eq([described_class::DUPLICATE_MESSAGE])
  end

  it 'works against an author as well as a book' do
    author = create(:author)

    result = described_class.new(author, user_id: user.id, rating: 5).call

    expect(result).to be_success
    expect(result.value.reviewable_type).to eq('Author')
  end
end
