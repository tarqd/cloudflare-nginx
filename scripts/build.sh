#!/bin/bash


function get_cloudflare_ips() {
  if [ $# -eq 0 ]; then
    get_cloudflare_ips v4 && get_cloudflare_ips v6
  else
    curl -s -N "https://www.cloudflare.com/ips-$1"
  fi
}

function validate_ip() {
 echo "$1" | grep -qiE '^(([0-9./]*)|[0-9a-z:]*)(/[0-9]{1,3})'
}

function validate_ips() {
  while read -r ip; do
    validate_ip "$ip" || return 1
  done
}

function log() {
  >&2 echo "$@"
}

function die() {
  log "$@"
  exit 1
}

function download_ips_if_not_cached() {
  if [ ! -f "cloudflare-ips-$1" ]; then
    get_cloudflare_ips "$1" > "cloudflare-ips-$1"
  fi
}

IPv4=cloudflare-ips-v4
IPv6=cloudflare-ips-v6

log "Downloading latest Cloudflare ranges"

download_ips_if_not_cached v4 && download_ips_if_not_cached v6 || die "failed to download ips from cloudflare"

cat $IPv4 $IPv6 | validate_ips || die "Cloudflare returned invalid ips"

wc -l $IPv4 $IPv6

MODELINE="# vim: set ft=nginx ts=2 sw=2 sts=2 et :"

log "Generating geo includes"

awk '{ print $1,"1;" }' $IPv4 > geo-ipv4.conf
awk '{ print $1,"1;" }' $IPv6 > geo-ipv6.conf
awk '{ print "proxy", $1,";" }' $IPv4 > geo-proxy-ipv4.conf
awk '{ print "proxy", $1,";" }' $IPv6 > geo-proxy-ipv6.conf
cat geo-proxy-ipv4.conf geo-proxy-ipv6.conf > geo-proxy.conf

log "Generating realip includes"

for x in realip-ipv{4,6}.conf allow-ipv{4,6}.conf; do
  echo -e "$MODELINE\n" > $x
done

awk '{ print "set_real_ip_from",$1 ";" }' $IPv4 >> realip-ipv4.conf
awk '{ print "set_real_ip_from",$1 ";" }' $IPv6 >> realip-ipv6.conf
awk '{ print "allow",$1 ";" }' $IPv4 >> allow-ipv4.conf
awk '{ print "allow",$1 ";" }' $IPv6 >> allow-ipv6.conf

mkdir -p /tmp/nginx-pkg/{cloudflare.d,cloudflare-ips}
mv ./*.conf /tmp/nginx-pkg/cloudflare.d
mv $IPv4 /tmp/nginx-pkg/cloudflare-ips/ipv4
mv $IPv6 /tmp/nginx-pkg/cloudflare-ips/ipv6
VERSION=${VERSION:-1.0.0}
cd /tmp/nginx-pkg
log "Creatig packages for version $VERSION"
fpm -t deb -s dir -d nginx -a all -m "Christopher Tarquini <code@tarq.io>"  -n cloudflare-nginx --vendor tarq.io --url https://github.com/ilsken/cloudflare-nginx --description "Helpful Nginx configuration for Cloudflare" --license MIT --directories /etc/nginx/cloudflare.d --directories /usr/share/cloudflare-ips -v $VERSION cloudflare.d=/etc/nginx/ cloudflare-ips=/usr/share
fpm -t rpm -s dir -d nginx -a all -m "Christopher Tarquini <code@tarq.io>"  -n cloudflare-nginx --vendor tarq.io --url https://github.com/ilsken/cloudflare-nginx --description "Helpful Nginx configuration for Cloudflare" --license MIT --directories /etc/nginx/cloudflare.d --directories /usr/share/cloudflare-ips -v $VERSION cloudflare.d=/etc/nginx/ cloudflare-ips=/usr/share

log "All Done!"


