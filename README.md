# cloudflare-ddns-updater
Bash script to update cloudflare dns with a dynamic IP. Works with multiple zones. 

Will update IP if a change is detected. --force and --log are options. <br>
A timer and service file  is included (you will need to modify the path in the service file to point to the script and optionally the timer length of 20 minutes) for systemd timer. Or you can just run it with crontab.  

--log logs to ~/log-cfddns
