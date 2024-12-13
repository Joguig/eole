echo "TCP Open"
ss -tapn | grep -E ":(389|636)" | grep -v 'LISTEN' | awk '{print $5;}' | cut -d ':' -f 1 | sort | uniq -c

echo "LSOF"
lsof -p $(pidof slapd) |wc -l
