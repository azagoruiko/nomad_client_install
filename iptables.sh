iptables -A INPUT -i tun0 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --destination-port 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --destination-port 22 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --destination-port 443 -j ACCEPT
iptables -A INPUT -i eth0 -p udp --destination-port 1194 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --destination-port 943 -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i eth0 -j DROP
