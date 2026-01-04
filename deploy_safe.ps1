robocopy . "\\192.168.40.114\config" /MIR /R:1 /W:1 `
  /XD ".git" ".storage" ".cloud" "tts" "media" "backups" "__pycache__" `
  /XF "secrets.yaml" "home-assistant_v2.db" "home-assistant_v2.db-shm" "home-assistant_v2.db-wal" "zigbee.db" "zigbee.db-shm" "zigbee.db-wal" "*.pyc"
