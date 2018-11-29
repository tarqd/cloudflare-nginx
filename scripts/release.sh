#!/bin/bash

if [ -z "$VERSION" ]; then
  if [ ! -z "$TRAVIS_BUILD_NUMBER" ]; then
    VERSION="1.0.$TRAVIS_BUILD_NUMBER"
  fi
fi

docker build --build-arg VERSION=$VERSION -t cloudflare-nginx:build . 
docker container create --name extract cloudflare-nginx:build
docker container cp extract:/tmp/nginx-pkg /tmp/nginx-pkg
mv /tmp/nginx-pkg/*.deb ./release
mv /tmp/nginx-pkg/*.rpm ./release
mv /tmp/nginx-pkg/cloudflare-ips/* ./cloudflare-ips
mv /tmp/nginx-pkg/cloudflare.d/*v4.conf ./cloudflare.d/
mv /tmp/nginx-pkg/cloudflare.d/*v6.conf ./cloudflare.d/
rm -rf /tmp/nginx-pkg
docker container rm -f extract

