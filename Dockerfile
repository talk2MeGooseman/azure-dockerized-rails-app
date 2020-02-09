ARG RAILSDOCK_RUBY_VERSION=2.6

FROM ruby:$RAILSDOCK_RUBY_VERSION

ARG DEBIAN_FRONTEND=noninteractive

###############################################################################
# Base Software Install
###############################################################################

ARG RAILSDOCK_NODE_VERSION=10

RUN curl -sL https://deb.nodesource.com/setup_$RAILSDOCK_NODE_VERSION.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    yarn \
    locales \
    git \
    netcat \
    vim \
    sudo

###############################################################################
# Ruby, Rubygems, and Bundler Defaults
###############################################################################

ENV LANG C.UTF-8

# Point Bundler at /gems. This will cause Bundler to re-use gems that have already been installed on the gems volume
ENV BUNDLE_PATH /gems
ENV BUNDLE_HOME /gems

# Increase how many threads Bundler uses when installing. Optional!
ARG RAILSDOCK_BUNDLE_JOBS=20
ENV BUNDLE_JOBS $RAILSDOCK_BUNDLE_JOBS

# How many times Bundler will retry a gem download. Optional!
ARG RAILSDOCK_BUNDLE_RETRY=5
ENV BUNDLE_RETRY $RAILSDOCK_BUNDLE_RETRY

# Where Rubygems will look for gems, similar to BUNDLE_ equivalents.
ENV GEM_HOME /gems
ENV GEM_PATH /gems

# Add /gems/bin to the path so any installed gem binaries are runnable from bash.
ENV PATH /gems/bin:$PATH

# Install the pgsql client, when comes time to actually use a DB
RUN apt-get install -y postgresql-client

###############################################################################
# Final Touches
###############################################################################
RUN mkdir -p "$GEM_HOME"

RUN mkdir -p /app

WORKDIR /app

# Install latest bundler
RUN gem install bundler

# Only copy over gem files to do installs to save layer size
COPY Gemfile Gemfile.lock ./

RUN bundle config build.nokogiri --use-system-libraries

RUN bundle check || bundle install

# Copy for package.json and yarn.lock to do install to save layer size
COPY package.json yarn.lock ./

RUN yarn install --check-files --production=true

# Finally copy over rest of app
COPY . /app

# Precompile assets for production
RUN RAILS_ENV=production bundle exec rake assets:precompile

# puma complains if we dont make this
RUN mkdir -p tmp/pids/

# Run these scripts
ENTRYPOINT [ "entrypoints/docker-entrypoint.sh" ]

# Default to run this command unless overriden in docker-compose file
CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
