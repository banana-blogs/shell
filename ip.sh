#!/bin/bash

# Release the current DHCP lease
dhclient -r -v >/dev/null 2>&1

# Remove DHCP client state files
rm -rf /var/lib/dhcp/dhclient*

# Find and kill any dhclient processes
ps aux | grep dhclient | grep -v grep | awk -F ' ' '{print $2}' | xargs kill -9 2>/dev/null

# Wait for a few seconds
sleep 5s

# Request a new DHCP lease
dhclient -v >/dev/null 2>&1

# Wait for a few seconds
sleep 5s
