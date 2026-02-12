#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
TABLE_ID=200
TABLE_NAME="vxlan200"
TUN_IF="vxlan0"
SUBNET="10.200.200.0/30"

enable_sysctl() {
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.$INTERFACE.rp_filter=0 >/dev/null
}

add_routing_table() {
grep -q "$TABLE_NAME" /etc/iproute2/rt_tables || echo "$TABLE_ID $TABLE_NAME" >> /etc/iproute2/rt_tables
}

create_tunnel() {

read -p "Enter Peer Public IP: " PEER
read -p "Are you Server 1 or 2? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
    LOCAL="10.200.200.1"
    REMOTE="10.200.200.2"
else
    LOCAL="10.200.200.2"
    REMOTE="10.200.200.1"
fi

echo -e "${YELLOW}Cleaning old configs...${NC}"
ip link del $TUN_IF 2>/dev/null
ip rule del from $LOCAL table $TABLE_NAME 2>/dev/null
ip route flush table $TABLE_NAME 2>/dev/null

echo -e "${GREEN}Creating VXLAN...${NC}"

ip link add $TUN_IF type vxlan id 200 remote $PEER dstport 4789 dev $INTERFACE
ip addr add $LOCAL/30 dev $TUN_IF
ip link set $TUN_IF mtu 1400
ip link set $TUN_IF up

enable_sysctl
add_routing_table

# Route اصلی
ip route add $SUBNET dev $TUN_IF

# Policy Routing
ip rule add from $LOCAL table $TABLE_NAME
ip route add default dev $TUN_IF table $TABLE_NAME

# Firewall
iptables -I INPUT -p udp --dport 4789 -j ACCEPT
iptables -I FORWARD -i $TUN_IF -j ACCEPT
iptables -I FORWARD -o $TUN_IF -j ACCEPT

echo ""
echo -e "${GREEN}==============================${NC}"
echo -e "${CYAN} VXLAN Pro Tunnel Ready ${NC}"
echo -e "${GREEN}==============================${NC}"
echo -e "Local IP  : $LOCAL"
echo -e "Remote IP : $REMOTE"
echo ""
echo -e "${YELLOW}Test with:${NC} ping $REMOTE"
}

delete_tunnel() {
ip link del $TUN_IF 2>/dev/null
ip rule del table $TABLE_NAME 2>/dev/null
ip route flush table $TABLE_NAME 2>/dev/null
iptables -D INPUT -p udp --dport 4789 -j ACCEPT 2>/dev/null
echo -e "${RED}Tunnel Removed.${NC}"
}

status_tunnel() {
echo -e "${CYAN}Interface:${NC}"
ip addr show $TUN_IF 2>/dev/null
echo ""
echo -e "${CYAN}Rules:${NC}"
ip rule | grep $TABLE_NAME
echo ""
echo -e "${CYAN}Routes:${NC}"
ip route | grep $TUN_IF
}

while true; do
clear
echo -e "${GREEN}"
echo "======================================"
echo "       mahdi4you VXLAN Pro"
echo "======================================"
echo -e "${NC}"
echo "1) Create Tunnel"
echo "2) Delete Tunnel"
echo "3) Status"
echo "4) Exit"
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
