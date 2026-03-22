require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # Log to STDOUT with the request id on every line, as a container expects.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Keep the health probe out of the request log.
  config.silence_healthcheck_path = '/health'

  config.active_support.report_deprecations = false

  config.i18n.fallbacks = true

  config.active_record.dump_schema_after_migration = false
  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]
end
