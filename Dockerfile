FROM alpine:3.4

WORKDIR /activemq

ARG ACTIVEMQ_VERSION=5.14.1
ENV ACTIVEMQ_URL=https://www.apache.org/dist/activemq/$ACTIVEMQ_VERSION/apache-activemq-$ACTIVEMQ_VERSION-bin.tar.gz

ENV DUMB_INIT_VERSION=1.2.0
ENV GOSU_VERSION=1.10
ENV JAVA8_VERSION=8.101.13-r1

# su-exec user
RUN addgroup activemq && \
    adduser -S -G activemq activemq

RUN set -ex && \
# update and install packages
  apk update && \
  apk add --no-cache --update --repository http://dl-3.alpinelinux.org/alpine/edge/community/ \
    curl \
    gnupg \
    openjdk8-jre=${JAVA8_VERSION} \
    su-exec \
    tar && \
\
# install activemq
  curl --progress-bar $ACTIVEMQ_URL -o activemq.tar.gz && \
  curl --progress-bar $ACTIVEMQ_URL.asc -o activemq.tar.gz.asc && \
  curl --progress-bar https://www.apache.org/dist/activemq/KEYS | gpg --import && \
  gpg --verify activemq.tar.gz.asc && \
  tar xzf activemq.tar.gz --strip-components=1 && \
  rm activemq.tar.gz* && \
\
# install dumb-init
  curl --progress-bar -OL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
  curl --progress-bar -OL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/sha256sums && \
  sed -n 2p sha256sums | sha256sum -c && \
  mv dumb-init_${DUMB_INIT_VERSION}_amd64 /usr/local/bin/dumb-init && \
  chmod +x /usr/local/bin/dumb-init && \
  apk del curl gnupg && \
  rm -rf /var/cache/apk/* && \
  chown activemq:activemq . -R

EXPOSE 1883 5672 8161 61613 61614 61616

ENTRYPOINT ["dumb-init", "--", "su-exec", "activemq", "bin/activemq"]

CMD ["console"]
