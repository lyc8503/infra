SELF_PUBLIC_IP=$(curl -4 https://1.1.1.1/cdn-cgi/trace | grep 'ip=' | cut -c4-)

curl -G '{{ sub_server }}?token={{ reg_password }}&id={{ sub_id }}_hy2&traffic={{ traffic }}' --data-urlencode "subscription={name: {{ sub_id }}_hy2,type: hysteria2,server: $SELF_PUBLIC_IP,port: {{ hy2_port }},password: {{ v2_uuid }},skip-cert-verify: true,client-fingerprint: chrome}"
