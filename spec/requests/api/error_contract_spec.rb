RSpec.describe 'the API error contract' do
  let(:response_hash) { JSON(response.body, symbolize_names: true) }

  it 'returns a JSON body for a missing book' do
    get api_book_path(-1)

    expect(response).to have_http_status(:not_found)
    expect(response_hash).to eq(errors: ['Resource not found'])
  end

  it 'returns a JSON body for a missing author' do
    get api_author_path(-1)

    expect(response_hash).to eq(errors: ['Resource not found'])
  end

  it 'returns a JSON body for a missing user' do
    get api_user_path(-1)

    expect(response_hash).to eq(errors: ['Resource not found'])
  end

  it 'returns a JSON body for reviews of a missing reviewable' do
    get api_book_reviews_path(-1)

    expect(response).to have_http_status(:not_found)
    expect(response_hash).to eq(errors: ['Resource not found'])
  end

  it 'answers a malformed JSON body with 400 in the same envelope' do
    post api_users_path, params: '{"first_name": "Ada",', headers: { 'CONTENT_TYPE' => 'application/json' }

    expect(response).to have_http_status(:bad_request)
    expect(response_hash).to eq(errors: ['Request body is not valid JSON'])
  end

  it 'uses the same envelope for validation failures' do
    post api_users_path, params: { first_name: 'Ada' }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response_hash[:errors]).to be_an(Array)
  end
end
