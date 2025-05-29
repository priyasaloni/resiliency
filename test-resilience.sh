#!/bin/bash

LOG_FILE="/var/log/resilience-test.log"
FLAG_FILE="/var/log/reboot-initiated.flag"
METADATA_ENDPOINT="http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01"
HEADERS="Metadata:true"

# Check if this is the first run or post-reboot
if [ -f "$FLAG_FILE" ]; then
    echo "===== VM Reboot Completed =====" | tee -a $LOG_FILE
    END_TIME=$(date +%s)
    START_TIME=$(cat "$FLAG_FILE")
    RTO=$((END_TIME - START_TIME))
    echo "End Timestamp: $(date -u)" | tee -a $LOG_FILE
    echo "Recovery Time Objective (RTO): $RTO seconds" | tee -a $LOG_FILE
    rm -f "$FLAG_FILE"
    exit 0
fi

# First run: start the test
echo "===== VM Resilience Test Started =====" | tee -a $LOG_FILE
START_TIME=$(date +%s)
echo "$START_TIME" > "$FLAG_FILE"
echo "Start Timestamp: $(date -u)" | tee -a $LOG_FILE

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
sudo /sbin/shutdown -r now
