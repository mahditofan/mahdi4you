#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
NC="\e[0m"

TUN_IF="gre0"
SERVICE_FILE="/etc/systemd/system/mahdi4you-gre.service"
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

auto_mtu() {
BASE_MTU=$(ip link show $INTERFACE | awk '/mtu/ {print $5}')
CALC_MTU=$((BASE_MTU-24))
echo $CALC_MTU
}

enable_sysctl() {
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
}

create_service() {

MTU=$(auto_mtu)

cat > $SERVICE_FILE <<EOF
[Unit]
Description=mahdi4you GRE Tunnel
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
ip tunnel add $TUN_IF mode gre local $LOCAL_PUB remote $PEER_PUB ttl 255;
ip addr add $LOCAL_TUN/30 dev $TUN_IF;
ip link set $TUN_IF mtu $MTU;
ip link set $TUN_IF up;
ip route add 10.99.99.0/30 dev $TUN_IF;
sysctl -w net.ipv4.ip_forward=1;
sysctl -w net.ipv4.conf.all.rp_filter=0;
iptables -I FORWARD -i $TUN_IF -j ACCEPT;
iptables -I FORWARD -o $TUN_IF -j ACCEPT;
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mahdi4you-gre
systemctl start mahdi4you-gre
}

create_tunnel() {

read -p "Enter Your Public IP: " LOCAL_PUB
read -p "Enter Peer Public IP: " PEER_PUB
read -p "Are you Server 1 or 2? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
    LOCAL_TUN="10.99.99.1"
    REMOTE_TUN="10.99.99.2"
else
    LOCAL_TUN="10.99.99.2"
    REMOTE_TUN="10.99.99.1"
fi

ip tunnel del $TUN_IF 2>/dev/null

create_service

echo ""
echo -e "${GREEN}==============================${NC}"
echo -e "${CYAN} GRE Tunnel Created Successfully ${NC}"
echo -e "${GREEN}==============================${NC}"
echo -e "${BLUE}Local Tunnel IP : $LOCAL_TUN${NC}"
echo -e "${BLUE}Remote Tunnel IP: $REMOTE_TUN${NC}"
echo ""
echo -e "${YELLOW}Auto MTU Applied: $(auto_mtu)${NC}"
echo -e "${YELLOW}Test with: ping $REMOTE_TUN${NC}"
}

delete_tunnel() {
systemctl stop mahdi4you-gre 2>/dev/null
systemctl disable mahdi4you-gre 2>/dev/null
rm -f $SERVICE_FILE
systemctl daemon-reload
ip tunnel del $TUN_IF 2>/dev/null
echo -e "${RED}Tunnel Fully Removed.${NC}"
}

status_tunnel() {
systemctl status mahdi4you-gre --no-pager
echo ""
ip addr show $TUN_IF 2>/dev/null
}

while true; do
clear
echo -e "${GREEN}"
echo "======================================"
echo "        mahdi4you GRE Ultimate"
echo "======================================"
echo -e "${NC}"
echo -e "${YELLOW}1) Create GRE Tunnel${NC}"
echo -e "${YELLOW}2) Delete Tunnel${NC}"
echo -e "${YELLOW}3) Status${NC}"
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
