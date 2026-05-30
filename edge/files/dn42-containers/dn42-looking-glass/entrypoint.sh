#!/bin/bash
set -e

LG_PROXY_PORT=8000
LG_FRONTEND_PORT=${LG_FRONTEND_PORT:-5000}
LG_SERVERS=${LG_SERVERS:-"localhost"}
LG_DOMAIN=${LG_DOMAIN:-"dn42.42420167.xyz"}

# Start proxy (talks to bird socket)
/opt/bird-lg/proxy --bird /run/bird/bird.ctl --listen "0.0.0.0:${LG_PROXY_PORT}" &

# Wait briefly for proxy to be ready
sleep 1

# Start frontend
exec /opt/bird-lg/frontend \
    --servers "$LG_SERVERS" \
    --domain "$LG_DOMAIN" \
    --proxy-port "$LG_PROXY_PORT" \
    --listen "0.0.0.0:${LG_FRONTEND_PORT}"
