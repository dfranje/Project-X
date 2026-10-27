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

## Admin panel audit (fixes in install/admin-security.patch)

The admin panel is not in this repo; its fixes ship as a patch applied at
install time. A command-execution audit found and fixed three authenticated
(admin / reseller-permission-gated) injection points, all now using
`escapeshellarg()` / `intval()`:

- `api.php` `backup`/`restore`: the `.sql` path derived from `$_GET["filename"]`
  via `pathinfo()` was interpolated unescaped into a `mysql` / `mysqldump` shell
  command. `pathinfo()` strips directories but not shell metacharacters, so a
  crafted `filename` broke out of the quotes — command injection. Now
  `escapeshellarg()`'d.
- `api.php` `map_stream`: `escapeshellcmd($_GET["stream"])` was placed inside
  double quotes (the paired-quote quirk, plus ffprobe argument injection).
  Switched to `escapeshellarg()`.
- `watch.php`: `exec("pkill -9 ".$watch_pid)` with a non-integer value. Now
  `intval()`'d.

The rest of the audit came back clean: no raw superglobal reaches SQL (the panel
uses `ESC()` / `intval()` consistently), no `include`/`require` LFI, and the
`login.php` reCAPTCHA fetch targets a fixed Google host.

**Not changed (operator decision):** the panel still calls `xtream-ui.com` on
every Settings page load (`settings.php`) and can download + install a GeoLite2
`.mmdb` from it (`updateGeoLite2()`). This is the same third-party phone-home
class that was removed from the backend — a privacy leak, a page-load
dependency on an external domain, and a supply-chain risk if that domain changes
hands. Removing or gating it is recommended.

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
  (`crl_sync.php`, `offline_cons.php`, `xmltv.php`, `portal.php`,
  `player_api.php`). A follow-up **full backend sweep** then confirmed the
  result: `ipTV_db::query()` is a printf-style layer (`mysqli_real_escape_string`
  on every arg, then `vsprintf` into the format string), and no call site
  concatenates or interpolates a variable into a format string. The only
  callers of the unescaped paths — the raw-query method `ipTV_db::FC53e22a…()`
  and one direct `mysqli_query()` — all pre-escape their input: `api.php` builds
  the `users` INSERT through a builder that sanitises column names
  (`preg_replace` to `[A-Za-z0-9_]`) and `escape()`s every value; the
  `crl_sync.php`/`offline_cons.php` log parsers `array_map('escape', …)` each
  client-supplied field before the bulk INSERT; `xmltv.php` escapes+quotes each
  `epg_id` and `intval`s the date offsets. A full PDO rewrite of the custom
  layer would be churn with no security benefit, so it is deliberately not done.

## Known functional (non-security) issue — validate on a live server

The two client-logging crons `crons/crl_sync.php` and `crons/offline_cons.php`
have their **statement order scrambled by the ionCube decode** (the same class
of damage as the repaired `goto` fatals, but these still pass `php -l`). For
example `offline_cons.php` tests `file_exists($file)` and runs the
`user_activity` INSERT *before* the lines that set `$file` and build the VALUES
string, so as a linear script the body is a no-op. This is not a vulnerability
(the SQLi vector in the builders is already closed), but it means the
`client_logs` / `user_activity` stats tables likely do not populate. Repairing
the control flow needs reconstruction plus a live run to confirm the tables fill
without double-inserting — best done during VPS validation, not blind.
- Repaired decode-dropped `goto` labels in `streaming.php`,
  `clients_live.php` and `geo/Decoder.php` — the backend previously could not
  even be included (compile fatal); it now passes `php -l` everywhere and
  boots via `init.php`.
- `system_api.php` `print_image`: fixed arbitrary file read (restricted to
  MOVIES_IMAGES). `xplugin.php` screen upload: now requires a real image.
- `includes/lib.php` stalker/MAG token decrypt: replaced the removed `mcrypt`
  Rijndael-256 (256-bit block, no openssl equivalent) with a phpseclib-backed,
  mcrypt-compatible path — uses mcrypt where still present, phpseclib otherwise,
  and fails closed if neither is available instead of fataling. The HMAC check
  is now constant-time (`hash_equals`). This lets the backend run on PHP 8.x;
  the installer vendors phpseclib automatically.
