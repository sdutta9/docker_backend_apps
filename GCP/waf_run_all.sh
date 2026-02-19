#!/bin/bash

# Instance 1:
/home/shouvik/script/waf_test_wrk.sh https://secure-api.shouvik.dev 1h >> /var/log/wrk/instance1.log 2>&1 &

# Instance 2:
/home/shouvik/script/waf_test_wrk.sh https://api.shouvik.dev 1h >> /var/log/wrk/instance2.log 2>&1 &

# Instance 3:
/home/shouvik/script/waf_test_wrk.sh https://insecure-api.shouvik.dev 1h >> /var/log/wrk/instance3.log 2>&1 &

# Wait for all background processes to finish
wait