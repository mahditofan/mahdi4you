#!/bin/bash

TUN_DEV="ipip1"
IR_TUN_IP="10.50.0.1/30"
KH_TUN_IP="10.50.0.2/30"

load_module() {
modprobe ipip
echo "ipip" >> /etc/modules
}

enable_forward() {
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
}

install_ir() {
read -p "Enter KHAREJ Public IP: " KH_IP
LOCAL_IP=$(curl -s ifconfig.me)

load_module

ip tunnel add $TUN_DEV mode ipip remote $KH_IP local $LOCAL_IP
ip addr add $IR_TUN_IP dev $TUN_DEV
ip link set $TUN_DEV mtu 1480
ip link set $TUN_DEV up

enable_forward

echo "IRAN Tunnel Created ✅"
}

install_kh() {
read -p "Enter IRAN Public IP: " IR_IP
LOCAL_IP=$(curl -s ifconfig.me)

load_module

ip tunnel add $TUN_DEV mode ipip remote $IR_IP local $LOCAL_IP
ip addr add $KH_TUN_IP dev $TUN_DEV
ip link set $TUN_DEV mtu 1480
ip link set $TUN_DEV up

enable_forward

echo "KHAREJ Tunnel Created ✅"
}

status_tunnel() {
echo "====== Interface ======"
ip a show $TUN_DEV
echo "====== Routing ======"
ip route
echo "====== Ping Test ======"
ping -c 4 10.50.0.2
}

restart_tunnel() {
ip link set $TUN_DEV down
ip link set $TUN_DEV up
echo "Restarted ✅"
}

remove_tunnel() {
ip tunnel del $TUN_DEV
echo "Removed ❌"
}

menu() {
clear
echo "====== tofanTunnel L3 IPIP ======"
echo "1) Install IRAN"
echo "2) Install KHAREJ"
echo "3) Status"
echo "4) Restart"
echo "5) Remove"
echo "0) Exit"
read -p "Choose: " opt

case $opt in
1) install_ir ;;
2) install_kh ;;
3) status_tunnel ;;
4) restart_tunnel ;;
5) remove_tunnel ;;
0) exit ;;
esac
}

menu
