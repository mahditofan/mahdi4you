#!/bin/bash

clear

GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"

while true
do
clear
echo -e "${GREEN}"
echo "======================================"
echo "        mahdi4you VXLAN Tunnel"
echo "======================================"
echo -e "${NC}"
echo "1) Setup Tunnel"
echo "2) Delete Tunnel"
echo "3) Exit"
echo ""
read -p "Choose an option: " option

case $option in

1)
read -p "Enter Remote IP: " remote_ip
read -p "Enter Local Tunnel IP (Example 10.10.10.1): " local_tun_ip
read -p "Enter Remote Tunnel IP (Example 10.10.10.2): " remote_tun_ip

echo "Creating VXLAN..."

ip link add vxlan42 type vxlan id 42 dev eth0 remote $remote_ip dstport 4789
ip addr add $local_tun_ip/24 dev vxlan42
ip link set vxlan42 up
ip link set vxlan42 mtu 1400

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -A INPUT -p udp --dport 4789 -j ACCEPT
iptables -A FORWARD -i vxlan42 -j ACCEPT
iptables -A FORWARD -o vxlan42 -j ACCEPT

echo -e "${GREEN}Tunnel Created Successfully!${NC}"
sleep 3
;;

2)
echo "Deleting VXLAN..."
ip link del vxlan42
iptables -D INPUT -p udp --dport 4789 -j ACCEPT
echo -e "${RED}Tunnel Deleted!${NC}"
sleep 2
;;

3)
exit
;;

*)
echo "Invalid option"
sleep 2
;;

esac
done
