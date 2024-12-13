#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import sys
from monitor_eole_ci4 import MonitorEoleCi

monitor = MonitorEoleCi()
monitor.initZephir()
print(monitor.getIdServeur())
sys.exit (0)
