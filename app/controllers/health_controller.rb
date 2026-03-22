# Liveness/readiness probe used by the Docker healthcheck.
#
# It checks the database connection as well as the process, because a Rails
# process that cannot reach Postgres is up but useless.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.with_connection { |connection| connection.select_value('SELECT 1') }

    render json: { status: 'ok', database: 'ok' }, status: :ok
  rescue StandardError => e
    render json: { status: 'error', database: e.class.name }, status: :service_unavailable
  end
end
