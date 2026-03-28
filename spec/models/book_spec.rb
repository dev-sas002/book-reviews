require 'rails_helper'

RSpec.describe Book, type: :model do
  it 'validates presence of title' do
    book = build(:book, title: nil)
    book.valid?

    expect(book.errors[:title]).to be_present
  end

  it 'validates presence of description' do
    book = build(:book, description: nil)
    book.valid?

    expect(book.errors[:description]).to be_present
  end

  it 'has many reviews via reviewable polymorphic association' do
    book = create(:book)
    user = create(:user)

    create(:review, reviewable: book, user: user, rating: 4, description: 'Nice')

    expect(book.reviews.count).to eq(1)
  end

  it 'destroys associated reviews when the book is destroyed' do
    book = create(:book)
    user = create(:user)

    review = create(:review, reviewable: book, user: user, rating: 4, description: 'Nice')

    expect { book.destroy }.to change { Review.where(id: review.id).count }.from(1).to(0)
  end
end
