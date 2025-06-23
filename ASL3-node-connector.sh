#!/bin/bash
##############################

# ASL3 node connector script
# By Goose - N8GMZ - 2025

###############################

# This script will connect your AllStarLink3 node to another node and disconnect after a period of inactivity on the node.
# It was made to connect to nets and disconnect after there is no activity, when the net is complete.
# This code is protected under the MIT license
# https://github.com/GooseThings/ASL3-node-connector/

###############################

# Add this script to crontab for automated scheduling
# Example: "58 19 * * 3 /usr/local/bin/ASL3-node-connector.sh &"
# This example connects your node to another node at 7:58PM (1958 hours) on Wednesdays (3)

### SETTINGS ####
NODE=12345 # Replace this with your own node number!
TARGET=12345 # Replace this with the target node you're connecting to! 
IDLE_LIMIT=300  # Seconds of idle time before your node disconnects from target node
AUDIO_PATH="/var/lib/asterisk/sounds/custom" # Path for where the audio files are stored
CONNECT_ANNOUNCE="link-generic-announcement" # Replace this with your connection announcement WAV file stored in /var/lib/asterisk/sounds/custom
CONNECT_ANNOUNCE_TIME=9 # This is the amount of time your connect announcement WAV file is, in seconds
DISCONNECT_ANNOUNCE="disconnect-generic-announcement" # Replace this with your disconnect anouncement WAV file stored in /var/lib/asterisk/sounds/custom

### A NOTE ON WAV FILE ANNOUNCEMENTS ###
# They must be 128kb/s 8000Hz mono WAV files
# Run the following command from the Asterisk CLI to test that the WAV file works:
# "rpt -rx localplay [your node #] /var/lib/asterisk/sounds/custom/[Your WAV file]

### DO NOT INCLUDE the ".wav" from the filefame in the commands or in the settings above ###

# Play connection announcement and then connect to the target node after announcement finishes
asterisk -rx "rpt playback $NODE $AUDIO_PATH$CONNECT_ANNOUNCE" # Comment out this line if no connect announcement
sleep $CONNECT_ANNOUNCE_TIME # Comment out if no connect announcement
asterisk -rx "rpt fun $NODE *3$TARGET"
sleep 3  # Give it a moment to fully connect

LAST_ACTIVITY=$(date +%s) # Timestamp of last activity

while true; do
    ACTIVITY=$(asterisk -rx "rpt stats $NODE" | grep -i "lastnode")

    if echo "$ACTIVITY" | grep -q "$TARGET"; then
        LAST_ACTIVITY=$(date +%s) # Reset timer if traffic detected
    fi

    CURRENT_TIME=$(date +%s)
    IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))

    if [ $IDLE_TIME -ge $IDLE_LIMIT ]; then
        asterisk -rx "rpt fun $NODE *1$TARGET" # Disconnects from node
        sleep 3 # Comment out if no exit announcement
        asterisk -rx "rpt playback $NODE $AUDIO_PATH$DISCONNECT_ANNOUNCE" #Comment out if no exit announcement
        exit 0
    fi

    sleep 30  # check every 30 seconds
done
