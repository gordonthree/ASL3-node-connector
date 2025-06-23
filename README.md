 ## ASL-node-connector
 * Download ```ASL-node-connector.sh``` to ```/usr/local/bin```

 * Download audio files to: ```/var/lib/asterisk/sounds/``` (optional)

 * Setup by editing the .sh file: ```sudo nano /usr/local/sbin/ASL3-node-connector.sh```

 * Run automatically at certain times via crontab
   * Example: ```58 19 * * 3 /usr/local/bin/ASL3-node-connector.sh &```

 * Run the 10 minute announcement command via crontab set 10 minutes before connector script is ran:
   * Example: ```48 19 * * 3 /usr/sbin/asterisk -rx "rpt playback [your node number] /var/lib/asterisk/sounds/10-min-generic-announcement```
