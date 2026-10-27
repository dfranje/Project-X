#!/usr/bin/env bash
#
# Project-X / XtreamUI — full test install for a CLEAN Ubuntu 24.04 server.
#
# WHAT IT DOES
#   - Installs MariaDB, PHP-FPM + extensions, ffmpeg, nginx deps.
#   - Lays out /home/xtreamcodes/iptv_xtream_codes with the (security-hardened)
#     backend from THIS repo, plus the XtreamUI admin panel with the fixes in
#     install/admin-security.patch applied.
#   - Creates the database, schema, an admin account and the encrypted config.
#   - Wires up php-fpm pools, nginx and a systemd unit.
#
# IMPORTANT — READ install/README.md FIRST.
#   * Authorisation: run this only on a server you own/control, for content you
#     are licensed to distribute. It installs server software and adds no
#     content; what you stream is your responsibility.
#   * This is a TEST/best-effort installer. The code targets PHP 7.2; the
#     bundled PHP 7.2/nginx binaries do NOT run on Ubuntu 24.04, so we use the
#     system PHP (+ a mysqli compatibility shim) and this repo's rebuilt nginx.
#     The admin panel works well; parts of the streaming backend (GeoIP under
#     PHP 8.x, etc.) may not. Test on a THROWAWAY VPS, never straight to prod.
#
set -euo pipefail

# ------------------------------------------------------------------ settings --
XC_USER="xtreamcodes"
INSTALL_DIR="/home/${XC_USER}/iptv_xtream_codes"
DB_NAME="${DB_NAME:-xtream_iptvpro}"
DB_USER="${DB_USER:-xtream}"
DB_PASS="${DB_PASS:-$(openssl rand -hex 16)}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-14)}"
ADMIN_PORT="${ADMIN_PORT:-25500}"          # XtreamUI admin panel
CLIENT_PORT="${CLIENT_PORT:-25461}"        # streaming/client API (from nginx.conf)
XTREAMUI_ZIP_URL="${XTREAMUI_ZIP_URL:-https://github.com/emre1393/xtreamui_mirror/releases/latest/download/release_22f.zip}"
CONFIG_CRYPT_KEY="5709650b0d7806074842c6de575025b1"  # matches wwwdir/init.php & admin/functions.php
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------ preflight --
[ "$(id -u)" -eq 0 ] || die "Run as root (sudo ./install.sh)."
. /etc/os-release 2>/dev/null || true
[ "${VERSION_ID:-}" = "24.04" ] || warn "Tested on Ubuntu 24.04; detected '${VERSION_ID:-unknown}'. Continuing."
[ -d "${REPO_DIR}/wwwdir" ] || die "Run this from inside the cloned repo (wwwdir/ not found at ${REPO_DIR})."
[ -f "${REPO_DIR}/install/admin-security.patch" ] || die "install/admin-security.patch missing."
command -v curl >/dev/null || { apt-get update -q && apt-get install -y -q curl; }

# ------------------------------------------------------------- dependencies ---
log "Installing packages (MariaDB, PHP-FPM, ffmpeg, tools)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q \
  mariadb-server \
  php-fpm php-cli php-mysql php-gd php-curl php-mbstring php-xml php-bcmath php-zip \
  ffmpeg unzip git wget curl openssl cron ca-certificates

# Detect the installed PHP-FPM version (Ubuntu 24.04 -> 8.3).
PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)"
[ -n "${PHP_VER}" ] && [ -d "/etc/php/${PHP_VER}/fpm" ] || die "php-fpm did not install correctly."
FPM_SVC="php${PHP_VER}-fpm"
log "Using PHP ${PHP_VER} (${FPM_SVC})."
if [ "${PHP_VER%%.*}" -ge 8 ]; then
  warn "This code targets PHP 7.2. PHP ${PHP_VER} works for the admin panel; some backend features may not. PHP 7.4 (ondrej/php PPA) is closer to the original."
fi

# ------------------------------------------------------------------- user ------
log "Creating system user '${XC_USER}'..."
id "${XC_USER}" >/dev/null 2>&1 || useradd -m -s /usr/sbin/nologin "${XC_USER}"

# -------------------------------------------------------------- layout ---------
log "Laying out ${INSTALL_DIR} from the repo..."
mkdir -p "${INSTALL_DIR}"
for item in wwwdir crons tools nginx nginx_rtmp signals bin GeoLite2.mmdb database.sql start_services.sh xfirewall.php kill_pids; do
  [ -e "${REPO_DIR}/${item}" ] && cp -a "${REPO_DIR}/${item}" "${INSTALL_DIR}/"
done
# php dir holds the fpm sockets/pids and the sock path nginx expects
mkdir -p "${INSTALL_DIR}/php" \
         "${INSTALL_DIR}/tmp/opened_cons" "${INSTALL_DIR}/streams" "${INSTALL_DIR}/movies" \
         "${INSTALL_DIR}/created_channels" "${INSTALL_DIR}/delay" "${INSTALL_DIR}/tv_archive" \
         "${INSTALL_DIR}/logs" "${INSTALL_DIR}/async_incs" "${INSTALL_DIR}/signals"
