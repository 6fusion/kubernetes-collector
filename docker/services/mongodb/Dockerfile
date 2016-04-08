# Alpine Linux 3.2 with MongoDB 3.2.0
FROM alpine:3.2

MAINTAINER 6fusion team <dev@6fusion.com>

# MongoDB version to install
ENV MONGODB_VERSION 3.2.0

# Install pre-requisites and MongoDB
RUN apk --update add bash curl libgcc libstdc++ && \
    cd /tmp && \
    curl -SLo- https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VERSION}.tgz | \
    tar xz && \
    curl -SLO https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/8/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk && \
    curl -SLO https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/8/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-bin-2.21-r2.apk && \
    apk add --allow-untrusted glibc-2.21-r2.apk glibc-bin-2.21-r2.apk && \
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib && \
    mv mongodb-linux-x86_64-${MONGODB_VERSION}/bin/* /usr/bin/ && \
    apk del curl && \
    rm -rf /tmp/* /var/cache/apk/*

# Create folders needed by the MongoDB service
RUN mkdir -p /data/db && \
    mkdir -p /var/log/mongodb

# Add the scripts to start the service
ADD scripts /scripts
RUN chmod +x /scripts/*.sh

ENTRYPOINT ["/scripts/run.sh"]
CMD [""]

EXPOSE 27017
