#!/bin/bash

clear
echo "======================================"
echo "     Installing tofanTunnel..."
echo "======================================"

INSTALL_DIR="/usr/local/tofanTunnel"
SCRIPT_URL="https://raw.githubusercontent.com/mahditofan/tofanTunnel/main/tofanTunnel.sh"

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

curl -Ls $SCRIPT_URL -o tofanTunnel.sh

chmod +x tofanTunnel.sh

ln -sf $INSTALL_DIR/tofanTunnel.sh /usr/bin/tofan

echo ""
echo "Installation Completed ✅"
echo ""
echo "Run tunnel panel with:"
echo "tofan"
