# Quickstart — test on a clean Ubuntu 24.04 VPS

Copy-paste path to stand up the hardened backend + patched admin on a fresh
server, confirm what works, and (optionally) connect Claude to the VPS so we can
debug the install live.

> **Use a throwaway VPS.** This is a best-effort test installer, not a
> production-hardened deploy, and Xtream Codes–derived panels are widely
> associated with unlicensed streaming — only use it on a server you own, for
> content you are licensed to distribute. See `install/README.md` for the full
> authorisation/legality note.

---

## 1. Provision + log in

Create a **clean Ubuntu 24.04** VPS (2 vCPU / 2 GB RAM is plenty for a test),
then SSH in as root (or a sudo user):

```bash
ssh root@YOUR_VPS_IP
apt-get update -q && apt-get install -y -q git     # the installer pulls the rest
```

## 2. Get the code (this branch)

The repo is private, so authenticate with a GitHub token or SSH key.

```bash
# HTTPS (will prompt for username + a personal access token as the password):
git clone https://github.com/dfranje/Project-X.git
cd Project-X
git checkout ccr-032639f1-ckq65a
```

## 3. Run the installer

```bash
sudo ./install.sh
```

Optional overrides (otherwise it generates strong random values and prints them):

```bash
sudo ADMIN_USER=admin ADMIN_PASS='YourStrongPass' DB_PASS='AnotherStrongPass' ./install.sh
# other overridable vars: DB_NAME, DB_USER, ADMIN_PORT (25500), CLIENT_PORT (25461), XTREAMUI_ZIP_URL
```

At the end it prints the **admin URL, admin credentials and DB password — save
them.** It installs MariaDB, system PHP-FPM 8.3 (with the `mysqli` shim + three
pools), ffmpeg, the rebuilt nginx, and vendors phpseclib for the stalker path.

## 4. Smoke tests

| Check | Command / action | Expected |
|-------|------------------|----------|
| Services up | `systemctl status xtreamcodes php8.3-fpm mariadb` | all `active` |
| Backend/nginx logs | `journalctl -u xtreamcodes -n 80 --no-pager` | no fatals |
| phpseclib vendored | `ls /home/xtreamcodes/iptv_xtream_codes/wwwdir/includes/vendor/autoload.php` | file exists |
| **Admin panel** | browse `http://YOUR_VPS_IP:25500/`, log in | dashboard loads |
| Client/stream API | `curl -sk http://YOUR_VPS_IP:25461/ | head` | responds |

Then validate the three things that can't be checked headless (see
`install/README.md`):

- **GeoIP** — open a page that shows client country; confirm it resolves.
- **Stalker / MAG login** — point a MAG/stalker client at the panel; confirm the
  token auth (the phpseclib Rijndael-256 path) works.
- **Live streaming** — add a test stream and confirm ffmpeg spawns and HLS plays.

> **Known issue to expect:** the two client-logging crons
> (`crons/crl_sync.php`, `crons/offline_cons.php`) have statement order
> scrambled by the original ionCube decode, so the `client_logs` /
> `user_activity` stats tables likely won't populate. This is functional, not a
> vulnerability — see `SECURITY-NOTES.md`. It's on the list to repair + verify
> live.

## 5. (Optional) Connect Claude to the VPS for live debugging

This cloud session can't reach your VPS, but you can run Claude **on** the VPS so
we continue live (it runs the installer, reads logs, iterates):

1. Install Claude Code on the VPS (see the Claude Code docs at
   `https://code.claude.com/docs`).
2. From the repo directory, start it:
   ```bash
   cd ~/Project-X
   claude                 # or: claude remote-control  (shows up in the Claude Code app)
   ```
3. That's a **fresh** session with empty context — point it at this branch and
   at `install/README.md` + `SECURITY-NOTES.md`, which capture every decision so
   far, and it can pick up the thread.

## Reset / uninstall

See the **Uninstall / reset** section in `install/README.md`.
