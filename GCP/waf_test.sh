#!/bin/bash

# Arguments
TARGET_URL=${1:-"https://your-domain.com"}
DURATION=${2:-"2h"} # Default to 2 hours if not specified

# Calculate end time in seconds
END_TIME=$(( $(date +%s) + $(date -d "$DURATION" +%s -u 2>/dev/null || echo $(( ${DURATION%h} * 3600 )) ) ))

# Define the "attacks"
declare -A payloads
# payloads["A03:Injection (SQLi)"]="/get?id=1'%20OR%20'1'='1"
# # payloads["A03:Injection (NoSQL)"]="/api/login?user[\$ne]=null"
# # payloads["A01:Broken Access Control"]="/admin/config.php"
# payloads["A03:XSS"]="/html?name=<script>alert(1)</script>"
# payloads["A10:SSRF"]="/anything?url=http://169.254.169.254/latest/meta-data/"
# payloads["Homepage"]="/"
# payloads["Styles"]="/flasgger_static/swagger-ui.css"
# payloads["Images"]="/images/jpeg"
# payloads["Contact"]="/anything"


payloads[0]="/get?id=1'%20OR%20'1'='1"                                  # A03:Injection (SQLi)
payloads["A03:Injection (NoSQL)"]="/basic-auth?user[\$ne]=null"         # A03:Injection (NoSQL)
# payloads["A01:Broken Access Control"]="/admin/config.php"             # A01:Broken Access Control
payloads[1]="/base64?name\=\%3Cscript\%3Ealert\(1\)\%3C/script\%3E"     # A03:XSS
payloads[2]="/anything?url=http://169.254.169.254/latest/meta-data/"    # A10:SSRF
payloads[3]="/$%7Bpwd%7D/serverless.yaml"                                   # likely attack
payloads[4]="/flasgger_static/swagger-ui.css"
payloads[5]="/image/jpeg"
payloads[6]="/html"

echo "----------------------------------------------------"
echo " WAF Demo running against: $TARGET_URL"
echo " Duration: $DURATION (Ends at $(date -d @$END_TIME))"
echo "----------------------------------------------------"


while [ $(date +%s) -lt $END_TIME ]; do
    for attack in "${!payloads[@]}"; do
        path=${payloads[$attack]}
        full_url="${TARGET_URL}${path}"

        # -s: Silent, -o: discard body, -w: return status code
        status=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" "$full_url")

        if [ "$status" == "403" ]; then
            echo "$(date +%H:%M:%S) [BLOCKED] $full_url"
        else
            echo "$(date +%H:%M:%S) [ALLOWED] $full_url (Status: $status)"
        fi
        
        # Short sleep to prevent hitting rate limits on your own machine
        sleep 2
    done
done

echo "Demo duration reached. Exiting."