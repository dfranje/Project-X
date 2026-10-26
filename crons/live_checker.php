<?php
/*Rev:26.09.18r0*/

if (!@$argc) {
    die(0);
}
require str_replace('\\', '/', dirname($argv[0])) . '/../wwwdir/init.php';
cli_set_process_title('XtreamCodes[Live Checker]');
$Ed756578679cd59095dfa81f228e8b38 = TMP_DIR . md5(aFFB052CCA396818d81004ff99Db49AA() . __FILE__);
bBd9e78AC32626e138e758E840305A7c($Ed756578679cd59095dfa81f228e8b38);
$B5dac75572776cad02b4f375a2781a87 = array();
$f566700a43ee8e1f0412fe10fbdf03df->query('SELECT
                          t2.stream_display_name,
                          t1.stream_id,
                          t1.monitor_pid,
                          t1.on_demand,
                          t1.server_stream_id,
                          t1.pid,
                          clients.online_clients
                        FROM
                          `streams_sys` t1
                        INNER JOIN `streams` t2 ON t2.id = t1.stream_id AND t2.direct_source = 0
                        INNER JOIN `streams_types` t3 ON t3.type_id = t2.type
                        LEFT JOIN
                          (
                          SELECT
                            stream_id,
                            COUNT(*) as online_clients
                          FROM
                            `user_activity_now`
                          WHERE `server_id` = \'%d\'
                          GROUP BY
                            stream_id
                        ) AS clients
                        ON
                          clients.stream_id = t1.stream_id
                        WHERE
                          (
                            t1.pid IS NOT NULL OR t1.stream_status <> 0 OR t1.to_analyze = 1
                          ) AND t1.server_id = \'%d\' AND t3.live = 1', SERVER_ID, SERVER_ID);
if (0 < $f566700a43ee8e1f0412fe10fbdf03df->d1e5ce3B87Bb868b9e6Efd39AA355A4f()) {
    $D465fc5085f41251c6fa7c77b8333b0f = $f566700a43ee8e1f0412fe10fbdf03df->C126FD559932f625cDF6098d86C63880();
    foreach ($D465fc5085f41251c6fa7c77b8333b0f as $c3a18c26bfa971a25d2e6ada870ff735) {
        $B5dac75572776cad02b4f375a2781a87[] = $c3a18c26bfa971a25d2e6ada870ff735['stream_id'];
        if (cd89785224751CCA8017139dAf9e891e::CDA72BC41975c364bc559dB25648a5b2($c3a18c26bfa971a25d2e6ada870ff735['monitor_pid'], $c3a18c26bfa971a25d2e6ada870ff735['stream_id'])) {
            if (!($c3a18c26bfa971a25d2e6ada870ff735['on_demand'] == 1 && $c3a18c26bfa971a25d2e6ada870ff735['online_clients'] == 0)) {
                $Bb37b848bec813a5c13ea0b018962c40 = STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.m3u8';
                if (cD89785224751CCa8017139DaF9e891E::bcAa9B8a7B46Eb36cd507a218FA64474($c3a18c26bfa971a25d2e6ada870ff735['pid'], $c3a18c26bfa971a25d2e6ada870ff735['stream_id']) && file_exists($Bb37b848bec813a5c13ea0b018962c40)) {
                    $e423b354d93563733645ada7277d4ad0 = Cd89785224751cCa8017139DAf9E891E::d28ef1088dd95BE31717Ae0F5fA2A158('live', STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.m3u8');
                    $e5c171779f469240e4b97461d59ce3d2 = file_exists(STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.progress') ? json_decode(file_get_contents(STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.progress'), true) : array();
                    if (file_exists(STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.pid')) {
                        $Bc7d327b1510891329ca9859db27320f = intval(file_get_contents(STREAMS_PATH . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.pid'));
                    } else {
                        $Bc7d327b1510891329ca9859db27320f = intval(shell_exec('ps aux | grep -v grep | grep \'/' . $c3a18c26bfa971a25d2e6ada870ff735['stream_id'] . '_.m3u8\' | awk \'{print $2}\''));
                    }
                    if ($c3a18c26bfa971a25d2e6ada870ff735['pid'] != $Bc7d327b1510891329ca9859db27320f) {
                        $f566700a43ee8e1f0412fe10fbdf03df->query('UPDATE `streams_sys` SET `pid` = \'%d\',`progress_info` = \'%s\',`bitrate` = \'%d\' WHERE `server_stream_id` = \'%d\'', $Bc7d327b1510891329ca9859db27320f, json_encode($e5c171779f469240e4b97461d59ce3d2), $e423b354d93563733645ada7277d4ad0, $c3a18c26bfa971a25d2e6ada870ff735['server_stream_id']);
                    } else {
                        $f566700a43ee8e1f0412fe10fbdf03df->query('UPDATE `streams_sys` SET `progress_info` = \'%s\',`bitrate` = \'%d\' WHERE `server_stream_id` = \'%d\'', json_encode($e5c171779f469240e4b97461d59ce3d2), $e423b354d93563733645ada7277d4ad0, $c3a18c26bfa971a25d2e6ada870ff735['server_stream_id']);
                    }
                }
            } else {
                E3cf480C172E8B47Fe10857C2A5AeB48::C27C26b9Ed331706a4c3f0292142Fb52($c3a18c26bfa971a25d2e6ada870ff735['stream_id'], true);
            }
        } else {
            e3CF480c172E8b47fe10857C2a5AeB48::e79092731573697c16a932c339D0a101($c3a18c26bfa971a25d2e6ada870ff735['stream_id']);
            usleep(50000);
        }
    }
}
$fbbf53be35fd65b950965d4d685168ba = shell_exec('ps aux | grep XtreamCodes');
if (preg_match_all('/XtreamCodes\\[(.*)\\]/', $fbbf53be35fd65b950965d4d685168ba, $ae37877cee3bc97c8cfa6ec5843993ed)) {
    $Acdfe077907272ac319d15f08f47d5be = array_diff($ae37877cee3bc97c8cfa6ec5843993ed[1], $B5dac75572776cad02b4f375a2781a87);
    foreach ($Acdfe077907272ac319d15f08f47d5be as $ba85d77d367dcebfcc2a3db9e83bb581) {
        if (!is_numeric($ba85d77d367dcebfcc2a3db9e83bb581)) {
            continue;
        }
        shell_exec('kill -9 `ps -ef | grep \'/' . $ba85d77d367dcebfcc2a3db9e83bb581 . '_.m3u8\\|XtreamCodes\\[' . $ba85d77d367dcebfcc2a3db9e83bb581 . '\\]\' | grep -v grep | awk \'{print $2}\'`;');
        shell_exec('rm -f ' . STREAMS_PATH . $ba85d77d367dcebfcc2a3db9e83bb581 . '_*');
    }
}
if (!(!is_file(TMP_DIR . 'cache_x') || 1200 <= time() - filemtime(TMP_DIR . 'cache_x'))) {
    // Removed the xtream-codes.com gt_bl.php "blacklist" fetch: the service is
    // defunct and its response was passed straight to unserialize() (PHP object
    // injection). cache_x is no longer populated from the network.
    @unlink($Ed756578679cd59095dfa81f228e8b38);
}
?>
