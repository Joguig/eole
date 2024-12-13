systemd-analyze plot >/tmp/plot
rm -f /tmp/filtre
grep device </tmp/plot >/tmp/plot.filtre
awk -F'[ <>".]' '{ print $13;}' </tmp/plot.filtre | while read -r Y ;
do
    y1=$(( Y - 14))
    echo "y=\"${Y}.000\"" >>/tmp/filtre
    echo "y=\"${y1}.000\"" >>/tmp/filtre
done
grep -v -f /tmp/filtre /tmp/plot

