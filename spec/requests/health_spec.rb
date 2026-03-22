RSpec.describe 'GET /health' do
  let(:response_hash) { JSON(response.body, symbolize_names: true) }

  it 'reports ok when the database is reachable' do
    get '/health'

    expect(response).to have_http_status(:ok)
    expect(response_hash).to eq(status: 'ok', database: 'ok')
  end

  it 'reports service unavailable when the database is not reachable' do
    connection = ActiveRecord::Base.connection
    allow(connection).to receive(:execute).and_call_original
    allow(connection).to receive(:execute).with('SELECT 1').and_raise(
      ActiveRecord::StatementInvalid.new('connection is closed')
    )

    get '/health'

    expect(response).to have_http_status(:service_unavailable)
    expect(response_hash[:status]).to eq('error')
  end
end
