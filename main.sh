#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
TUN_IF="vxlan0"
SERVICE_FILE="/etc/systemd/system/mahdi4you-vxlan.service"

create_service() {

cat > $SERVICE_FILE <<EOF
[Unit]
Description=mahdi4you VXLAN Tunnel
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
ip link add $TUN_IF type vxlan id 200 remote $PEER dstport 4789 dev $INTERFACE;
ip addr add $LOCAL/30 dev $TUN_IF;
ip link set $TUN_IF mtu 1400;
ip link set $TUN_IF up;
ip route add 10.200.200.0/30 dev $TUN_IF;
sysctl -w net.ipv4.ip_forward=1;
sysctl -w net.ipv4.conf.all.rp_filter=0;
iptables -I INPUT -p udp --dport 4789 -j ACCEPT;
iptables -I FORWARD -i $TUN_IF -j ACCEPT;
iptables -I FORWARD -o $TUN_IF -j ACCEPT;
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mahdi4you-vxlan
systemctl start mahdi4you-vxlan
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

ip link del $TUN_IF 2>/dev/null

create_service

echo ""
echo -e "${GREEN}Tunnel Created & Persistent Enabled${NC}"
echo "Local IP: $LOCAL"
echo "Remote IP: $REMOTE"
echo ""
echo "After reboot it will stay active."
}

delete_tunnel() {
systemctl stop mahdi4you-vxlan 2>/dev/null
systemctl disable mahdi4you-vxlan 2>/dev/null
rm -f $SERVICE_FILE
systemctl daemon-reload
ip link del $TUN_IF 2>/dev/null
echo -e "${RED}Tunnel Fully Removed.${NC}"
}

status_tunnel() {
systemctl status mahdi4you-vxlan --no-pager
echo ""
ip addr show $TUN_IF 2>/dev/null
}

while true; do
clear
echo -e "${GREEN}"
echo "======================================"
echo "     mahdi4you VXLAN Persistent"
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
