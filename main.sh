#!/bin/bash

TUN_NAME="tofanTunnel"
SERVICE_FILE="/etc/systemd/system/${TUN_NAME}.service"

function enable_forward() {
    sysctl -w net.ipv4.ip_forward=1
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "IP Forward Enabled ✅"
}

function create_tunnel() {
    read -p "Enter This Server Public IP: " LOCAL_IP
    read -p "Enter Remote Server Public IP: " REMOTE_IP
    read -p "Enter Tunnel Local IP (example 10.10.10.1): " TUN_LOCAL
    read -p "Enter Tunnel Remote IP (example 10.10.10.2): " TUN_REMOTE

    apt update -y
    apt install -y iproute2

    ip tunnel add $TUN_NAME mode gre local $LOCAL_IP remote $REMOTE_IP ttl 255
    ip addr add $TUN_LOCAL/30 dev $TUN_NAME
    ip link set $TUN_NAME up
    ip route add $TUN_REMOTE dev $TUN_NAME

    enable_forward

    cat > $SERVICE_FILE <<EOF
[Unit]
Description=tofanTunnel GRE Tunnel
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip tunnel add $TUN_NAME mode gre local $LOCAL_IP remote $REMOTE_IP ttl 255
ExecStart=/sbin/ip addr add $TUN_LOCAL/30 dev $TUN_NAME
ExecStart=/sbin/ip link set $TUN_NAME up
ExecStart=/sbin/ip route add $TUN_REMOTE dev $TUN_NAME
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $TUN_NAME

    echo "Tunnel Created Successfully ✅"
}

function delete_tunnel() {
    ip link set $TUN_NAME down 2>/dev/null
    ip tunnel del $TUN_NAME 2>/dev/null
    systemctl disable $TUN_NAME 2>/dev/null
    rm -f $SERVICE_FILE
    echo "Tunnel Deleted ❌"
}

function tunnel_status() {
    ip addr show $TUN_NAME
}

function restart_tunnel() {
    systemctl restart $TUN_NAME
    echo "Tunnel Restarted 🔄"
}

function enable_nat() {
    read -p "Enter Outgoing Interface (example eth0): " IFACE
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    echo "NAT Enabled ✅"
}

function disable_nat() {
    read -p "Enter Outgoing Interface (example eth0): " IFACE
    iptables -t nat -D POSTROUTING -o $IFACE -j MASQUERADE
    echo "NAT Disabled ❌"
}

function change_mtu() {
    read -p "Enter MTU Value (example 1400): " MTU
    ip link set dev $TUN_NAME mtu $MTU
    echo "MTU Changed ✅"
}

while true; do
    clear
    echo "=============================="
    echo "       🔥 tofanTunnel 🔥"
    echo "=============================="
    echo "1. Create Tunnel"
    echo "2. Delete Tunnel"
    echo "3. Tunnel Status"
    echo "4. Restart Tunnel"
    echo "5. Enable NAT"
    echo "6. Disable NAT"
    echo "7. Change MTU"
    echo "8. Enable IP Forward"
    echo "0. Exit"
    echo "=============================="
    read -p "Choose Option: " choice

    case $choice in
        1) create_tunnel ;;
        2) delete_tunnel ;;
        3) tunnel_status ; read -p "Press Enter..." ;;
        4) restart_tunnel ; read -p "Press Enter..." ;;
        5) enable_nat ; read -p "Press Enter..." ;;
        6) disable_nat ; read -p "Press Enter..." ;;
        7) change_mtu ; read -p "Press Enter..." ;;
        8) enable_forward ; read -p "Press Enter..." ;;
        0) exit ;;
        *) echo "Invalid Option" ; sleep 1 ;;
    esac
done
