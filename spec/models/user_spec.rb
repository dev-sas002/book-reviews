require 'rails_helper'

RSpec.describe User, type: :model do
  it 'validates presence of first_name' do
    user = build(:user, first_name: nil)
    user.valid?

    expect(user.errors[:first_name]).to be_present
  end

  it 'validates presence of last_name' do
    user = build(:user, last_name: nil)
    user.valid?

    expect(user.errors[:last_name]).to be_present
  end

  it 'is valid with a first and last name' do
    expect(build(:user)).to be_valid
  end

  it 'has many reviews' do
    user = create(:user)

    create(:review, reviewable: create(:book), user: user, rating: 4)
    create(:review, reviewable: create(:author), user: user, rating: 2)

    expect(user.reviews.count).to eq(2)
  end

  it 'destroys its reviews when destroyed so none are left orphaned' do
    user = create(:user)
    review = create(:review, reviewable: create(:book), user: user, rating: 4)

    expect { user.destroy }.to change { Review.where(id: review.id).count }.from(1).to(0)
  end
end
