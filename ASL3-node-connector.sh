# ASL3 node connector script
# By Goose - N8GMZ - 2025
###############################

# This script will connect your AllStarLink3 node to another node and disconnect after a period of inactivity on the node.
# It was made to connect to nets and disconnect after there is no activity, when the net is complete.
# This code is protected under the MIT license
# https://github.com/GooseThings/ASL3-node-connector/

###############################

# Add this script to crontab for automated scheduling
# Example: 58 19 * * 3 /usr/local/bin/ASL3-node-connector.sh &
# This example connects your node to another node at 7:58PM on Wednesdays

###############################

#!/bin/bash

NODE=12345 # Replace this with your number number!
TARGET=12345 # Replace this with the target node you're connecting to! 
IDLE_LIMIT=300  # seconds of idle time before your node disconnects from target node
CONNECT_ANNOUNCE="WMEC-con-proper" # Replace this with your connection announcement WAV file stored in /var/lib/asterisk/sounds/custom
DISCONNECT_ANNOUNCE="WMEC-discon-proper" # Replace this with your disconnect anouncement WAV file

# Play connection announcement and then connect to the target node after announcement finishes
asterisk -rx "rpt playback $NODE /var/lib/asterisk/sounds/custom/$CONNECT_ANNOUNCE" # Comment out this line if no connect announcement
sleep $CONNECT_ANNOUNCE_TIME # Comment out if no connect announcement
asterisk -rx "rpt fun $NODE *3$TARGET"
sleep 3  # Give it a moment to fully connect

# Timestamp of last activity
LAST_ACTIVITY=$(date +%s)

while true; do
    ACTIVITY=$(asterisk -rx "rpt stats $NODE" | grep -i "lastnode")

    if echo "$ACTIVITY" | grep -q "$TARGET"; then
        # Reset timer if traffic detected
        LAST_ACTIVITY=$(date +%s)
    fi

    CURRENT_TIME=$(date +%s)
    IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))

    if [ $IDLE_TIME -ge $IDLE_LIMIT ]; then
        asterisk -rx "rpt fun $NODE *1$TARGET" # Disconnects from node
        sleep 3 # Comment out if no exit announcement
        asterisk -rx "rpt playback $NODE /var/lib/asterisk/sounds/custom/$DISCONNECT_ANNOUNCE" #Comment out if no exit announcement
        exit 0
    fi

    sleep 30  # check every 30 seconds
done
