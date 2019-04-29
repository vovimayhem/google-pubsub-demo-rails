# Unlike other projects, where I use an alpine-based official image,
# I'm using instead the debian-based versions (default + slim). Notice also how
# the "development" stage does not depend on the "runtime" stage.

# The reason behind this was that I couldn't resolve a segfault I was getting
# with gRPC stuff and the MUSL C library...

# I: Development Stage: ========================================================
# In this stage we'll build the image used for development, including compilers,
# and development libraries. This is also a first step for building a releasable
# Docker image:

# Step 1: Use the "ruby:2.5.3" image as the starting point:
FROM ruby:2.6.3 AS development

# Step 2: We'll set '/usr/src' path as the working directory:
# NOTE: This is a Linux "standard" practice - see:
# - http://www.pathname.com/fhs/2.2/
# - http://www.pathname.com/fhs/2.2/fhs-4.1.html
# - http://www.pathname.com/fhs/2.2/fhs-4.12.html
WORKDIR /usr/src

# Step 3: We'll set the working dir as HOME and add the app's binaries path to
# $PATH:
ENV HOME=/usr/src PATH=/usr/src/bin:$PATH

# Step 4: Add the development packages using debian's package manager:
RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo

# Step 5: Copy the project's Gemfile + lock:
ADD Gemfile* /usr/src/

# Step 6: Install the current project gems - they can be safely changed later
# during development via `bundle install` or `bundle update`:
RUN bundle install --jobs=4 --retry=3

# Step 7: Receive the developer's user id as argument to use in the container:
ARG DEVELOPER_UID="1000"

# Step 8: Add the developer user to the container (and add it to the "root"
# group):
RUN adduser \
  --quiet \
  --home /usr/src \
  --no-create-home \
  --disabled-password \
  --uid $DEVELOPER_UID developer && usermod -aG sudo developer

# Step 9: Scale down to the developer user:
USER developer

# Step 10: Set the default command:
CMD [ "rails", "server", "-b", "0.0.0.0" ]

# Stage II: Testing ============================================================
# This is the stage where we place the final code prior to building, and it's
# made for our CI process to have a testable image, ready to run tests into:

# Step 11: Pick off from the development stage:
FROM development AS testing

# Step 12: Copy the rest of the code:
COPY . /usr/src

# Stage III: Builder ===========================================================
# Step 13: Pick off from the testing stage image:
FROM testing AS builder

# Step 14: Remove installed gems that belong to the development & test groups -
# we'll copy the remaining system gems into the deployable image later:
RUN bundle config without development:test && bundle clean && rm -rf tmp/*

# Stage IV: Release ============================================================
# Step 15: Use the official ruby image, debian slim version:
FROM ruby:2.6.3-slim AS runtime

# Step 16: Replicate the step 2 from the development stage, where we set the
# '/usr/src' path as the working directory:
WORKDIR /usr/src

# Step 17: Replicate the step 3 from the development stage, where we set the
# working dir as HOME and add the app's binaries path to $PATH:
ENV HOME=/usr/src PATH=/usr/src/bin:$PATH

# Step 18: Add the runtime packages (needed for the app to run) using debian's
# package manager:
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    libpq5 \
    openssl \
    tzdata

# Step 19: Copy the installed system gems from the builder stage:
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Step 20: Copy the application code from the builder stage at the /usr/src
# directory, along with the precompiled assets, setting the owner to 'nobody':
COPY --from=builder --chown=nobody:nobody /usr/src /usr/src

# Step 21: Generate the temporary directories in case they don't already exist:
RUN mkdir -p /usr/src/tmp/cache /usr/src/tmp/pids /usr/src/tmp/sockets \
 && chown -R nobody:nobody /usr/src/tmp

# Step 22: Set the container user to 'nobody', so it always run unprivileged:
USER nobody

# Step 23: Set the RAILS/RACK_ENV and PORT default values:
ENV RAILS_ENV=production RACK_ENV=production PORT=3000

# Step 24: Check that there are no issues with rails' load paths, missing gems,
# etc:
RUN export DATABASE_URL=postgres://postgres@example.com:5432/fakedb \
    SECRET_KEY_BASE=10167c7f7654ed02b3557b05b88ece && \
    rails runner "puts 'Looks Good!'"

# Step 25: Set the container's default command:
CMD [ "puma" ]

# Step 26 thru 30: Add label-schema.org labels to identify the build info:
ARG SOURCE_BRANCH="master"
ARG SOURCE_COMMIT="000000"
ARG BUILD_DATE="2017-09-26T16:13:26Z"
ARG IMAGE_NAME="google-pubsub-emulator-rails-demo:development"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Vovimayhem Google PubSub Emulator Rails Demo" \
      org.label-schema.description="Vovimayhem Google PubSub Emulator Rails Demo" \
      org.label-schema.vcs-url="https://github.com/vovimayhem/google-pubsub-emulator-rails-demo.git" \
      org.label-schema.vcs-ref=$SOURCE_COMMIT \
      org.label-schema.schema-version="1.0.0-rc1" \
      build-target="release" \
      build-branch=$SOURCE_BRANCH
