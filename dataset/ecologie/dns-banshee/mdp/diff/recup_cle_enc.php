<?php

require '../utils/getDomainFromIP.php';

if (! isset($_GET['zz_ip'])) {
    $ip=$_SERVER['REMOTE_ADDR'];
    } //fin si isset
else
    {
    $ip=$_GET['zz_ip'];
    }

$domain=getDomainFromIP($ip);

$filename = "/home/mdp/diff/".$domain.".cle_enc";
$fd = fopen($filename, "r");
$contents = fread($fd, filesize ($filename));
echo $contents;
fclose($fd);

?>
