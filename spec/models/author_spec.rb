require 'rails_helper'

RSpec.describe Author, type: :model do
  it 'validates presence of description' do
    author = build(:author, description: nil)
    author.valid?

    expect(author.errors[:description]).to be_present
  end

  it 'has many reviews via reviewable polymorphic association' do
    author = create(:author)
    user = create(:user)

    create(:review, reviewable: author, user: user, rating: 5, description: 'Great')

    expect(author.reviews.count).to eq(1)
  end

  it 'destroys associated books when the author is destroyed' do
    author = create(:author)
    book = create(:book, author: author)
    expect { author.destroy }.to change { Book.where(id: book.id).count }.from(1).to(0)
  end
end
