#!/bin/bash

ntpq -c 'as' | sed -e '/^$/d' -e '/ind.*/d' -e '/==*/d' -e 's/\s\+/ /g' -e 's/^\s\+//' | cut -f2 -d ' '
