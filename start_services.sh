#! /bin/bash
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
sleep 1
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
sleep 1
kill $(ps aux | grep 'xtreamcodes' | grep -v grep | grep -v 'start_services.sh' | awk '{print $2}') 2>/dev/null
sleep 4
sudo -u xtreamcodes /home/xtreamcodes/iptv_xtream_codes/php/bin/php /home/xtreamcodes/iptv_xtream_codes/crons/setup_cache.php
sudo -u xtreamcodes /home/xtreamcodes/iptv_xtream_codes/php/bin/php /home/xtreamcodes/iptv_xtream_codes/tools/signal_receiver.php >/dev/null 2>/dev/null &
sudo -u xtreamcodes /home/xtreamcodes/iptv_xtream_codes/php/bin/php /home/xtreamcodes/iptv_xtream_codes/tools/pipe_reader.php >/dev/null 2>/dev/null &
chown -R xtreamcodes:xtreamcodes /home/xtreamcodes
sleep 4
# Generate a self-signed TLS cert/key on first start. The key is never stored
# in the repository; see .gitignore. Replace with a CA-issued cert in production.
XC_CONF=/home/xtreamcodes/iptv_xtream_codes/nginx/conf
if [ ! -s "$XC_CONF/server.key" ] || [ ! -s "$XC_CONF/server.crt" ]; then
    ( umask 077; openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$XC_CONF/server.key" -out "$XC_CONF/server.crt" \
        -days 3650 -subj "/CN=iptv-panel" )
    chmod 600 "$XC_CONF/server.key"
    chmod 644 "$XC_CONF/server.crt"
    chown xtreamcodes:xtreamcodes "$XC_CONF/server.key" "$XC_CONF/server.crt"
fi
/home/xtreamcodes/iptv_xtream_codes/nginx_rtmp/sbin/nginx_rtmp
/home/xtreamcodes/iptv_xtream_codes/nginx/sbin/nginx
start-stop-daemon --start --quiet --pidfile /home/xtreamcodes/iptv_xtream_codes/php/VaiIb8.pid --exec /home/xtreamcodes/iptv_xtream_codes/php/sbin/php-fpm -- --daemonize --fpm-config /home/xtreamcodes/iptv_xtream_codes/php/etc/VaiIb8.conf
start-stop-daemon --start --quiet --pidfile /home/xtreamcodes/iptv_xtream_codes/php/JdlJXm.pid --exec /home/xtreamcodes/iptv_xtream_codes/php/sbin/php-fpm -- --daemonize --fpm-config /home/xtreamcodes/iptv_xtream_codes/php/etc/JdlJXm.conf
start-stop-daemon --start --quiet --pidfile /home/xtreamcodes/iptv_xtream_codes/php/CWcfSP.pid --exec /home/xtreamcodes/iptv_xtream_codes/php/sbin/php-fpm -- --daemonize --fpm-config /home/xtreamcodes/iptv_xtream_codes/php/etc/CWcfSP.conf
