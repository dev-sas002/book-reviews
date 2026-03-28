require 'rails_helper'

RSpec.describe Pagination do
  let(:book) { create(:book) }

  before do
    5.times { create(:review, reviewable: book, user: create(:user), rating: 3) }
  end

  def paginate(page: nil, per_page: nil)
    described_class.new(book.reviews.order(:id), page: page, per_page: per_page)
  end

  it 'defaults to the first page at the default page size' do
    pagination = paginate

    expect(pagination.page).to eq(1)
    expect(pagination.per_page).to eq(described_class::DEFAULT_PER_PAGE)
    expect(pagination.records.size).to eq(5)
  end

  it 'limits and offsets the scope' do
    pagination = paginate(page: 2, per_page: 2)

    expect(pagination.records.pluck(:id)).to eq(book.reviews.order(:id).pluck(:id)[2, 2])
  end

  it 'reports totals from the unpaged scope' do
    pagination = paginate(page: 2, per_page: 2)

    expect(pagination.total).to eq(5)
    expect(pagination.total_pages).to eq(3)
    expect(pagination.to_h).to eq(page: 2, per_page: 2, total: 5, total_pages: 3)
  end

  it 'caps per_page so a client cannot ask for the whole table' do
    expect(paginate(per_page: 10_000).per_page).to eq(described_class::MAX_PER_PAGE)
  end

  it 'floors page and per_page at 1' do
    pagination = paginate(page: -3, per_page: 0)

    expect(pagination.page).to eq(1)
    expect(pagination.per_page).to eq(1)
  end

  it 'falls back to the defaults for junk input' do
    pagination = paginate(page: 'two', per_page: 'lots')

    expect(pagination.page).to eq(1)
    expect(pagination.per_page).to eq(described_class::DEFAULT_PER_PAGE)
  end

  it 'reports one page when the scope is empty' do
    pagination = described_class.new(Review.none, page: nil, per_page: nil)

    expect(pagination.total).to eq(0)
    expect(pagination.total_pages).to eq(1)
  end
end
