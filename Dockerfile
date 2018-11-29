FROM debian:stretch
WORKDIR /opt/cloudflare.d
COPY cloudflare.d/* ./
COPY scripts/build.sh /build.sh
ARG VERSION
ENV VERSION $VERSION
RUN  apt-get update -y && apt-get -y install rpm ruby ruby-dev rubygems build-essential && apt-get install -y curl grep && gem install --no-ri --no-rdoc fpm
RUN /build.sh
