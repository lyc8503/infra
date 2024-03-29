curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}&cf=1' --data-urlencode "subscription={name: {{ sub_id }}_GRPC, server: {{ v2_domain }}, port: 443, type: vmess, uuid: {{ v2_uuid }}, alterId: 0, cipher: auto, tls: true, servername: {{ v2_domain }}, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}"

CLOUDFLARED_DOMAIN=$(curl -v 127.0.0.1:2333/quicktunnel | jq -r ".hostname")
if [ -n "$CLOUDFLARED_DOMAIN" ]; then
    curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_cloudflared&cf=1' --data-urlencode "subscription={name: {{ sub_id }}_WS, server: $CLOUDFLARED_DOMAIN, port: 443, type: vmess, uuid: {{ v2_uuid }}, alterId: 0, cipher: auto, tls: true, servername: $CLOUDFLARED_DOMAIN, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: $CLOUDFLARED_DOMAIN }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}"
fi