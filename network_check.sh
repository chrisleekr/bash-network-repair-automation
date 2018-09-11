#!/bin/bash
# Author:
# twitter.com/pitto
#
# HOW TO INSTALL:
#
# 1) Install ifupdown and fping with the following command:
# sudo apt-get install ifupdown fping
#
# 2) Then install this script into a folder and add to your crontab -e this row:
# */5 * * * * /yourhome/yourname/network_check.sh
#
# Note:
# If you want to perform automatic repair fsck at reboot
# remember to uncomment fsck autorepair here: nano /etc/default/rcS

# Let's clear the screen
# clear

# Set interface you want to check against
interface='eth0'

# Write here the gateway you want to check to declare network working or not
gateway_ip='www.google.com'

# Here we initialize the check counter to zero
network_check_tries=0

# Here we specify the maximum number of failed checks
network_check_threshold=10

time=$(date '+%d/%m/%Y %H:%M:%S');


# This function will be called when network_check_tries is equal or greather than network_check_threshold
function restart_interface {
    # If network test failed more than $network_check_threshold
    echo "[$time] Network was not working for the previous $network_check_tries checks."
    # We restart interface
    echo "[$time] Restarting $interface"
    /sbin/ifdown $interface
    sleep 5
    /sbin/ifup --force $interface
    sleep 60
    # If network is still down after recovery and you want to force a reboot simply uncomment following 4 rows
    host_status=$(fping $gateway_ip)
    if [[ $host_status != *"alive"* ]]; then
        shutdown -r +1 'Reboot the system due to no internet connectivity'
    fi
}

# This loop will run network_check_tries times and if we have network_check_threshold failures
# we declare network as not working and we restart interface
while [ $network_check_tries -lt $network_check_threshold ]; do
    # We check if ping to gateway is working and perform the ok / ko actions
    host_status=$(fping $gateway_ip)
    # Increase network_check_tries by 1 unit
    network_check_tries=$[$network_check_tries+1]
    # If network is working
    if [[ $host_status == *"alive"* ]]; then
        # We print positive feedback and quit
        echo "[$time] Network is working correctly" && exit 0
    else
        # If network is down print negative feedback and continue
        echo "[$time] Network is down, failed check number $network_check_tries of $network_check_threshold"
    fi
    # If we hit the threshold we restart interface
    if [ $network_check_tries -ge $network_check_threshold ]; then
        restart_interface
    fi
    # Let's wait a bit between every check
    sleep 10
done
