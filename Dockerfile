# syntax=docker/dockerfile:1

# Keep in step with .ruby-version; the Gemfile reads that file, so a mismatch
# fails `bundle install` instead of drifting silently.
ARG RUBY_VERSION=3.4.12

##############################################################################
# Stage 1: build the gem bundle (compilers and headers live only here)
##############################################################################
FROM ruby:${RUBY_VERSION}-slim AS gems

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev pkg-config git && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/cache "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

##############################################################################
# Stage 2: runtime, with the interpreter, the built gems and the app only
##############################################################################
FROM ruby:${RUBY_VERSION}-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq5 libyaml-0-2 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=production \
    PORT=3000 \
    LANG=C.UTF-8

WORKDIR /app

COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY . .

# Run as an unprivileged user. Only the directories Rails actually writes to
# are handed over; the application code stays read-only to the process.
RUN set -eux; \
    groupadd --system --gid 1000 app; \
    useradd --system --uid 1000 --gid app --create-home app; \
    mkdir -p tmp/pids log; \
    chown -R app:app tmp log

USER app

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=5 \
  CMD ruby -e "require 'net/http'; exit(Net::HTTP.get_response(URI(\"http://127.0.0.1:#{ENV.fetch('PORT', '3000')}/health\")).code == '200' ? 0 : 1)"

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
