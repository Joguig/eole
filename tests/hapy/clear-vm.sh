#!/bin/bash

onevm terminate amon.etb1.lan --hard
onevm list
onetemplate delete amon.etb1.lan --recursive
onetemplate list
oneimage delete amon.etb1.lan-disk-0
oneimage list 