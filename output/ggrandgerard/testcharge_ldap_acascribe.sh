for i in $(seq 1 2000); 
do 
   telnet 192.168.0.26 389 &
done
