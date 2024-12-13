#!/usr/bin/env python3
# coding: utf-8
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,C0325,R0902,R0904,R0912,R0911

import sys

for line in sys.stdin:
    line = line.replace('\n', '')
    nbcar = len(line)
    if nbcar == 0:
        sys.stdout.write('\n\r')
        sys.stdout.write(line)
    else:
        if line[0] == ' ':
            sys.stdout.write(line[1:])
        else:
            sys.stdout.write('\n\r')
            sys.stdout.write(line)
sys.stdout.write('\n')