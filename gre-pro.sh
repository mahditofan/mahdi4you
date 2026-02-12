#!/bin/bash

TUN="mahdiGRE"
SERVICE="/etc/systemd/system/mahdi-gre.service"

RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; NC="\e[0m"

get_interface(){
ip route | grep default | awk '{print $5}' | head -n1
}

calc_mtu(){
BASE=$(ip link show $(get_interface) | awk '/mtu/ {print $5}')
echo $((BASE-24))
}

enable_sys(){
cat <<EOF >/etc/sysctl.d/99-mahdi-gre.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.$TUN.rp_filter=0
EOF
sysctl --system >/dev/null
}

create_service(){

MTU=$(calc_mtu)

cat > $SERVICE <<EOF
[Unit]
Description=Mahdi Real GRE Tunnel
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
ip tunnel add $TUN mode gre local $LOCAL remote $REMOTE ttl 255;
ip addr add $LOCAL_TUN/30 dev $TUN;
ip link set $TUN mtu $MTU;
ip link set $TUN up;
ip route replace 172.30.50.0/30 dev $TUN;
'
RemainAfterExit=yes

ExecStop=/bin/bash -c '
ip tunnel del $TUN 2>/dev/null;
'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mahdi-gre
systemctl restart mahdi-gre
}

create_tunnel(){

read -p "Your Public IP: " LOCAL
read -p "Peer Public IP: " REMOTE
read -p "Server 1 or 2? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
LOCAL_TUN="172.30.50.1"
REMOTE_TUN="172.30.50.2"
else
LOCAL_TUN="172.30.50.2"
REMOTE_TUN="172.30.50.1"
fi

ip tunnel del $TUN 2>/dev/null

enable_sys
create_service

echo -e "${GREEN}Tunnel Created Successfully${NC}"
echo -e "${CYAN}Local Tunnel IP: $LOCAL_TUN${NC}"
echo -e "${CYAN}Remote Tunnel IP: $REMOTE_TUN${NC}"
echo -e "${YELLOW}Test with: ping $REMOTE_TUN${NC}"
}

delete_tunnel(){
systemctl stop mahdi-gre 2>/dev/null
systemctl disable mahdi-gre 2>/dev/null
rm -f $SERVICE
rm -f /etc/sysctl.d/99-mahdi-gre.conf
sysctl --system >/dev/null
ip tunnel del $TUN 2>/dev/null
systemctl daemon-reload
echo -e "${RED}Tunnel Removed Completely${NC}"
}

status_tunnel(){
echo -e "${GREEN}===== Tunnel Status =====${NC}"
ip addr show $TUN 2>/dev/null
echo ""
ip route | grep 172.30.50
echo ""
systemctl status mahdi-gre --no-pager
}

while true; do
clear
echo -e "${GREEN}"
echo "================================"
echo "      MAHDI REAL GRE MENU"
echo "================================"
echo -e "${NC}"
echo "1) Create GRE Tunnel"
echo "2) Delete Tunnel"
echo "3) Status"
echo "4) Exit"
echo ""
read -p "Choose: " opt

case $opt in
1) create_tunnel; read -p "Enter..." ;;
2) delete_tunnel; read -p "Enter..." ;;
3) status_tunnel; read -p "Enter..." ;;
4) exit ;;
*) echo "Invalid"; sleep 2 ;;
esac
done
