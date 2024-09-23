#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <start|stop> <MIN_VMID> <MAX_VMID>"
    exit 1
fi

# Define the action: start or stop
ACTION=$1

# Define the range of VMIDs
MIN_VMID=$2
MAX_VMID=$3

# Function to start VMs
start_vm() {
    local vmid=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting VMID: $vmid"
    /usr/sbin/qm start $vmid
}

# Function to stop VMs
stop_vm() {
    local vmid=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopping VMID: $vmid"
    /usr/sbin/qm shutdown $vmid
}

# Get the list of VMIDs within the specified range
vmids=($(/usr/sbin/qm list | awk -v min=$MIN_VMID -v max=$MAX_VMID 'NR>1 && $1 >= min && $1 <= max {print $1}'))

# Iterate over the VMIDs
for i in "${!vmids[@]}"; do
    vmid=${vmids[$i]}
    vmname=$(/usr/sbin/qm list | awk -v id=$vmid '$1 == id {print $2}')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] VM Name: $vmname, VMID: $vmid"

    # Check if the VM is running
    status=$(/usr/sbin/qm status $vmid | awk '{print $2}')
    if [ "$status" == "running" ]; then
        if [ "$ACTION" == "stop" ]; then
            stop_vm $vmid
            # Wait for 2 minutes unless it's the last VM
            if [ $i -lt $((${#vmids[@]} - 1)) ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for 30 seconds before shutting down the next VM..."
                sleep 30
            fi
        fi
    elif [ "$status" == "stopped" ]; then
        if [ "$ACTION" == "start" ]; then
            start_vm $vmid
            # Wait for 2 minutes unless it's the last VM
            if [ $i -lt $((${#vmids[@]} - 1)) ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for 2 minutes before starting the next VM..."
                sleep 120
            fi
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] VM Name: $vmname, VMID: $vmid has an unknown status: $status"
    fi
done
