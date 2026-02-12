#!/bin/bash

TUN_IP_IR="10.20.0.1"
TUN_IP_KH="10.20.0.2"
TUN_DEV="gre1"

install_ir() {
read -p "Enter KHAREJ Public IP: " KH_IP

ip tunnel add $TUN_DEV mode gre remote $KH_IP local $(curl -s ifconfig.me) ttl 255
ip addr add $TUN_IP_IR/30 dev $TUN_DEV
ip link set $TUN_DEV mtu 1400
ip link set $TUN_DEV up

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "IRAN Tunnel Created ✅"
}

install_kh() {
read -p "Enter IRAN Public IP: " IR_IP

ip tunnel add $TUN_DEV mode gre remote $IR_IP local $(curl -s ifconfig.me) ttl 255
ip addr add $TUN_IP_KH/30 dev $TUN_DEV
ip link set $TUN_DEV mtu 1400
ip link set $TUN_DEV up

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "KHAREJ Tunnel Created ✅"
}

status_tunnel() {
echo "==== Interface Status ===="
ip a show $TUN_DEV
echo "==== Ping Test ===="
ping -c 4 $TUN_IP_KH
}

restart_tunnel() {
ip link set $TUN_DEV down
ip link set $TUN_DEV up
echo "Restarted ✅"
}

remove_tunnel() {
ip tunnel del $TUN_DEV
echo "Tunnel Removed ❌"
}

menu() {
clear
echo "====== tofanTunnel L3 GRE ======"
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
