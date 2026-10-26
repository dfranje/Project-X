# Security notes

## TLS key rotation (done / to finish on servers)

The HTTPS private key `nginx/conf/server.key` was committed to the repo (added
in commit `0dfeddf`, "v1"). Treat it as **compromised**.

- The key and its certificate are no longer tracked; `start_services.sh`
  generates a fresh self-signed RSA-2048 pair on first start, and the working
  copy here has already been regenerated (its modulus differs from the old
  one).
- The **old key is still present in git history** (`0dfeddf`, which is also on
  `master`). Removing it from `HEAD` does not un-expose it. Rewriting that
  history would rewrite commits shared with `master` without removing the key
  from `master`, so it is not done here. If you want it purged from history,
  do a coordinated `git filter-repo --path nginx/conf/server.key --invert-paths`
  on `master` and force-push once everyone is aware; the key is burned either
  way, so rotating it on the servers is what actually matters.

To rotate on each server: generate a new key/cert (or let `start_services.sh`
do it), reload nginx, and prefer a CA-issued certificate over self-signed.

## Other hardcoded secrets that should be rotated

These ship with the same value in every install and should be changed:

- `KEY_CRYPT` and `CONFIG_CRYPT_KEY` in `wwwdir/init.php` — used to
  "encrypt" the `config` file (DB credentials) and the blacklist cache. The
  cipher is a repeating-key XOR, so the DB credentials are effectively
  recoverable by anyone who has both the `config` file and this public key.
- Database password in the `config` file.
- `live_streaming_pass` and `api_pass` in the `settings` table — both are
  empty by default and gate the admin/streaming APIs (see SECURITY review).

## Password storage (why line passwords are not hashed)

`users.password` (subscriber "lines") is **not** a hashable secret in this
architecture: the plaintext password travels in every stream URL
(`/live/<user>/<pass>/<id>.ts`), is handed back to MAG/Enigma devices, and is
embedded in generated M3U playlists. Replacing it with a one-way hash would
break streaming authentication across every client, so it is deliberately
left as-is here. What was hardened instead: the case-sensitive login rechecks
in `get.php` and `streaming.php` now use strict (`===`) comparison, which
removes a PHP type-juggling edge case (e.g. `"0e1" == "0e2"`).

The password that *should* be hashed is the admin/reseller panel login
(`reg_users.password`). That login lives in the separate admin-panel
application, **not** in this repository (this repo is the client/streaming
API, crons and tools), so there is nothing to convert here. When working on
the admin panel, store `reg_users.password` with `password_hash()` and verify
with `password_verify()`.

## Hardcoded secrets — rotate on the servers (not changeable in-repo)

These ship with the same value in every install and should be changed, but
changing them in the repo would break existing installs, so they are an
operator action:

- `KEY_CRYPT` and `CONFIG_CRYPT_KEY` in `wwwdir/init.php` — used to
  "encrypt" the `config` file (DB credentials). The cipher is a repeating-key
  XOR, so the DB credentials are effectively recoverable by anyone who has
  both the `config` file and this public key. Rotating `CONFIG_CRYPT_KEY`
  requires re-writing each server's `config` file with the new key.
- Database password in the `config` file.
- `live_streaming_pass` and `api_pass` in the `settings` table — both are
  empty by default and gate the admin/streaming APIs.

## Done in later stages

- `nginx/sbin/nginx` rebuilt against OpenSSL 3.5.5 — Heartbleed fixed
  (see `nginx/REBUILD.md`).
- `system_api.php`: constant-time API auth; `getURL` shell-injection fixed.
- All calls to the defunct `xtream-codes.com` were removed: the `cloud_ips`
  allowlist fetch, the `api.xtream-codes.com` ISP/VPN lookup (which leaked
  client IP + user-agent), the `gt_bl.php` blacklist fetch (which fed
  `unserialize()` — PHP object injection), and the `GeoLite2.mmdb` download.
  The shipped GeoIP database is used as-is; update it from MaxMind.
- ffmpeg drawtext overlay: command/filter injection fixed.
- tmp caches: `unserialize()` replaced with JSON (object-injection removed).
- `api.php`: `user_data` column whitelist (mass-assignment fixed).
- SQL: escaped/parameterized the query sites that bypassed the escape layer
  (`crl_sync.php`, `xmltv.php`, `portal.php`, `player_api.php`). A full PDO
  migration of the custom query layer is still a separate, larger effort.
