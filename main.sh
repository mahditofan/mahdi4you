#!/bin/bash

clear
set -e

PROJECT="mahdi4you"
VXLAN_ID=42
VXLAN_IF="vxlan42"
VXLAN_PORT=4789
MTU=1400
NET_KHAREJ="10.50.50.1/24"
NET_IRAN="10.50.50.2/24"

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Please run as root"
    exit 1
  fi
}

get_default_if() {
  ip route | awk '/default/ {print $5}' | head -n1
}

install_vxlan() {
  echo "---- VXLAN Install ----"
  read -p "Server role (iran/kharej): " ROLE
  read -p "Peer public IPv4: " PEER_IP
  read -p "Network interface [auto]: " DEV
  DEV=${DEV:-$(get_default_if)}

  LOCAL_IP=$(ip addr show $DEV | awk '/inet /{print $2}' | cut -d/ -f1)

  if [[ "$ROLE" == "kharej" ]]; then
    TUN_IP=$NET_KHAREJ
  elif [[ "$ROLE" == "iran" ]]; then
    TUN_IP=$NET_IRAN
  else
    echo "❌ Invalid role"
    exit 1
  fi

  modprobe vxlan

  ip link del $VXLAN_IF 2>/dev/null || true

  ip link add $VXLAN_IF type vxlan id $VXLAN_ID local $LOCAL_IP remote $PEER_IP dstport $VXLAN_PORT
  ip addr add $TUN_IP dev $VXLAN_IF
  ip link set $VXLAN_IF mtu $MTU
  ip link set $VXLAN_IF up

  sysctl -w net.ipv4.ip_forward=1 >/dev/null

  if [[ "$ROLE" == "kharej" ]]; then
    iptables -t nat -C POSTROUTING -o $DEV -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -o $DEV -j MASQUERADE

    iptables -C FORWARD -i $VXLAN_IF -o $DEV -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i $VXLAN_IF -o $DEV -j ACCEPT

    iptables -C FORWARD -i $DEV -o $VXLAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i $DEV -o $VXLAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
  fi

  echo "✅ VXLAN installed successfully"
}

remove_vxlan() {
  echo "---- Remove VXLAN ----"
  DEV=$(get_default_if)

  ip link del $VXLAN_IF 2>/dev/null || true
  iptables -t nat -D POSTROUTING -o $DEV -j MASQUERADE 2>/dev/null || true
  iptables -D FORWARD -i $VXLAN_IF -o $DEV -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -i $DEV -o $VXLAN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

  echo "🗑 VXLAN removed"
}

status_vxlan() {
  echo "---- VXLAN Status ----"
  ip addr show $VXLAN_IF || echo "❌ VXLAN not found"
}

menu() {
  echo "=============================="
  echo " $PROJECT VXLAN Installer"
  echo "=============================="
  echo "1) Install VXLAN"
  echo "2) Remove VXLAN"
  echo "3) VXLAN Status"
  echo "0) Exit"
  echo "------------------------------"
  read -p "Select: " CHOICE

  case $CHOICE in
    1) install_vxlan ;;
    2) remove_vxlan ;;
    3) status_vxlan ;;
    0) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
}

check_root
menu
