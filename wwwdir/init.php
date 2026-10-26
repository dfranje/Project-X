<?php
/*Rev:26.09.18r0*/

error_reporting(0);
ini_set('display_errors', 0);
define('MAIN_DIR', '/home/xtreamcodes/');
define('IPTV_ROOT_PATH', str_replace('\\', '/', dirname(__FILE__)) . '/');
define('IPTV_INCLUDES_PATH', IPTV_ROOT_PATH . 'includes' . '/');
define('IPTV_TEMPLATES_PATH', IPTV_ROOT_PATH . 'templates' . '/');
@ini_set('user_agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:9.0) Gecko/20100101 Firefox/9.0');
@ini_set('default_socket_timeout', 5);
define('IN_SCRIPT', true);
define('SOFTWARE', 'iptv');
define('SCRIPT_VERSION', '2.9.2');
define('IPTV_PANEL_DIR', MAIN_DIR . 'iptv_xtream_codes/');
define('BIN_PATH', IPTV_PANEL_DIR . 'bin/');
define('FFMPEG_PATH', file_exists(BIN_PATH . 'ffmpeg') ? BIN_PATH . 'ffmpeg' : '/usr/bin/ffmpeg');
define('FFPROBE_PATH', file_exists(BIN_PATH . 'ffprobe') ? BIN_PATH . 'ffprobe' : '/usr/bin/ffprobe');
define('YOUTUBE_PATH', BIN_PATH . 'youtube');
define('STREAMS_PATH', IPTV_PANEL_DIR . 'streams/');
define('MOVIES_IMAGES', IPTV_PANEL_DIR . 'wwwdir/images/');
define('MOVIES_PATH', IPTV_PANEL_DIR . 'movies/');
define('CREATED_CHANNELS', IPTV_PANEL_DIR . 'created_channels/');
define('CRON_PATH', IPTV_PANEL_DIR . 'crons/');
define('PHP_BIN', '/home/xtreamcodes/iptv_xtream_codes/php/bin/php');
define('ASYNC_DIR', IPTV_PANEL_DIR . 'async_incs/');
define('TMP_DIR', IPTV_PANEL_DIR . 'tmp/');
define('TOOLS_PATH', IPTV_PANEL_DIR . 'tools/');
define('IPTV_CLIENT_AREA', IPTV_PANEL_DIR . 'wwwdir/client_area/');
define('IPTV_CLIENT_AREA_TEMPLATES_PATH', IPTV_CLIENT_AREA . 'templates/');
define('TV_ARCHIVE', IPTV_PANEL_DIR . 'tv_archive/');
define('DELAY_STREAM', IPTV_PANEL_DIR . 'delay/');
define('SIGNALS_PATH', IPTV_PANEL_DIR . 'signals/');
define('KEY_CRYPT', 'dd2dbe5c8087454e7f3e341d728c3940');
define('FFMPEG_FONTS_PATH', SIGNALS_PATH . 'free-sans.ttf');
define('CONFIG_CRYPT_KEY', '5709650b0d7806074842c6de575025b1');
define('RESTART_TAKE_CACHE', 5);
define('TOTAL_SAVES_DROP', 6);
define('CLOSE_OPEN_CONS_PATH', TMP_DIR . 'opened_cons/');
define('ENIGMA2_PLUGIN_DIR', MOVIES_IMAGES . 'enigma2/');
define('GEOIP2_FILENAME', IPTV_PANEL_DIR . 'GeoLite2.mmdb');
if (!defined('USE_CACHE')) {
    define('USE_CACHE', true);
}
if (!defined('FETCH_BOUQUETS')) {
    define('FETCH_BOUQUETS', true);
}
define('CACHE_STREAMS', false);
define('CACHE_STREAMS_TIME', 10);
define('STREAM_TYPE', array('live', 'series', 'movie', 'created_live', 'radio_streams'));
// The `get_real_ip_client` header is only trusted when the request comes from one of these
// networks (loopback, private ranges and Cloudflare, see https://www.cloudflare.com/ips/).
// Extra proxies can be listed one CIDR per line in TRUSTED_PROXIES_FILE.
define('TRUSTED_PROXIES', array('127.0.0.0/8', '::1/128', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', 'fc00::/7', '173.245.48.0/20', '103.21.244.0/22', '103.22.200.0/22', '103.31.4.0/22', '141.101.64.0/18', '108.162.192.0/18', '190.93.240.0/20', '188.114.96.0/20', '197.234.240.0/22', '198.41.128.0/17', '162.158.0.0/15', '104.16.0.0/13', '104.24.0.0/14', '172.64.0.0/13', '131.0.72.0/22', '2400:cb00::/32', '2606:4700::/32', '2803:f800::/32', '2405:b500::/32', '2405:8100::/32', '2a06:98c0::/29', '2c0f:f248::/32'));
define('TRUSTED_PROXIES_FILE', IPTV_PANEL_DIR . 'trusted_proxies');
require MAIN_DIR . 'iptv_xtream_codes/xfirewall.php';
require IPTV_INCLUDES_PATH . 'functions.php';
require IPTV_INCLUDES_PATH . 'lib.php';
require IPTV_INCLUDES_PATH . 'mysql.php';
require IPTV_INCLUDES_PATH . 'streaming.php';
require IPTV_INCLUDES_PATH . 'servers.php';
require IPTV_INCLUDES_PATH . 'stream.php';
require IPTV_ROOT_PATH . 'langs/English.php';
$_INFO = array();
if (file_exists(IPTV_PANEL_DIR . 'config')) {
    $_INFO = json_decode(EAAB451Ef7a60C6D480E43B6c15A14A1(base64_decode(file_get_contents(IPTV_PANEL_DIR . 'config')), CONFIG_CRYPT_KEY), true);
    define('SERVER_ID', $_INFO['server_id']);
} else {
    die('no config found');
}
$f566700a43ee8e1f0412fe10fbdf03df = new ipTV_db($_INFO['db_user'], $_INFO['db_pass'], $_INFO['db_name'], $_INFO['host'], $_INFO['db_port'], empty($_INFO['pconnect']) ? false : true, isset($f828fbd7943068a1cd53cba5fe86120c) ? true : false);
A78bF8d35765be2408C50712ce7a43aD::$ipTV_db =& $f566700a43ee8e1f0412fe10fbdf03df;
CD89785224751cCa8017139daf9E891e::$ipTV_db =& $f566700a43ee8e1f0412fe10fbdf03df;
e3cF480c172E8B47FE10857C2a5Aeb48::$ipTV_db =& $f566700a43ee8e1f0412fe10fbdf03df;
A78Bf8D35765be2408c50712CE7a43AD::fAB9232Faa11c27667E20D2B25c46266();
include IPTV_INCLUDES_PATH . 'geo/Reader.php';
include IPTV_INCLUDES_PATH . 'geo/Decoder.php';
include IPTV_INCLUDES_PATH . 'geo/Util.php';
include IPTV_INCLUDES_PATH . 'geo/Metadata.php';
$D3dfbeed696b35ae7f2e1ad4fa3c7477 = array('clients_live.php', 'clients_movie.php', 'timeshift.php', 'admin_live.php', 'admin_movie.php', 'xmltv.php', 'panel_api.php', 'enigma2.php', 'portal.php', 'get.php');
if (empty($argc)) {
    if (!in_array(basename($_SERVER['SCRIPT_FILENAME']), $D3dfbeed696b35ae7f2e1ad4fa3c7477)) {
        D9f93b7C177E377D0bBFe315eaeae505();
    }
}
?>
