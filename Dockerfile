FROM alpine:3.2

ENV BUILD_PACKAGES build-base curl-dev libffi-dev gcc git zlib-dev
ENV RUBY_PACKAGES ruby ruby-bundler ruby-dev ruby-io-console ruby-nokogiri
ENV RUNTIME_PACKAGES ca-certificates

WORKDIR /app
COPY app/ /app/
COPY Gemfile* /app/

RUN apk --no-cache add $BUILD_PACKAGES $RUBY_PACKAGES $RUNTIME_PACKAGES && \
    bundle install && \
    apk del $BUILD_PACKAGES




