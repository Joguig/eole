#!/bin/bash
if [ ! -f /tmp/old_rules ] 
then
	iptables -S >/tmp/old_rules
fi 

echo "echo 'toutes les regles'" 
(
echo "iptables -F "
echo "iptables -X "
echo "iptables -t nat -F "
echo "iptables -t nat -X "
echo "iptables -t mangle -F "
echo "iptables -t mangle -X "
echo "iptables -P INPUT ACCEPT "
echo "iptables -P FORWARD ACCEPT "
echo "iptables -P OUTPUT ACCEPT "
echo "echo 'les regles de log'"
echo "iptables -N LOGGER_DROP"
echo "iptables -I LOGGER_DROP -j DROP"
echo "iptables -I LOGGER_DROP -j LOG --log-prefix \"DROPPED:  \""
echo "echo 'les regles EOLE'"
sed -e "s/-j DROP/-j LOGGER_DROP/" -e "s/^/iptables /" </tmp/old_rules
) >/tmp/new_rules
cat /tmp/new_rules

echo "Lancer 'bash /tmp/new_rules'"
echo "Puis 'tail -f /var/log/rsyslog/local/kernel/kernel.warning.log' "

