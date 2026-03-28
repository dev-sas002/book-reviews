RSpec.describe 'pagination' do
  let(:response_hash) { JSON(response.body, symbolize_names: true) }

  describe 'collection endpoints' do
    it 'advertises the page in response headers' do
      create_list(:book, 3)

      get api_books_path

      expect(response.headers['X-Total-Count']).to eq('3')
      expect(response.headers['X-Page']).to eq('1')
      expect(response.headers['X-Per-Page']).to eq(Pagination::DEFAULT_PER_PAGE.to_s)
      expect(response.headers['X-Total-Pages']).to eq('1')
    end

    it 'returns only the requested page' do
      books = create_list(:book, 3)

      get api_books_path, params: { page: 2, per_page: 2 }

      expect(response_hash.pluck(:id)).to eq([books.max_by(&:id).id])
      expect(response.headers['X-Total-Pages']).to eq('2')
    end

    it 'caps an oversized per_page' do
      create(:user)

      get api_users_path, params: { per_page: 5_000 }

      expect(response.headers['X-Per-Page']).to eq(Pagination::MAX_PER_PAGE.to_s)
    end
  end

  describe 'the reviews endpoint' do
    let(:book) { create(:book) }

    before do
      3.times { create(:review, reviewable: book, user: create(:user), rating: 4) }
    end

    it 'reports the page in the body as well as the headers' do
      get api_book_reviews_path(book, params: { page: 2, per_page: 2 })

      expect(response_hash[:meta]).to eq(page: 2, per_page: 2, total: 3, total_pages: 2)
      expect(response_hash[:reviews].size).to eq(1)
      expect(response.headers['X-Total-Count']).to eq('3')
    end

    it 'counts the filtered set, not the whole reviewable' do
      create(:review, reviewable: book, user: create(:user), rating: 1)

      get api_book_reviews_path(book, params: { rating: 1 })

      expect(response_hash[:meta][:total]).to eq(1)
    end
  end
end
