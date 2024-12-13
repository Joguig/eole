#!/bin/bash

case "$1" in
   status)
       sed -i 's/\(ups\.status: \).*/\1/' /etc/nut/dummy.dev
       ;;
       
   battery-charge)
       sed -i "s/\(battery\.charge: \)[0-9]*/\119/" /etc/nut/dummy.dev
       ;;

   replace-battery)
       sed -i "s/\(ups\.status: \).*/\1ALARM OL/" /etc/nut/dummy.dev
       sed -i "/ups\.delay\.shutdown/i\ups.alarm: Replace battery! No battery installed!" /etc/nut/dummy.dev
       ;;
       
   alarm)
       sed -i "s/\(ups\.status: \).*/\1OL/" /etc/nut/dummy.dev
       sed -i "s/\(battery\.charge: \)[0-9]*/\193/" /etc/nut/dummy.dev
       sed -i "/ups\.alarm.*/d" /etc/nut/dummy.dev
       ;;
esac
