#!/bin/bash

echo "* kill xvfb"
XVFB_PID=$(cat /root/xvfb.pid)
kill -9 "$XVFB_PID"

exit 0
