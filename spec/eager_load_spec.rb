# The test environment loads code lazily, so a file whose constant does not
# match its path would only fail on the first production boot. This loads
# everything once, the way production does.
RSpec.describe 'eager loading' do
  it 'loads every file under app/ and lib/ without a NameError' do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end
end
