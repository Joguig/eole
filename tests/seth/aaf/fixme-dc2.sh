#!/bin/bash

echo "FIXME"
sed -i 's@#!/bin/bash@#!/bin/bash -x@g' /usr/share/eole/postservice/24-test-synchro-with-time-reference
exit 0
