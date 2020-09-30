#!/bin/bash
step=5

for (( i = 0; i < 60; i=(i+step) )); do
    curl "http://mapi.mcache/api/cache/refresh"
    sleep $step
done

exit 0