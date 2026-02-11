#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
NC="\e[0m"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

enable_sysctl() {
    sysctl -w net.ipv4.ip_forward=1 >/dev/null
    sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
    sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
}

create_tunnel() {

read -p "Enter Peer Public IP: " PEER
read -p "Are you Server 1 or 2? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
    LOCAL="172.31.255.1"
    REMOTE="172.31.255.2"
else
    LOCAL="172.31.255.2"
    REMOTE="172.31.255.1"
fi

echo -e "${YELLOW}Cleaning old tunnel...${NC}"
ip link del gnv0 2>/dev/null

echo -e "${GREEN}Creating Geneve Tunnel...${NC}"

ip link add gnv0 type geneve id 55 remote $PEER dstport 6081 dev $INTERFACE
ip addr add $LOCAL/30 dev gnv0
ip link set gnv0 mtu 1380
ip link set gnv0 up

# Route Fix (خیلی مهم)
ip route add 172.31.255.0/30 dev gnv0 2>/dev/null

# Firewall
iptables -I INPUT -p udp --dport 6081 -j ACCEPT
iptables -I FORWARD -i gnv0 -j ACCEPT
iptables -I FORWARD -o gnv0 -j ACCEPT

enable_sysctl

echo ""
echo -e "${GREEN}==============================${NC}"
echo -e "${CYAN} Tunnel Successfully Created ${NC}"
echo -e "${GREEN}==============================${NC}"
echo -e "Local IP  : ${BLUE}$LOCAL${NC}"
echo -e "Remote IP : ${BLUE}$REMOTE${NC}"
echo ""
echo -e "${YELLOW}Test with:${NC} ping $REMOTE"
}

delete_tunnel() {
ip link del gnv0 2>/dev/null
iptables -D INPUT -p udp --dport 6081 -j ACCEPT 2>/dev/null
echo -e "${RED}Tunnel Deleted.${NC}"
}

status_tunnel() {
echo -e "${CYAN}Interface Status:${NC}"
ip addr show gnv0 2>/dev/null
echo ""
echo -e "${CYAN}Route Table:${NC}"
ip route | grep gnv0
}

while true; do
clear
echo -e "${GREEN}"
echo "====================================="
echo "        mahdi4you Geneve Ultra"
echo "====================================="
echo -e "${NC}"
echo -e "${YELLOW}1) Create Tunnel${NC}"
echo -e "${YELLOW}2) Delete Tunnel${NC}"
echo -e "${YELLOW}3) Tunnel Status${NC}"
echo -e "${YELLOW}4) Exit${NC}"
echo ""
read -p "Choose: " OPT

case $OPT in
1) create_tunnel; read -p "Press Enter..." ;;
2) delete_tunnel; read -p "Press Enter..." ;;
3) status_tunnel; read -p "Press Enter..." ;;
4) exit ;;
*) echo "Invalid"; sleep 2 ;;
esac
done
