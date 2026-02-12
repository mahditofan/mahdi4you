#!/bin/bash

TUN_IP_IR="10.10.0.1"
TUN_IP_KH="10.10.0.2"
WG_PORT="51820"
RAW_PORT="443"
PASSWORD="tofanTunnel"

install_base() {
apt update -y
apt install -y wireguard wget curl

echo "Enabling BBR..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

wget -O udp2raw.tar.gz https://github.com/wangyu-/udp2raw/releases/download/20230206.0/udp2raw_binaries.tar.gz
tar -xvf udp2raw.tar.gz
chmod +x udp2raw_amd64
mv udp2raw_amd64 /usr/local/bin/udp2raw
}

create_wg_ir() {
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
PRI=$(cat /etc/wireguard/privatekey)

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $PRI
Address = $TUN_IP_IR/24
ListenPort = $WG_PORT
MTU = 1280

[Peer]
PublicKey = REPLACE_KHAREJ_KEY
AllowedIPs = $TUN_IP_KH/32
Endpoint = 127.0.0.1:$RAW_PORT
PersistentKeepalive = 25
EOF

echo "IRAN Public Key:"
cat /etc/wireguard/publickey
}

create_wg_kh() {
read -p "Enter IRAN IP: " IRIP
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
PRI=$(cat /etc/wireguard/privatekey)

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $PRI
Address = $TUN_IP_KH/24
ListenPort = $WG_PORT
MTU = 1280

[Peer]
PublicKey = REPLACE_IRAN_KEY
AllowedIPs = $TUN_IP_IR/32
Endpoint = 127.0.0.1:$RAW_PORT
PersistentKeepalive = 25
EOF

echo "KHAREJ Public Key:"
cat /etc/wireguard/publickey
}

create_udp_service_ir() {
cat > /etc/systemd/system/udp2raw.service <<EOF
[Unit]
Description=udp2raw Server
After=network.target

[Service]
ExecStart=/usr/local/bin/udp2raw -s -l0.0.0.0:$RAW_PORT -r127.0.0.1:$WG_PORT -k $PASSWORD --raw-mode faketcp --cipher-mode xor
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

create_udp_service_kh() {
read -p "Enter IRAN IP: " IRIP

cat > /etc/systemd/system/udp2raw.service <<EOF
[Unit]
Description=udp2raw Client
After=network.target

[Service]
ExecStart=/usr/local/bin/udp2raw -c -l127.0.0.1:$RAW_PORT -r$IRIP:$RAW_PORT -k $PASSWORD --raw-mode faketcp --cipher-mode xor
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

start_all() {
systemctl daemon-reload
systemctl enable udp2raw
systemctl enable wg-quick@wg0
systemctl restart udp2raw
systemctl restart wg-quick@wg0
echo "Tunnel Started ✅"
}

status_tunnel() {
echo "====== WireGuard Status ======"
wg show
echo "====== Ping Test ======"
ping -c 4 $TUN_IP_KH
}

restart_tunnel() {
systemctl restart udp2raw
systemctl restart wg-quick@wg0
echo "Restarted ✅"
}

remove_all() {
systemctl stop wg-quick@wg0
systemctl stop udp2raw
systemctl disable wg-quick@wg0
systemctl disable udp2raw
rm -rf /etc/wireguard
rm /etc/systemd/system/udp2raw.service
pkill udp2raw
echo "Tunnel Removed ❌"
}

menu() {
clear
echo "====== tofanTunnel Pro ======"
echo "1) Install IRAN"
echo "2) Install KHAREJ"
echo "3) Start Tunnel"
echo "4) Status"
echo "5) Restart"
echo "6) Remove"
echo "0) Exit"
read -p "Choose: " opt

case $opt in
1) install_base; create_wg_ir; create_udp_service_ir ;;
2) install_base; create_wg_kh; create_udp_service_kh ;;
3) start_all ;;
4) status_tunnel ;;
5) restart_tunnel ;;
6) remove_all ;;
0) exit ;;
esac
}

menu
