#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo -e ' [!] WARNING: Some actions may fail without Root Privileges. '
    exit 1
fi

echo "[*] Stopping NetworkManager..."
systemctl stop NetworkManager || echo "[!] Failed to stop NetworkManager, continuing..."

echo "[*] Killing interfering Processes..."
airmon-ng check kill

read -rp "Interface to use for monitoring: " interface

echo "[*] Starting Monitor Mode on $interface..."
airmon-ng start "$interface"

echo "[*] Requesting IP Address for $interface..."
dhclient "$interface"

echo "[+] Monitor Mode should now be active on $interface
