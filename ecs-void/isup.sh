#!/bin/bash

URL=$1
MAX_ATTEMPTS=30

for attempt in `seq 1 $MAX_ATTEMPTS`
do
    echo -n .
    STATUS_CODE=`curl -s --connect-timeout 2 -o /dev/null -w "%{http_code}" "$URL"`
    if [ "$STATUS_CODE" = "200" ]; then
        exit 0
    fi
    sleep 1
done

# ensure newline
echo ""
echo "Asked $MAX_ATTEMPTS times and the service ($URL) is still not answering 200"
exit 1