# Install (test) — Ubuntu 24.04

`install.sh` stands up the whole thing on a **clean** Ubuntu 24.04 server for
**testing**: the security-hardened streaming backend from this repo plus the
XtreamUI admin panel with the fixes in `install/admin-security.patch` applied.

```bash
git clone <this-repo> project-x && cd project-x
sudo ./install.sh
# optional overrides:
# sudo ADMIN_USER=admin ADMIN_PASS='YourPass' DB_PASS='...' ./install.sh
```

At the end it prints the admin URL, the admin credentials and the DB password —
**save them**.

## Before you run it

- **Authorisation / legality.** Use this only on a server you own or are
  authorised to use, and only for content you are licensed to distribute. The
  script installs server software and adds *no* content; what you stream is
  your responsibility. Xtream Codes–derived panels are widely associated with
  unlicensed streaming — don't.
- **Throwaway VPS first.** This is a best-effort test installer, not a
  production-hardened deploy. Run it on a disposable VPS, confirm what works,
  then decide.

## What works vs. what to expect

| Component | Status on Ubuntu 24.04 / PHP 8.3 |
|-----------|----------------------------------|
| Admin panel (XtreamUI, patched) | Works: login, dashboard, management pages |
| MariaDB schema + admin user | Works |
| Client/stream **API** bootstrap (`init.php`) | Loads |
| Live **streaming** (ffmpeg spawn, HLS) | Partial — needs testing per stream |
| Stalker / MAG portal tokens | Works on 8.x via phpseclib (installed automatically; mcrypt was removed in PHP 7.2) — validate with a real MAG/stalker client |
| GeoIP lookups | Should work on 8.x (the reader uses only PHP 8-valid syntax); validate on first use |

### How it runs on PHP 8.3
The code was written for **PHP 7.2**, but the only hard incompatibilities have
been bridged, so it runs on the system **PHP 8.3** that ships with Ubuntu 24.04:

- **`mysqli` error handling** — a `mysqli_report(OFF)` auto-prepend restores the
  7.2-style return-based semantics (8.1+ throws by default).
- **`mcrypt`** (removed in 7.2) — only the stalker/MAG token decrypt used it,
  for a 256-bit-block Rijndael that openssl can't do. `includes/lib.php` now
  calls mcrypt when present and otherwise **phpseclib** (vendored by the
  installer under `wwwdir/includes/vendor`), which is mcrypt-compatible.
- **nginx** — the repo's rebuilt binary (`nginx/sbin/nginx`, nginx 1.28 +
  OpenSSL 3.5.5, statically linked) runs on 24.04; three PHP-FPM pools listen on
  the unix sockets `nginx/conf/balance.conf` expects.

Two things still want a live smoke-test because they can't be exercised
headless here: **GeoIP** lookups and **stalker/MAG** login. Both use only
PHP 8-valid code now; confirm them against a real client on your VPS.

## Security fixes included

Backend (committed in this repo): trusted real-IP handling, TLS hardening +
rebuilt nginx, removal of the defunct `xtream-codes.com` calls, ffmpeg drawtext
injection fix, JSON caches, `user_data` whitelist, SQL-injection hardening,
`print_image` LFI fix, upload validation, and the decode-dropped `goto` repair
that lets the backend load at all.

Admin panel (`install/admin-security.patch`, applied at install time):
pre-auth SSRF fix in `resize.php`, `getIP()` trusted-proxy + valid-IP handling,
`iptables` shell-arg escaping, per-user password salt with backward-compatible
verification, `SameSite=Lax`/`HttpOnly` session cookie, per-form CSRF tokens,
command-injection fixes in `api.php` (the database backup/restore `.sql`
filename and the `map_stream` ffprobe argument) and `watch.php` (the `pkill`
PID), all now using `escapeshellarg()`/`intval()`, and removal of the
`xtream-ui.com` phone-home (the Settings-page version check and the
`updateGeoLite2()` auto-download — update GeoLite2 manually from MaxMind). See
the project history and `SECURITY-NOTES.md` for details.

## Uninstall / reset

```bash
systemctl disable --now xtreamcodes
rm -rf /home/xtreamcodes /etc/systemd/system/xtreamcodes.service /etc/php/*/fpm/pool.d/xc_*.conf
mysql -e "DROP DATABASE IF EXISTS xtream_iptvpro; DROP USER IF EXISTS 'xtream'@'127.0.0.1','xtream'@'localhost';"
systemctl daemon-reload
```
