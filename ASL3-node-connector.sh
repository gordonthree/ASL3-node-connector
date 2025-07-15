#!/bin/bash
set -euo pipefail

#############################################
# ASL3 Node Connector Script
# By Goose - N8GMZ - 2025
# https://github.com/GooseThings/ASL3-node-connector/
#############################################

# --- CONFIGURABLE SETTINGS ---
NODE=64549
TARGET=29972
IDLE_LIMIT=60  # seconds
AUDIO_PATH="/var/lib/asterisk/sounds/custom"

EARLY_ANNOUNCE="10-min-generic-announcement" # Put your 10 minute warning announcement here
EARLY_TIME=600 # in seconds

CONNECT_ANNOUNCE="link-generic-announcement" # connection announcement here
CONNECT_ANNOUNCE_TIME=20 # this is the dwell time you need to play the whole announcement before linking the nodes so it doesn't play on the other node

DISCONNECT_ANNOUNCE="disconnect-generic-announcement" # This is the WAV file that plays when you've disconnected
LOGFILE="/var/log/ASL3-node-connector.log" # Logs actions
# -----------------------------

log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOGFILE"; }
play() { asterisk -rx "rpt playback $NODE $1"; }

# --- STEP 1: Early announcement (after idle) ---
log "Waiting for repeater to be idle before early announcement..."
while :; do
    RXKEYED=$(asterisk -rx "rpt show variables $NODE" | awk -F= '/RPT_RXKEYED/{print $2}' | tr -d '\r')
    RXKEYED=${RXKEYED:-1}
    if [[ "$RXKEYED" == 0 ]]; then
        log "Repeater idle. Playing early announcement."
        play "$AUDIO_PATH/$EARLY_ANNOUNCE"
        break
    fi
    log "Repeater busy (RXKEYED=$RXKEYED). Rechecking in 30s..."
    sleep 30
done

sleep "$EARLY_TIME"

# --- STEP 2: Connect after idle ---
log "Waiting for repeater to be idle before connect announcement..."
while :; do
    RXKEYED=$(asterisk -rx "rpt show variables $NODE" | awk -F= '/RPT_RXKEYED/{print $2}' | tr -d '\r')
    RXKEYED=${RXKEYED:-1}
    if [[ "$RXKEYED" == 0 ]]; then
        log "Repeater idle. Playing connect announcement."
        play "$AUDIO_PATH/$CONNECT_ANNOUNCE"
        sleep "$CONNECT_ANNOUNCE_TIME"
        log "Connecting to node $TARGET..."
        asterisk -rx "rpt fun $NODE *3$TARGET"
        break
    fi
    log "Repeater busy (RXKEYED=$RXKEYED). Rechecking in 5s..."
    sleep 5
done

sleep 300  # Allow net to get started before idle monitoring

# --- STEP 3: Monitor for idle activity ---
log "Monitoring for idle time (limit: $IDLE_LIMIT seconds)..."
LAST_ACTIVITY=$(date +%s)

while :; do
    RXKEYED=$(asterisk -rx "rpt show variables $NODE" | awk -F= '/RPT_RXKEYED/{print $2}' | tr -d '\r')
    RXKEYED=${RXKEYED:-1}
    CURRENT_TIME=$(date +%s)

    if [[ "$RXKEYED" == 1 ]]; then
        LAST_ACTIVITY=$CURRENT_TIME
        log "Activity detected. Timer reset."
    else
        IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
        log "Idle time: $IDLE_TIME seconds."
    fi

    if (( CURRENT_TIME - LAST_ACTIVITY >= IDLE_LIMIT )); then
        log "Idle time exceeded. Disconnecting from node $TARGET..."
        asterisk -rx "rpt fun $NODE *1$TARGET"
        sleep 3
        play "$AUDIO_PATH/$DISCONNECT_ANNOUNCE"
        log "Disconnected from node $TARGET. Exiting."
        exit 0
    fi

    sleep 30
done
