FROM alpine:3.2
MAINTAINER 6fusion dev <dev@6fusion.com>

ENV BUILD_PACKAGES build-base curl-dev libffi-dev gcc git zlib-dev
ENV RUBY_PACKAGES ruby ruby-bundler ruby-dev ruby-io-console ruby-nokogiri
ENV DEV_PACKAGES bash vim sudo
ENV RUNTIME_PACKAGES ca-certificates

ENV RACK_ENV development

ENV UID 1000
ENV GID 1000
ENV USERNAME k8scollector
ENV GROUP k8scollector

RUN \
# Update and install all of the required packages.
  apk update && \
  apk upgrade && \
  apk add $BUILD_PACKAGES $RUBY_PACKAGES $DEV_PACKAGES $RUNTIME_PACKAGES && \
# Create the k8scollector user to map it to the host machine user
  addgroup -g $GID $GROUP && \
  adduser -g "K8s Collector" -h /home/$USERNAME -s /bin/ash -G $GROUP -u $UID -D $USERNAME && \
# Give the k8scollector user sudo privileges
  echo "%$GROUP ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$GROUP && \
# Create the folder to hold the application
  mkdir -p /usr/src/app && \
# Create the temporary command to keep the container alive
  touch /entrypoint.log && \
# Clean up
  rm -rf /var/cache/apk/*

WORKDIR  /usr/src/app
COPY Gemfile* /usr/src/app/

USER k8scollector
RUN \
# Install the gems required by the application
  bundle install

USER root
RUN \
# Remove the temporary Gemfiles
  rm Gemfile*

CMD ["tail", "-f", "/entrypoint.log"]
