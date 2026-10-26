# Rebuilding the bundled nginx (fixes Heartbleed and later CVEs)

`nginx/sbin/nginx` shipped with the panel is statically linked against
**OpenSSL 1.0.1e (2013)**, which is vulnerable to Heartbleed (CVE-2014-0160)
and many later issues. Disabling SSLv3/TLSv1.0/1.1 in `nginx.conf` is
necessary but does **not** fix Heartbleed — the heartbeat bug lives in the
OpenSSL code compiled into the binary, so the binary itself must be rebuilt
against a current OpenSSL. The new TLS settings in `conf/nginx.conf`
(`ssl_protocols TLSv1.2 TLSv1.3`, modern ciphers) require OpenSSL 1.1.1+.

The preferred long-term fix is to stop shipping a private nginx build and
run the distribution's nginx package instead. If the panel must keep its own
static binary, rebuild it from current, checksum-verified sources as below.

## Verified sources (Ubuntu 24.04 archive)

| component | version    | sha256 of the .orig tarball |
|-----------|------------|------------------------------|
| nginx     | 1.28.0     | `c6b5c6b086c0df9d3ca3ff5e084c1d0ef909e6038279c71c1c3e985f576ff76a` |
| OpenSSL   | 3.5.5      | `b28c91532a8b65a1f983b4c28b7488174e4a01008e29ce8e69bd789f28bc2a89` |
| PCRE2     | 10.46      | `8d28d7f2c3b970c3a4bf3776bcbb5adfc923183ce74bc8df1ebaad8c1985bd07` |
| zlib      | 1.3        | `5eea0322c1c21c75cad3b607ac1c43ff5c71e014b8ac4a34300b5e2b80d02e70` |

Apply the Ubuntu security patch series shipped in the matching `*.debian.tar.xz`
(`debian/patches/series`) to the nginx and OpenSSL trees before building —
those carry the post-release CVE fixes.

## Configure line

This mirrors the original build (verified with `strings nginx/sbin/nginx |
grep 'configure arguments'`), minus flags removed in modern nginx
(`--with-ipv6`, `--with-cpu-opt`, which are now defaults/no-ops):

```sh
./configure \
  --prefix=/home/xtreamcodes/iptv_xtream_codes/nginx/ \
  --http-client-body-temp-path=/home/xtreamcodes/iptv_xtream_codes/tmp/client_temp \
  --http-proxy-temp-path=/home/xtreamcodes/iptv_xtream_codes/tmp/proxy_temp \
  --http-fastcgi-temp-path=/home/xtreamcodes/iptv_xtream_codes/tmp/fastcgi_temp \
  --lock-path=/home/xtreamcodes/iptv_xtream_codes/tmp/nginx.lock \
  --http-uwsgi-temp-path=/home/xtreamcodes/iptv_xtream_codes/tmp/uwsgi_temp \
  --http-scgi-temp-path=/home/xtreamcodes/iptv_xtream_codes/tmp/scgi_temp \
  --conf-path=/home/xtreamcodes/iptv_xtream_codes/nginx/conf/nginx.conf \
  --error-log-path=/home/xtreamcodes/iptv_xtream_codes/logs/error.log \
  --http-log-path=/home/xtreamcodes/iptv_xtream_codes/logs/access.log \
  --pid-path=/home/xtreamcodes/iptv_xtream_codes/nginx/nginx.pid \
  --with-http_ssl_module --with-http_realip_module --with-http_addition_module \
  --with-http_sub_module --with-http_dav_module --with-http_gunzip_module \
  --with-http_gzip_static_module --with-pcre --with-http_random_index_module \
  --with-http_secure_link_module --with-http_stub_status_module \
  --with-http_auth_request_module --with-threads --with-mail --with-mail_ssl_module \
  --with-file-aio \
  --with-pcre=../pcre2-10.46 \
  --with-zlib=../zlib-1.3.dfsg \
  --with-openssl=../openssl-3.5.5 \
  --with-ld-opt='-Wl,-z,relro -Wl,--as-needed -static' \
  --with-cc-opt='-static -static-libgcc -g -O2 -Wformat -Wall'
make -j"$(nproc)"
```

Then verify the result links the new OpenSSL and replace the binary:

```sh
strings objs/nginx | grep -m1 'OpenSSL 3\.'   # must show 3.5.x, not 1.0.1e
./objs/nginx -t -c /path/to/nginx.conf         # config check
# stop nginx, back up nginx/sbin/nginx, copy objs/nginx over it, start nginx
```

Rebuild `nginx_rtmp/sbin/nginx_rtmp` the same way (it uses the original
`nginx-rtmp-module` via `--add-module=./nginx-rtmp-module`).
