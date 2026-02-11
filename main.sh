#!/bin/bash
clear
set -e

PROJECT="mahdi4you-TCP"
WG_IF="wg0"
WG_PORT=51820
VXLAN_IF="vxlan200"
VXLAN_ID=200
VXLAN_PORT=4789
MTU=1380

check_root() {
 [ "$EUID" -ne 0 ] && echo "Run as root" && exit 1
}

install_all() {

apt update -y
apt install wireguard iproute2 iptables -y

echo "Server role (iran/kharej)"
read ROLE
read -p "Peer Public IP: " PEER
read -p "Public Interface (eth0?): " DEV
DEV=${DEV:-eth0}

WG_PRIV=$(wg genkey)
WG_PUB=$(echo $WG_PRIV | wg pubkey)

echo "====== IMPORTANT ======"
echo "Save this Public Key:"
echo $WG_PUB
echo "======================="

read -p "Enter Peer Public Key: " PEER_PUB

if [ "$ROLE" = "kharej" ]; then
  WG_IP="10.200.200.1/30"
  PEER_WG="10.200.200.2/32"
  VX_IP="172.30.30.1/30"
else
  WG_IP="10.200.200.2/30"
  PEER_WG="10.200.200.1/32"
  VX_IP="172.30.30.2/30"
fi

cat > /etc/wireguard/$WG_IF.conf <<EOF
[Interface]
PrivateKey = $WG_PRIV
Address = $WG_IP
ListenPort = $WG_PORT

[Peer]
PublicKey = $PEER_PUB
AllowedIPs = $PEER_WG
Endpoint = $PEER:$WG_PORT
PersistentKeepalive = 25
EOF

sysctl -w net.ipv4.ip_forward=1

wg-quick up $WG_IF

ip link add $VXLAN_IF type vxlan id $VXLAN_ID local ${WG_IP%/*} remote ${PEER_WG%/*} dev $WG_IF dstport $VXLAN_PORT
ip addr add $VX_IP dev $VXLAN_IF
ip link set $VXLAN_IF mtu $MTU
ip link set $VXLAN_IF up

iptables -A INPUT -p udp --dport $WG_PORT -j ACCEPT

if [ "$ROLE" = "kharej" ]; then
  iptables -t nat -A POSTROUTING -o $DEV -j MASQUERADE
  iptables -A FORWARD -i $VXLAN_IF -o $DEV -j ACCEPT
  iptables -A FORWARD -i $DEV -o $VXLAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

echo "✅ Installed successfully"
}

remove_all() {
wg-quick down $WG_IF 2>/dev/null || true
ip link del $VXLAN_IF 2>/dev/null || true
rm -f /etc/wireguard/$WG_IF.conf
echo "Removed."
}

menu() {
echo "======================="
echo " $PROJECT "
echo "======================="
echo "1) Install"
echo "2) Remove"
echo "0) Exit"
read -p "Choose: " CH

case $CH in
1) install_all ;;
2) remove_all ;;
0) exit ;;
*) echo "Invalid" ;;
esac
}

check_root
menu
