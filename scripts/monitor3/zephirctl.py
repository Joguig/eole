#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import sys
from monitor_eole_ci4 import MonitorEoleCi

if __name__ == '__main__':
    if len(sys.argv) == 1:
        sys.exit(1)
    monitor = MonitorEoleCi()
    monitor.initZephir()
    monitor.zephirCtl(sys.argv)
    sys.exit (0)
