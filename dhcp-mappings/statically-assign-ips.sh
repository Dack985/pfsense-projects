#!/bin/bash

# Variables
PFSENSE_IP="192.168.1.1"  # Replace with your pfSense IP address
USERNAME="admin"          # pfSense username
PASSWORD="your_password"  # pfSense password
CONFIG_XML="/cf/conf/config.xml"

# Backup current configuration
echo "Backing up current pfSense configuration..."
scp ${USERNAME}@${PFSENSE_IP}:${CONFIG_XML} config_backup.xml

# Create a working copy of the config file
cp config_backup.xml config.xml

# Get the number of mappings from the user
read -p "How many DHCP mappings would you like to create? " num_mappings

# Loop to collect MAC, IP, and Description for each mapping
for ((i=1; i<=num_mappings; i++)); do
    echo "Mapping $i:"
    read -p "Enter MAC address (e.g., 00:11:22:33:44:55): " mac
    read -p "Enter IP address (e.g., 192.168.1.100): " ip
    read -p "Enter description: " desc

    # Add each entry to the XML configuration file
    xmlstarlet ed --inplace -s "/pfsense/dhcpd/lan/staticmap" -t elem -n "map" -v "" \
        -s "/pfsense/dhcpd/lan/staticmap/map[last()]" -t elem -n "mac" -v "$mac" \
        -s "/pfsense/dhcpd/lan/staticmap/map[last()]" -t elem -n "ipaddr" -v "$ip" \
        -s "/pfsense/dhcpd/lan/staticmap/map[last()]" -t elem -n "descr" -v "$desc" config.xml

    echo "Added: MAC=$mac, IP=$ip, Description='$desc'"
done

# Upload the modified configuration back to pfSense
echo "Uploading updated configuration to pfSense..."
scp config.xml ${USERNAME}@${PFSENSE_IP}:${CONFIG_XML}

# Apply the configuration changes
echo "Applying configuration changes on pfSense..."
ssh ${USERNAME}@${PFSENSE_IP} "pfSsh.php playback config reload"

echo "All DHCP mappings added and configuration reloaded successfully!"
