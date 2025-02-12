{% set dest_host, dest_port = v2_reality_dest.split(':') %}
SELF_PUBLIC_IP=$(curl -4 https://1.1.1.1/cdn-cgi/trace | grep 'ip=' | cut -c4-)

curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_vision&traffic={{ traffic }}' --data-urlencode "subscription={name: {{ sub_id }}_vision_reality,type: vless,server: $SELF_PUBLIC_IP,port: {{ v2_vision_port }},uuid: {{ v2_uuid }},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: {{ dest_host }},reality-opts: {public-key: {{v2_reality_pk}},short-id: ae},client-fingerprint: chrome}"
curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_grpc&traffic={{ traffic }}' --data-urlencode "subscription={name: {{ sub_id }}_grpc_reality,type: vless,server: $SELF_PUBLIC_IP,port: {{ v2_grpc_port }},uuid: {{ v2_uuid }},network: grpc,tls: true,udp: true,servername: {{ dest_host }},reality-opts: {public-key: {{v2_reality_pk}},short-id: ae},client-fingerprint: chrome,grpc-opts:{grpc-service-name: grpc}}"

{% if ipv6_sub %}
SELF_PUBLIC_IPV6=$(curl -6 https://[2606:4700:4700::1111]/cdn-cgi/trace | grep 'ip=' | cut -c4-)

curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_v6_vision&traffic={{ traffic }}' --data-urlencode "subscription={name: {{ sub_id }}_v6_vision_reality,type: vless,server: $SELF_PUBLIC_IPV6,port: {{ v2_vision_port }},uuid: {{ v2_uuid }},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: {{ dest_host }},reality-opts: {public-key: {{v2_reality_pk}},short-id: ae},client-fingerprint: chrome}"
curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_v6_grpc&traffic={{ traffic }}' --data-urlencode "subscription={name: {{ sub_id }}_v6_grpc_reality,type: vless,server: $SELF_PUBLIC_IPV6,port: {{ v2_grpc_port }},uuid: {{ v2_uuid }},network: grpc,tls: true,udp: true,servername: {{ dest_host }},reality-opts: {public-key: {{v2_reality_pk}},short-id: ae},client-fingerprint: chrome,grpc-opts:{grpc-service-name: grpc}}"
{% endif %}
