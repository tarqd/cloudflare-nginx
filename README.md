# cloudflare-nginx

Collection of helpful configuration files for working with Nginx + Cloudflare

## cloudflare.d/cloudflare.conf

Defines a few helper variables:

- `$is_cloudflare_ip`: Returns 1 if the current `$remote_addr` is a cloudflare IP
- `$cloudflare_connecting_ip`: Returns the users real IP if we're behind Cloudflare, otherwise blank
- `$cloudflare_remote_addr`: Returns `$cloudflare_connecting_ip` if we're behind cloudflare, otherwise returns `$remote_addr`
- `$cloudflare_add_x_forwarded_for`: If we're behind cloudflare it returns `<CF-Connecting-IP>, <CloudFlare-IP>, <Original-X-Forwarded-For>`, otherwise it returns `$proxy_add_xforwarded_for`
- `$cloudflare_scheme`, Returns `X-Forwarded-For-Proto` if we're behind cloudflare, otherwise `$scheme`
- `$cloudflare_country`, Returns `CF-IPCountry` if we're behind cloudflare, otherwise blank

If you're using the realip module, you'll have to use the `$cloudflare_realip_*` versions of the above variables, if available

You'll also have access to the `cloudflare` log format, which will log `$cloudflare_remote_addr` along with `CF-Ray` 

## cloudflare.d/cloudflare-restrict.conf

Include this in your server or location block to block any connections from non-cloudflare IPs. Does not work if you're using the realip module. 

```
if ( $is_cloudflare_ip = 0 ) {
  return 403;
}
```

## cloudflare.d/cloudflare-allow.conf

Include this allow connections from cloudflare IPs using the access module. 

```
# it will contain a line like this for each cloudflare range
allow cloudflareip/range;
```

## cloudflare.d/realip.conf

Uses the realip module to set `$remote_addr` if we're behind cloudflare.

## cloudflare.d/cloudflare-proxy.conf

Sets up proxy parameters to safely pass the users real ip when we're behind cloudflare along with some other variables:

```
proxy_set_header X-Real-IP $cloudflare_remote_addr;
proxy_set_header X-Forwarded-For $cloudflare_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $cloudflare_scheme;
proxy_set_header X-Geo-Country $cloudflare_country;
```

## Installation

You can either copy `cloudflare.d` into your nginx directory or use the deb/rpm packages to install these configs.

After that, add the following to `/etc/nginx/conf.d/cloudflare.conf`:

```
include cloudflare.d/cloudflare.conf
```

You can then use the helpers in server/location blocks like so:

```
server {
  server_name behindcloudflare.com;
  include cloudflare.d/restrict.conf;
  include cloudflare.d/cloudflare-proxy.conf;
  access_log /var/log/nginx/behindcloudflare_access.log cloudflare;
  # block US visitors
  if ( $cloudflare_country = "US" ) {
    return 403;
  }
  proxy_pass https://backend;
}
```

# Why not just use realip?

Sometimes you don't want to just replace the `remote_addr` wholesale in Nginx depending on your setup. A quick example would be if you want to whitelist your internal VPN and cloudflare in a location block.
If you're using `allow/deny` to allow direct access to the backend via the VPN, you can't use realip because your end users coming from cloudflare will be blocked because the access module is now using the cloudflare IP, not the real `$remote_addr` for applying your ACLs.

With this script you can keep your old ACLs and just add cloudflares IPs to the list and use the helper variables to ensure your backends/logs always see the right IP. 
