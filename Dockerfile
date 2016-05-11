FROM alpine:3.2
MAINTAINER 6fusion dev <dev@6fusion.com>

ENV BUILD_PACKAGES build-base curl-dev libffi-dev gcc git zlib-dev
ENV RUBY_PACKAGES ruby ruby-bundler ruby-dev ruby-io-console ruby-nokogiri
ENV RUNTIME_PACKAGES ca-certificates bash

ENV RACK_ENV production

ENV APPDIR /usr/src/app

RUN \
# Update and install all of the required packages.
  apk update && \
  apk upgrade && \
  apk add $BUILD_PACKAGES $RUBY_PACKAGES $RUNTIME_PACKAGES && \
# Create the folder to hold the application
  mkdir -p $APPDIR && \
# Clean up
  rm -rf /var/cache/apk/*

WORKDIR  $APPDIR
COPY . $APPDIR

RUN \
# Install the gems required by the application
  bundle install && \
# Remove unnecessary files/folders
  rm -rf .git .gitignore

# Add the entrypoint script
ADD docker/apps/k8scollector/k8scollector-entrypoint.sh /
RUN chmod +x /k8scollector-entrypoint.sh

ENTRYPOINT ["/k8scollector-entrypoint.sh"]
