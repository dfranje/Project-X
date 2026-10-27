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
| GeoIP lookups | **Known issue** on PHP 8.x (the bundled reader is PHP 7.2-era); use PHP 7.4 if you need it |

### Why the version caveats
The code targets **PHP 7.2**. The binaries that ship in the repo (`php/bin/php`,
the old `nginx`) are linked against libraries that no longer exist on Ubuntu
24.04, so the installer uses:

- **System PHP-FPM** (8.3 on 24.04) with a `mysqli_report(OFF)` shim so the
  7.2-style `mysqli` error handling keeps working, and three pools on the unix
  sockets the backend's `nginx/conf/balance.conf` expects.
- **This repo's rebuilt nginx** (`nginx/sbin/nginx`, nginx 1.28 + OpenSSL 3.5.5
  — the Heartbleed fix), statically linked, so it runs on 24.04.

For the **closest-to-original** backend behaviour, install **PHP 7.4** from the
`ondrej/php` PPA before running, then re-point `PHP_VER` — 7.4 keeps the return
-based `mysqli` semantics and avoids the removed-function issues of 8.x.

## Security fixes included

Backend (committed in this repo): trusted real-IP handling, TLS hardening +
rebuilt nginx, removal of the defunct `xtream-codes.com` calls, ffmpeg drawtext
injection fix, JSON caches, `user_data` whitelist, SQL-injection hardening,
`print_image` LFI fix, upload validation, and the decode-dropped `goto` repair
that lets the backend load at all.

Admin panel (`install/admin-security.patch`, applied at install time):
pre-auth SSRF fix in `resize.php`, `getIP()` trusted-proxy + valid-IP handling,
`iptables` shell-arg escaping, per-user password salt with backward-compatible
verification, `SameSite=Lax`/`HttpOnly` session cookie, and per-form CSRF
tokens. See the project history for details.

## Uninstall / reset

```bash
systemctl disable --now xtreamcodes
rm -rf /home/xtreamcodes /etc/systemd/system/xtreamcodes.service /etc/php/*/fpm/pool.d/xc_*.conf
mysql -e "DROP DATABASE IF EXISTS xtream_iptvpro; DROP USER IF EXISTS 'xtream'@'127.0.0.1','xtream'@'localhost';"
systemctl daemon-reload
```
