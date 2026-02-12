#!/bin/bash

read -p "Enter IRAN Server Public IP: " IRAN_IP
read -p "Enter FOREIGN Server Public IP: " FOREIGN_IP
read -p "Is this server IRAN or FOREIGN? (iran/foreign): " ROLE

TUN_NAME="tofanTunnel"
TUN_LOCAL_IP_IRAN="10.10.10.2"
TUN_LOCAL_IP_FOREIGN="10.10.10.1"
TUN_NETMASK="30"

apt update -y
apt install -y iproute2

# Enable IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

if [[ $ROLE == "iran" ]]; then
    ip tunnel add $TUN_NAME mode gre local $IRAN_IP remote $FOREIGN_IP ttl 255
    ip addr add $TUN_LOCAL_IP_IRAN/$TUN_NETMASK dev $TUN_NAME
else
    ip tunnel add $TUN_NAME mode gre local $FOREIGN_IP remote $IRAN_IP ttl 255
    ip addr add $TUN_LOCAL_IP_FOREIGN/$TUN_NETMASK dev $TUN_NAME
fi

ip link set $TUN_NAME up

echo "Tunnel Created Successfully ✅"
ip addr show $TUN_NAME
