source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'bootsnap', require: false
gem 'pg', '~> 1.6'
gem 'puma', '>= 7.0'
gem 'rails', '~> 8.1.0'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'faker', '~> 3.5'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]
