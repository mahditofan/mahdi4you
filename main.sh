#!/bin/bash

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

create_tunnel() {

read -p "Enter Peer Public IP: " PEER_IP
read -p "Are you Server 1 (Kharej) or 2 (Iran)? (1/2): " SIDE

if [ "$SIDE" == "1" ]; then
    LOCAL_IP="10.77.77.1"
    REMOTE_IP="10.77.77.2"
else
    LOCAL_IP="10.77.77.2"
    REMOTE_IP="10.77.77.1"
fi

echo "Creating VXLAN..."

# پاک کردن قبلی اگر وجود داشت
ip link del vxlan0 2>/dev/null

# ساخت vxlan
ip link add vxlan0 type vxlan id 77 remote $PEER_IP dstport 4789 dev $INTERFACE

# ست کردن آیپی
ip addr add $LOCAL_IP/30 dev vxlan0

# تنظیم MTU پایدار
ip link set vxlan0 mtu 1400
ip link set vxlan0 up

# تنظیمات سیستمی مهم
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter

# باز کردن پورت
iptables -I INPUT -p udp --dport 4789 -j ACCEPT
iptables -I FORWARD -i vxlan0 -j ACCEPT
iptables -I FORWARD -o vxlan0 -j ACCEPT

echo ""
echo "Tunnel Created Successfully"
echo "Local Tunnel IP: $LOCAL_IP"
echo "Remote Tunnel IP: $REMOTE_IP"
echo ""
echo "Test with: ping $REMOTE_IP"
}

delete_tunnel() {
ip link del vxlan0 2>/dev/null
echo "Tunnel Deleted"
}

while true; do
clear
echo "==============================="
echo "     mahdi4you VXLAN Stable"
echo "==============================="
echo "1) Create Tunnel"
echo "2) Delete Tunnel"
echo "3) Exit"
echo ""
read -p "Choose: " OPTION

case $OPTION in
1) create_tunnel; read -p "Press Enter..." ;;
2) delete_tunnel; read -p "Press Enter..." ;;
3) exit ;;
*) echo "Invalid"; sleep 2 ;;
esac
done
