#!/bin/bash

find / -newer /root/a ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" ! -path "/mnt/*"