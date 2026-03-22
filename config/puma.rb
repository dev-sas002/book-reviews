# One thread count for Puma and the Active Record pool (config/database.yml
# reads the same variable), so a request never waits for a connection.
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

port ENV.fetch('PORT', 3000)

# Allow puma to be restarted by `bin/rails restart`.
plugin :tmp_restart

pidfile ENV['PIDFILE'] if ENV['PIDFILE']
