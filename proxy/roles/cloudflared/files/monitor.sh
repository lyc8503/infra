#!/bin/bash

if [[ $(curl $(curl http://localhost:2333/quicktunnel | jq -r ".hostname")"/websocket") = "Bad Request" ]]; then
    echo Tunnel working...
    exit 0
fi

echo First time: not working, retest 60 secs later
sleep 60

if [[ $(curl $(curl http://localhost:2333/quicktunnel | jq -r ".hostname")"/websocket") = "Bad Request" ]]; then
    echo Tunnel working...
    exit 0
fi

echo Restarting tunnel...
systemctl restart cloudflared
