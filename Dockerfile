FROM azul/zulu-openjdk-debian:8

WORKDIR /activemq

ARG ACTIVEMQ_VERSION=5.14.1
ENV ACTIVEMQ_URL=https://www.apache.org/dist/activemq/$ACTIVEMQ_VERSION/apache-activemq-$ACTIVEMQ_VERSION-bin.tar.gz

ENV DUMB_INIT_VERSION=1.2.0
ENV GOSU_VERSION=1.10

RUN adduser --no-create-home --disabled-login --system --disabled-password --group -q activemq

RUN set -ex && \
  # update packages, install curl and cleanup
  apt-get update && \
  apt-get -y --no-install-recommends install \
    ca-certificates \
    curl && \
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
  curl --progress-bar -OL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_{$DUMB_INIT_VERSION}_amd64.deb && \
  curl --progress-bar -OL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/sha256sums && \
  head -n 1 sha256sums | sha256sum -c && \
  dpkg -i dumb-init_*.deb && \
  rm sha256sums dumb-init_*.deb && \
\
# install Gosu
  curl --progress-bar -LO https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64 && \
  curl --progress-bar -LO https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc && \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
  gpg --verify gosu-amd64.asc && \
  chmod +x gosu-amd64 && \
  mv gosu-amd64 /usr/local/bin/gosu && \
  rm gosu-amd64.asc && \
  apt-get clean && \
  apt-get purge -y --auto-remove ca-certificates curl && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  chown activemq:activemq . -R

EXPOSE 1883 5672 8161 61613 61614 61616

ENTRYPOINT ["dumb-init", "--", "gosu", "activemq", "bin/activemq"]

CMD ["console"]
