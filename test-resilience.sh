#!/bin/bash

LOG_FILE="/var/log/resilience-test.log"
METADATA_ENDPOINT="http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01"
HEADERS="Metadata:true"

echo "===== VM Resilience Test Started =====" | tee -a $LOG_FILE
echo "Timestamp: $(date -u)" | tee -a $LOG_FILE

# Validate power state before reboot
echo "Checking system power state before reboot..." | tee -a $LOG_FILE
POWER_STATE_BEFORE=$(systemctl is-system-running)
echo "System state before reboot: $POWER_STATE_BEFORE" | tee -a $LOG_FILE

# Log uptime
echo "Uptime before reboot: $(uptime -p)" | tee -a $LOG_FILE

# Validate public IP availability
echo "Checking public IP address..." | tee -a $LOG_FILE
PUBLIC_IP=$(curl -s -H "$HEADERS" "$METADATA_ENDPOINT")
if [ -n "$PUBLIC_IP" ]; then
    echo "Public IP: $PUBLIC_IP" | tee -a $LOG_FILE
    echo "Testing network connectivity to $PUBLIC_IP..." | tee -a $LOG_FILE
    ping -c 3 "$PUBLIC_IP" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Public IP is reachable." | tee -a $LOG_FILE
    else
        echo "Public IP is not reachable." | tee -a $LOG_FILE
    fi
else
    echo "No public IP found." | tee -a $LOG_FILE
fi

# Simulate a reboot
echo "Simulating reboot in 5 seconds..." | tee -a $LOG_FILE
sleep 5
sudo shutdown -r now
