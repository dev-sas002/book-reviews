# syntax=docker/dockerfile:1

# The application is pinned to the Ruby in .ruby-version, and the Gemfile reads
# that file, so the image tag and the repository cannot drift apart silently.
ARG RUBY_VERSION=2.7.2

# Matches `BUNDLED WITH` in Gemfile.lock. Ruby 2.7.2 ships Bundler 2.1.4, which
# warns on every single command that the lockfile was written by a newer
# Bundler; pinning it here keeps container output free of that noise.
ARG BUNDLER_VERSION=2.2.9

##############################################################################
# Stage 1 — build the gem bundle (compilers and headers live only here)
##############################################################################
FROM ruby:${RUBY_VERSION}-slim AS gems

# Debian buster is archived, so the default mirrors no longer serve a Release
# file. Point apt at archive.debian.org instead of pinning a newer Ruby the
# application has never been tested on.
RUN set -eux; \
    sed -i \
      -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
      -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
      -e '/buster-updates/d' /etc/apt/sources.list; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      pkg-config \
      patch \
      git; \
    rm -rf /var/lib/apt/lists/*

ARG BUNDLER_VERSION
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/cache "${BUNDLE_PATH}"/ruby/*/cache

##############################################################################
# Stage 2 — runtime: the interpreter, the built gems, the app, nothing else
##############################################################################
FROM ruby:${RUBY_VERSION}-slim AS runtime

RUN set -eux; \
    sed -i \
      -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
      -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
      -e '/buster-updates/d' /etc/apt/sources.list; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends libpq5 postgresql-client; \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000 \
    LANG=C.UTF-8

WORKDIR /app

# Brings the pinned Bundler across with the gems; GEM_HOME is /usr/local/bundle
# in the official Ruby image, so this is the whole gem environment.
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
