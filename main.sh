#!/bin/bash

VXLAN_DEV="vxlan0"
VNI="100"
PORT="443"
IR_TUN_IP="10.200.0.1/24"
KH_TUN_IP="10.200.0.2/24"

enable_forward() {
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
}

install_ir() {
read -p "Enter KHAREJ Public IP: " KH_IP
LOCAL_IP=$(curl -s ifconfig.me)

ip link add $VXLAN_DEV type vxlan id $VNI remote $KH_IP local $LOCAL_IP dstport $PORT dev eth0
ip addr add $IR_TUN_IP dev $VXLAN_DEV
ip link set $VXLAN_DEV mtu 1400
ip link set $VXLAN_DEV up

enable_forward

echo "IRAN VXLAN Created ✅"
}

install_kh() {
read -p "Enter IRAN Public IP: " IR_IP
LOCAL_IP=$(curl -s ifconfig.me)

ip link add $VXLAN_DEV type vxlan id $VNI remote $IR_IP local $LOCAL_IP dstport $PORT dev eth0
ip addr add $KH_TUN_IP dev $VXLAN_DEV
ip link set $VXLAN_DEV mtu 1400
ip link set $VXLAN_DEV up

enable_forward

echo "KHAREJ VXLAN Created ✅"
}

status_tunnel() {
echo "====== Interface ======"
ip a show $VXLAN_DEV
echo "====== Ping Test ======"
ping -c 4 10.200.0.2
}

restart_tunnel() {
ip link set $VXLAN_DEV down
ip link set $VXLAN_DEV up
echo "Restarted ✅"
}

remove_tunnel() {
ip link del $VXLAN_DEV
echo "Removed ❌"
}

menu() {
clear
echo "====== tofanTunnel VXLAN L2 ======"
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
