#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/tmp/airprep.log"
echo "[*] Starting script at $(date)" | tee "$LOGFILE"

if [[ $EUID -ne 0 ]]; then
    echo '[-] Please run this script with sudo.' | tee -a "$LOGFILE"
    exit 1
fi

# Detect wireless interfaces automatically
interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))
if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo "[-] No wireless interfaces found." | tee -a "$LOGFILE"
    exit 1
fi

# Choose the first wireless interface by default, or prompt
interface=${interfaces[0]}
echo "[*] Using detected interface: $interface" | tee -a "$LOGFILE"

# Save the current state
echo "[*] Backing up service status..." | tee -a "$LOGFILE"
systemctl is-active NetworkManager &> /tmp/nm_status || true

# Stop interfering services
echo "[*] Stopping NetworkManager..." | tee -a "$LOGFILE"
systemctl stop NetworkManager || echo "[!] Failed to stop NetworkManager, continuing..." | tee -a "$LOGFILE"

echo "[*] Killing interfering processes..." | tee -a "$LOGFILE"
airmon-ng check kill | tee -a "$LOGFILE"

# Start monitor mode
echo "[*] Starting monitor mode on $interface..." | tee -a "$LOGFILE"
airmon-ng start "$interface" | tee -a "$LOGFILE"

# Request IP address (useful if interface reverts to managed)
echo "[*] Requesting IP address for $interface..." | tee -a "$LOGFILE"
dhclient "$interface" || echo "[!] Could not acquire IP for $interface" | tee -a "$LOGFILE"

# Schedule restoration
restore_services() {
    echo "[*] Restoring previously running services..." | tee -a "$LOGFILE"
    if grep -q "active" /tmp/nm_status; then
        systemctl start NetworkManager && echo "[+] NetworkManager restarted." | tee -a "$LOGFILE"
    fi
}

trap restore_services EXIT

echo "[+] Monitor mode should now be active on $interface" | tee -a "$LOGFILE"
