#!/bin/bash

# Redirect all output to a log file so you can debug failures
exec > /var/log/startup-script.log 2>&1

echo "Starting deployment at $(date)"

# 1. Wait for package manager lock to clear
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    echo "Waiting for other software managers to finish..."
    sleep 5
done

# 1. Install all dependencies
apt-get update

# 2. Setup user and directory
USER_NAME="shouvik"
mkdir -p /home/$USER_NAME/script
mkdir -p /var/log/wrk
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/script /var/log/wrk


# 3. Create the inner test script
cat <<'EOF' > /home/$USER_NAME/script/waf_test.sh
#!/bin/bash
TARGET_URL=${1:-"https://your-domain.com"}
DURATION=${2:-"2h"}

# Calculate end time in seconds
END_TIME=$(( $(date +%s) + $(date -d "$DURATION" +%s -u 2>/dev/null || echo $(( ${DURATION%h} * 3600 )) ) ))

# Define the "attacks"
declare -A payloads

payloads[0]="/get?id=1'%20OR%20'1'='1"                                  # A03:Injection (SQLi)
# payloads["A03:Injection (NoSQL)"]="/basic-auth?user[\$ne]=null"       # A03:Injection (NoSQL)
# payloads["A01:Broken Access Control"]="/admin/config.php"             # A01:Broken Access Control
payloads[1]="/base64?name\=\%3Cscript\%3Ealert\(1\)\%3C/script\%3E"     # A03:XSS
payloads[2]="/anything?url=http://169.254.169.254/latest/meta-data/"    # A10:SSRF
payloads[3]="/$%7Bpwd%7D/serverless.yaml"                                   # likely attack
payloads[4]="/flasgger_static/swagger-ui.css"
payloads[5]="/flasgger_static/lib/jquery.min.js"
payloads[6]="/image/jpeg"
payloads[7]="/gzip"
payloads[8]="/headers"
payloads[9]="/"

echo "----------------------------------------------------"
echo " WAF Demo running against: $TARGET_URL"
echo " Start time: $DURATION "
echo " Duration: $DURATION (Ends at $(date -d @$END_TIME))"
echo "----------------------------------------------------"


while [[ $(date +%s) -lt $END_TIME ]]; do
    for attack in "${!payloads[@]}"; do
        path=${payloads[$attack]}
        full_url="${TARGET_URL}${path}"

        # -s: Silent, -o: discard body, -w: return status code
        status=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$full_url")

        # if [ "$status" == "403" ]; then
        #     echo "$(date +%H:%M:%S) [BLOCKED] $full_url"
        # else
        #     echo "$(date +%H:%M:%S) [ALLOWED] $full_url (Status: $status)"
        # fi
        
        # Short sleep to prevent hitting rate limits on your own machine
        sleep 2
    done
done

echo "Demo duration reached. Exiting."
EOF

# 4. Create the master runner script
cat <<EOF > /home/$USER_NAME/script/waf_run_all.sh
#!/bin/bash
/home/$USER_NAME/script/waf_test.sh https://secure-api.shouvik.us 1 >> /var/log/wrk/instance1.log 2>&1 &
/home/$USER_NAME/script/waf_test.sh https://api.shouvik.us 1 >> /var/log/wrk/instance2.log 2>&1 &
/home/$USER_NAME/script/waf_test.sh https://insecure-api.shouvik.us 1 >> /var/log/wrk/instance3.log 2>&1 &
/home/$USER_NAME/script/waf_test.sh https://httpbin.shouvik.us 1 >> /var/log/wrk/instance4.log 2>&1 &
wait
EOF

# 5. Set permissions
chmod +x /home/$USER_NAME/script/*.sh
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/script

# 6. Create and Start Systemd Service
cat <<EOF > /etc/systemd/system/waf_load_gen.service
[Unit]
Description=Triple WAF load generation Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=/home/$USER_NAME/script
ExecStart=/home/$USER_NAME/script/waf_run_all.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable waf_load_gen.service
systemctl restart waf_load_gen.service