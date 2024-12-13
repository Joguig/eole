<?php

function getDomainFromIP($ip)
{
    $domainMap = [];
    if (($handle = fopen("../utils/liste-ecdl", "r")) !== FALSE) {
        while (($data = fgetcsv($handle, 1000, ":")) !== FALSE) {
            //print_r($data);
            $domainMap[$data[1]] = $data[0];
	}
	//print_r($domainMap);
	fclose($handle);
    }
    return $domainMap[$ip];
}
