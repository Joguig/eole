#!/usr/bin/env python3

from socket import socket, AF_INET, SOCK_DGRAM
import os

s = socket(AF_INET, SOCK_DGRAM)
s.bind(('', 50000))
os.system('notify-send daemon-notify-send start')
while 1:
    data, addr = s.recvfrom(2048)
    if data:
        os.system('notify-send ' + data)