chmod +x "${INSTALL_DIR}/bin/"* "${INSTALL_DIR}/nginx/sbin/nginx" "${INSTALL_DIR}/nginx_rtmp/sbin/nginx_rtmp" 2>/dev/null || true

# ------------------------------------------------------- admin panel + fixes ---
log "Downloading XtreamUI admin panel and applying security fixes..."
TMP_ZIP="$(mktemp -d)"
curl -fsSL --retry 3 -o "${TMP_ZIP}/x.zip" "${XTREAMUI_ZIP_URL}"
unzip -q "${TMP_ZIP}/x.zip" -d "${TMP_ZIP}/x"
# The patch is rooted at the XtreamUI tree; apply it there, then copy admin/ out.
( cd "${TMP_ZIP}/x/XtreamUI-master" && git init -q . && git apply --ignore-whitespace --whitespace=nowarn -p1 "${REPO_DIR}/install/admin-security.patch" ) \
  || die "Failed to apply admin-security.patch to XtreamUI."
rm -rf "${INSTALL_DIR}/admin"
cp -a "${TMP_ZIP}/x/XtreamUI-master/admin" "${INSTALL_DIR}/admin"
# pull in the extra server-side tools the admin expects, if present
for extra in isp adtools pytools; do
  [ -d "${TMP_ZIP}/x/XtreamUI-master/${extra}" ] && cp -a "${TMP_ZIP}/x/XtreamUI-master/${extra}" "${INSTALL_DIR}/"
done
rm -rf "${TMP_ZIP}"

# --------------------------------------------------------------- database ------
log "Configuring MariaDB..."
systemctl enable --now mariadb >/dev/null 2>&1 || service mariadb start
ADMIN_HASH="$(php -r 'echo crypt($argv[1], sprintf("\$6\$rounds=20000\$%s\$", substr(bin2hex(random_bytes(16)),0,16)));' "${ADMIN_PASS}")"

mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# Load the schema only once (skip if already populated).
if [ "$(mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}'")" -lt 5 ]; then
  mysql "${DB_NAME}" < "${INSTALL_DIR}/database.sql"
fi

