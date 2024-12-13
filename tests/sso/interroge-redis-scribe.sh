#!/bin/bash

cd /usr/share/sso || exit 1

ciAptEole python-redis
#ciAptEole jq

python <<EOF
import config; 
print(config.REDIS_HOST)
print(config.REDIS_PORT)

import redis;
redis.Redis(host=config.REDIS_HOST, port=config.REDIS_PORT).keys('*')
#redis.Redis(host="192.168.0.24", port="9380").keys('*')
exit()
EOF
