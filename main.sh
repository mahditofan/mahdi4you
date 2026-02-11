#!/bin/bash

GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

enable_sysctl() {
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter
}

create_tunnel() {

read -p "Enter Peer Public IP: " PEER_IP
read -p "Are you Server 1 or 2? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
    LOCAL_TUN="100.64.0.1"
    REMOTE_TUN="100.64.0.2"
else
    LOCAL_TUN="100.64.0.2"
    REMOTE_TUN="100.64.0.1"
fi

echo -e "${GREEN}Creating Geneve Tunnel...${NC}"

ip link add gnv0 type geneve id 100 remote $PEER_IP dstport 6081 dev $INTERFACE
ip addr add $LOCAL_TUN/30 dev gnv0
ip link set gnv0 mtu 1380
ip link set gnv0 up

iptables -A INPUT -p udp --dport 6081 -j ACCEPT
iptables -A FORWARD -i gnv0 -j ACCEPT
iptables -A FORWARD -o gnv0 -j ACCEPT

enable_sysctl

echo -e "${GREEN}Tunnel Ready!${NC}"
echo "Local Tunnel IP: $LOCAL_TUN"
echo "Remote Tunnel IP: $REMOTE_TUN"
}

delete_tunnel() {
ip link del gnv0 2>/dev/null
iptables -D INPUT -p udp --dport 6081 -j ACCEPT 2>/dev/null
echo -e "${RED}Tunnel Deleted.${NC}"
}

while true; do
clear
echo -e "${GREEN}"
echo "======================================"
echo "         mahdi4you Geneve Pro"
echo "======================================"
echo -e "${NC}"
echo "1) Create Tunnel"
echo "2) Delete Tunnel"
echo "3) Exit"
echo ""
read -p "Choose: " OPTION

case $OPTION in
1)
create_tunnel
read -p "Press Enter..."
;;
2)
delete_tunnel
read -p "Press Enter..."
;;
3)
exit
;;
*)
echo "Invalid Option"
sleep 2
;;
esac
done