mysql "${DB_NAME}" <<SQL
SET SESSION sql_mode='';
CREATE TABLE IF NOT EXISTS \`admin_settings\` (\`type\` varchar(191) NOT NULL, \`value\` text DEFAULT NULL, PRIMARY KEY (\`type\`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO \`admin_settings\` (\`type\`,\`value\`) VALUES
 ('login_flood','0'),('pass_length','0'),('dark_mode_login','0'),('recaptcha_enable','0'),('version','22F'),('geolite2_version','0')
 ON DUPLICATE KEY UPDATE \`value\`=VALUES(\`value\`);
INSERT INTO \`reg_users\`
 (\`username\`,\`password\`,\`email\`,\`member_group_id\`,\`verified\`,\`credits\`,\`status\`,\`date_registered\`,\`default_lang\`,\`notes\`,\`ip\`,\`verify_key\`,\`reseller_dns\`,\`owner_id\`,\`override_packages\`,\`google_2fa_sec\`)
 VALUES ('${ADMIN_USER}','${ADMIN_HASH}','admin@localhost',1,1,99999,1,UNIX_TIMESTAMP(),'en','','127.0.0.1','','',0,'','')
 ON DUPLICATE KEY UPDATE \`password\`=VALUES(\`password\`);
SQL

# ------------------------------------------------------------- config file -----
log "Writing encrypted config..."
DB_NAME="${DB_NAME}" DB_USER="${DB_USER}" DB_PASS="${DB_PASS}" INSTALL_DIR="${INSTALL_DIR}" KEY="${CONFIG_CRYPT_KEY}" \
php -r '
$info = array("host"=>"127.0.0.1","db_user"=>getenv("DB_USER"),"db_pass"=>getenv("DB_PASS"),"db_name"=>getenv("DB_NAME"),"db_port"=>3306,"server_id"=>1,"pconnect"=>0);
$key = getenv("KEY"); $plain = json_encode($info); $out="";
for($i=0;$i<strlen($plain);$i++){ $out .= chr(ord($plain[$i]) ^ ord($key[$i % strlen($key)])); }
file_put_contents(getenv("INSTALL_DIR")."/config", base64_encode($out));
'

# ----------------------------------------------------------- php-fpm pools -----
log "Configuring php-fpm pools + mysqli compatibility shim..."
SHIM="${INSTALL_DIR}/php/compat_prepend.php"
printf '<?php if (function_exists("mysqli_report")) { @mysqli_report(MYSQLI_REPORT_OFF); }\n' > "${SHIM}"
# The backend's nginx balance.conf load-balances across three unix sockets.
for sock in VaiIb8 JdlJXm CWcfSP; do
  cat > "/etc/php/${PHP_VER}/fpm/pool.d/xc_${sock}.conf" <<POOL
[xc_${sock}]
user = ${XC_USER}
group = ${XC_USER}
listen = ${INSTALL_DIR}/php/${sock}.sock
listen.owner = ${XC_USER}
listen.group = ${XC_USER}
listen.mode = 0660
pm = ondemand
pm.max_children = 200
pm.process_idle_timeout = 10s
php_admin_value[auto_prepend_file] = ${SHIM}
php_admin_value[allow_url_fopen] = On
php_admin_value[display_errors] = Off
security.limit_extensions = .php
POOL
done
# Admin panel runs as its own default pool (www) too; make sure www points at xtreamcodes-readable paths.
systemctl restart "${FPM_SVC}"

# --------------------------------------------------------------- nginx ---------
log "Configuring nginx (client API + admin panel)..."
# Client/stream API uses this repo's hardened nginx.conf (already at nginx/conf/).
# Add an admin-panel server block that proxies .php to one of the fpm sockets.
ADMIN_CONF="${INSTALL_DIR}/nginx/conf/admin.conf"
cat > "${ADMIN_CONF}" <<NGX
server {
    listen ${ADMIN_PORT};
    root ${INSTALL_DIR}/admin;
    index index.php;
    server_tokens off;
    client_max_body_size 100m;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_pass unix:${INSTALL_DIR}/php/VaiIb8.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
}
NGX
# Include admin.conf from the main nginx http{} block if not already included.
grep -q 'admin.conf' "${INSTALL_DIR}/nginx/conf/nginx.conf" || \
  sed -i "s#include balance.conf;#include balance.conf;\n\tinclude admin.conf;#" "${INSTALL_DIR}/nginx/conf/nginx.conf"

# Generate the TLS cert the client API expects (never shipped in the repo).
if [ ! -s "${INSTALL_DIR}/nginx/conf/server.key" ]; then
  ( umask 077; openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=iptv-panel" \
      -keyout "${INSTALL_DIR}/nginx/conf/server.key" -out "${INSTALL_DIR}/nginx/conf/server.crt" )
fi

# ------------------------------------------------------------ permissions ------
log "Setting ownership..."
chown -R "${XC_USER}:${XC_USER}" "/home/${XC_USER}"

# ------------------------------------------------------------- systemd ---------
log "Installing systemd service..."
cat > /etc/systemd/system/xtreamcodes.service <<UNIT
[Unit]
Description=Project-X / XtreamUI IPTV panel
After=network.target mariadb.service ${FPM_SVC}.service
Wants=mariadb.service ${FPM_SVC}.service

[Service]
Type=forking
ExecStart=${INSTALL_DIR}/nginx/sbin/nginx
ExecStartPost=/bin/sh -c '${INSTALL_DIR}/nginx_rtmp/sbin/nginx_rtmp || true'
ExecStop=${INSTALL_DIR}/nginx/sbin/nginx -s stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
mkdir -p "${INSTALL_DIR}/tmp/client_temp" "${INSTALL_DIR}/tmp/proxy_temp" "${INSTALL_DIR}/tmp/fastcgi_temp" "${INSTALL_DIR}/tmp/uwsgi_temp" "${INSTALL_DIR}/tmp/scgi_temp"
chown -R "${XC_USER}:${XC_USER}" "${INSTALL_DIR}/tmp"
systemctl daemon-reload
systemctl enable xtreamcodes >/dev/null 2>&1 || true

# Validate the nginx config before starting.
if "${INSTALL_DIR}/nginx/sbin/nginx" -t -p "${INSTALL_DIR}/nginx" -c "${INSTALL_DIR}/nginx/conf/nginx.conf" 2>/tmp/nginx_test.log; then
  systemctl restart xtreamcodes || warn "systemd start failed; check: journalctl -u xtreamcodes"
else
  warn "nginx -t failed (see /tmp/nginx_test.log). Fix the config, then: systemctl start xtreamcodes"
fi

# ------------------------------------------------------------- summary ---------
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
cat <<DONE

============================================================
 Install finished (best-effort).  Test, don't trust blindly.
============================================================
 Admin panel : http://${IP:-SERVER_IP}:${ADMIN_PORT}/
   username  : ${ADMIN_USER}
   password  : ${ADMIN_PASS}
 Client API  : http://${IP:-SERVER_IP}:${CLIENT_PORT}/  (HTTPS on next port)
 Install dir : ${INSTALL_DIR}
 Database    : ${DB_NAME}  (user ${DB_USER})
 DB password : ${DB_PASS}
------------------------------------------------------------
 Services:   systemctl status xtreamcodes ${FPM_SVC} mariadb
 Logs:       journalctl -u xtreamcodes  |  ${INSTALL_DIR}/logs/
 Notes:      see install/README.md for PHP-version caveats and
             what is expected NOT to work on Ubuntu 24.04 / PHP ${PHP_VER}.
============================================================
 SAVE THESE CREDENTIALS NOW.
============================================================
DONE
