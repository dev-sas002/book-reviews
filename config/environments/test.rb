Rails.application.configure do
  config.enable_reloading = false

  # spec/eager_load_spec.rb loads the whole app once instead.
  config.eager_load = false

  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.hour.to_i}" }

  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Let exceptions the controllers do not rescue reach the spec.
  config.action_dispatch.show_exceptions = :none

  config.action_controller.allow_forgery_protection = false

  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'example.com' }

  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise

  config.action_controller.raise_on_missing_callback_actions = true
end
