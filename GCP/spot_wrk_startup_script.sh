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
apt-get install -y build-essential libssl-dev git unzip liblua5.1-0-dev

# 2. Setup user and directory
USER_NAME="shouvik"
mkdir -p /home/$USER_NAME/script
mkdir -p /var/log/wrk
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/script /var/log/wrk

# 3. Build wrk from source if not present
if [ ! -f /usr/local/bin/wrk ]; then
    cd /home/$USER_NAME/
    git clone https://github.com/wg/wrk.git wrk
    cd wrk
    sudo make
    cp wrk /usr/local/bin
fi

# 4. Create the Lua path file
cat <<EOF > /home/$USER_NAME/script/waf_paths.lua
local paths = {
  "/", "/get?id=1'%20OR%20'1'='1", "/base64?name=<script>alert(1)</script>",
  "/anything?url=http://169.254.169.254/latest/meta-data/", "/headers"
}
math.randomseed(os.time())
request = function()
  return wrk.format("GET", paths[math.random(#paths)])
end
EOF

# 5. Create the inner test script
cat <<EOF > /home/$USER_NAME/script/waf_test_wrk.sh
#!/bin/bash
TARGET_URL=\$1
DURATION=\$2
wrk -t2 -c10 -d\$DURATION -s /home/$USER_NAME/script/waf_paths.lua "\$TARGET_URL"
EOF

# 6. Create the master runner script
cat <<EOF > /home/$USER_NAME/script/waf_run_all.sh
#!/bin/bash
/home/$USER_NAME/script/waf_test_wrk.sh https://secure-api.shouvik.dev 1h >> /var/log/wrk/instance1.log 2>&1 &
/home/$USER_NAME/script/waf_test_wrk.sh https://api.shouvik.dev 1h >> /var/log/wrk/instance2.log 2>&1 &
/home/$USER_NAME/script/waf_test_wrk.sh https://insecure-api.shouvik.dev 1h >> /var/log/wrk/instance3.log 2>&1 &
/home/$USER_NAME/script/waf_test_wrk.sh https://httpbin.shouvik.us 1h >> /var/log/wrk/instance4.log 2>&1 &
wait
EOF

# 7. Set permissions
chmod +x /home/$USER_NAME/script/*.sh
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/script

# 8. Create and Start Systemd Service
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