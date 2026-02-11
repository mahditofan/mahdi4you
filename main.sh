#!/bin/bash

GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"

clear

install_packages() {
    apt update -y
    apt install -y strongswan strongswan-pki iproute2
}

enable_ip_forward() {
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
}

setup_ipsec() {
read -p "Enter Your Public IP: " my_ip
read -p "Enter Peer Public IP: " peer_ip
read -p "Enter Pre-Shared Key (PSK): " psk

cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="ike 1, knl 1, cfg 0"

conn geneve
    keyexchange=ikev2
    auto=start
    left=$my_ip
    leftid=$my_ip
    leftsubnet=0.0.0.0/0
    right=$peer_ip
    rightid=$peer_ip
    rightsubnet=0.0.0.0/0
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256!
EOF

cat > /etc/ipsec.secrets <<EOF
$my_ip $peer_ip : PSK "$psk"
EOF

systemctl restart strongswan
systemctl enable strongswan
}

setup_geneve() {
read -p "Enter Peer Public IP: " peer_ip
read -p "Enter Local Tunnel IP (Example 10.200.200.1): " local_tun
read -p "Enter Remote Tunnel IP (Example 10.200.200.2): " remote_tun

ip link add geneve42 type geneve id 42 remote $peer_ip dstport 6081
ip addr add $local_tun/30 dev geneve42
ip link set geneve42 mtu 1400
ip link set geneve42 up

iptables -A INPUT -p udp --dport 6081 -j ACCEPT
iptables -A FORWARD -i geneve42 -j ACCEPT
iptables -A FORWARD -o geneve42 -j ACCEPT

echo -e "${GREEN}Geneve Tunnel Created!${NC}"
}

delete_all() {
ip link del geneve42 2>/dev/null
rm -f /etc/ipsec.conf
rm -f /etc/ipsec.secrets
systemctl restart strongswan
echo -e "${RED}Tunnel Removed.${NC}"
}

while true; do
clear
echo -e "${GREEN}"
echo "======================================"
echo "     mahdi4you Geneve + IPsec"
echo "======================================"
echo -e "${NC}"
echo "1) Install & Setup IPsec"
echo "2) Setup Geneve Tunnel"
echo "3) Delete Tunnel"
echo "4) Exit"
echo ""
read -p "Choose: " opt

case $opt in
1)
install_packages
enable_ip_forward
setup_ipsec
read -p "Press Enter..."
;;
2)
setup_geneve
read -p "Press Enter..."
;;
3)
delete_all
read -p "Press Enter..."
;;
4)
exit
;;
*)
echo "Invalid Option"
sleep 2
;;
esac
done
