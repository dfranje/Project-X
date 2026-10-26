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

## Still outstanding (not addressed in these commits)

- `nginx/sbin/nginx` must be rebuilt against a current OpenSSL to fix
  Heartbleed (see `nginx/REBUILD.md`); the TLS config change alone does not.
- `system_api.php` exposes shell-execution actions; passwords are stored in
  clear text. These are tracked as later stages of the review.

## Done in later stages

- `system_api.php`: constant-time API auth; `getURL` shell-injection fixed.
- All calls to the defunct `xtream-codes.com` were removed: the `cloud_ips`
  allowlist fetch, the `api.xtream-codes.com` ISP/VPN lookup (which leaked
  client IP + user-agent), the `gt_bl.php` blacklist fetch (which fed
  `unserialize()` — PHP object injection), and the `GeoLite2.mmdb` download.
  The shipped GeoIP database is used as-is; update it from MaxMind.
