# Pull base image
#FROM hypriot/rpi-java:1.8.0
FROM openjdk:latest

MAINTAINER Michael Mäder <mike@moik.org>

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
#	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \ 
#	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
#	&& export GNUPGHOME="$(mktemp -d)" \
#	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
#	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
#	&& chmod +x /usr/local/bin/gosu \
#	&& gosu nobody true
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Args and Env
ARG ELASTICSEARCH_VERSION=5.0.1
ENV ES_HOME=/opt/elasticsearch
ENV PATH $ES_HOME/bin:$PATH

# Add the User before anything else (Will create Home Dir with correct User)
RUN useradd -d $ES_HOME -u 1000 elasticsearch

# Install Elasticsearch
RUN set -x \
	&& mkdir $ES_HOME \
	&& cd $ES_HOME \
	&& wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
	&& wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz.sha1 \
	&& EXPECTED_SHA=$(cat elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz.sha1) \
	&& ACTUAL_SHA=$(sha1sum elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz | awk '{print $1}') \
	&& test ${EXPECTED_SHA} = ${ACTUAL_SHA} \
	&& tar zxf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
	&& chown -R elasticsearch:elasticsearch elasticsearch-${ELASTICSEARCH_VERSION} \
	&& rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz.sha1 \
	&& mv elasticsearch-${ELASTICSEARCH_VERSION}/* . \
	&& rmdir elasticsearch-${ELASTICSEARCH_VERSION}

# Setup some additional directories
RUN set -ex \
	&& for path in \
		$ES_HOME/data $ES_HOME/logs \
	; do \
		mkdir -p "$path"; \
		chown -R elasticsearch:elasticsearch "$path"; \
	done

# Cleanup
#RUN set -xe \
#	&& apt-get purge -y ca-certificates wget

# Inject the config
COPY config $ES_HOME/config
RUN set -xe \
	&& chown -R elasticsearch:elasticsearch $ES_HOME/config

# Define standard entrypoint
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Define mountable directories.
#VOLUME ["/data"]

EXPOSE 9200 9300
CMD ["elasticsearch"]
