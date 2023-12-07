from fastapi import FastAPI, Response, Request
from fastapi.responses import PlainTextResponse
import os
import hashlib
import time
import requests

app = FastAPI()


def get_expire():
    return """mixed-port: 7890
ipv6: true
allow-lan: false
mode: Rule
log-level: info
external-controller: :9090

proxies:
  - {name: 订阅过期，请更新订阅链接, server: invalid.com, port: 443, type: vmess, uuid: 12345678-abcd-1234-1234-abcdabcdabcd, alterId: 0, cipher: auto, tls: false, skip-cert-verify: false}

proxy-groups:
  - name: EXPIRE
    type: select
    proxies:
      - 订阅过期，请更新订阅链接

rules:
  - MATCH,DIRECT
"""

def get_sub():
    domain = os.environ['V2RAY_DOMAIN']
    domain_ws = requests.get('http://127.0.0.1:2333/quicktunnel').json()['hostname']
    return """mixed-port: 7890
ipv6: true
allow-lan: false
mode: Rule
log-level: info
external-controller: :9090

proxies:
  - {name: GRPC_Default, server: V2RAY_DOMAIN, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: GRPC_优选azhz, server: cn.azhz.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: GRPC_优选whoint, server: www.who.int, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: GRPC_优选hostmonit, server: blog.hostmonit.com, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: GRPC_优选cfnode, server: cloudflare.cfgo.cc, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: GRPC_优选cfnodeEU, server: default.cfnode.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}

  - {name: WS_Default, server: V2RAY_DOMAIN_WS, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}
  - {name: WS_优选azhz, server: cn.azhz.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}
  - {name: WS_优选whoint, server: www.who.int, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}
  - {name: WS_优选hostmonit, server: blog.hostmonit.com, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}
  - {name: WS_优选cfnode, server: cloudflare.cfgo.cc, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}
  - {name: WS_优选cfnodeEU, server: default.cfnode.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN_WS, client-fingerprint: chrome, network: ws, ws-opts: { path: /websocket, headers: { Host: V2RAY_DOMAIN_WS }, max-early-data: 2048, early-data-header-name: Sec-WebSocket-Protocol }, udp: true}

use_proxies: &use_proxies
  proxies:
    - DIRECT
    - REJECT
    - GRPC_Default
    - GRPC_优选azhz
    - GRPC_优选whoint
    - GRPC_优选hostmonit
    - GRPC_优选cfnode
    - GRPC_优选cfnodeEU
    - WS_Default
    - WS_优选azhz
    - WS_优选whoint
    - WS_优选hostmonit
    - WS_优选cfnode
    - WS_优选cfnodeEU

proxy-groups:
  - name: CN
    type: select
    <<: *use_proxies
  - name: Proxy
    type: select
    <<: *use_proxies
  - name: Other
    type: select
    <<: *use_proxies

rule-providers:
  direct:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt"
    path: ./ruleset/direct.yaml
    interval: 86400

  proxy:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt"
    path: ./ruleset/proxy.yaml
    interval: 86400

  gfw:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt"
    path: ./ruleset/gfw.yaml
    interval: 86400


rules:
  - RULE-SET,direct,CN
  - RULE-SET,proxy,Proxy
  - RULE-SET,gfw,Proxy
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,CN
  - MATCH,Other
""".replace("V2RAY_DOMAIN_WS", domain_ws).replace("V2RAY_DOMAIN", domain).replace("UUID", os.environ['UUID'])


@app.get("/", response_class=PlainTextResponse)
async def root(req: Request, resp: Response, admin: str = '', sign: str = '', issuer: str = '', sub: str = '', expire: int = 0):

    # Admin access
    if admin == os.environ['ADMIN_PASSWORD']:
        return get_sub()

    # Sign
    params = list(req.query_params.items())
    params = list(filter(lambda x: x[0] not in ['sign', 'host'], params))
    params.sort(key=lambda x: x[0])
    sign_str = '&'.join(list(map(lambda x: f'{x[0]}={x[1]}', params)))

    # DO NOT invent an MAC function by yourself in production. This is a wrong example.
    expected_sign = hashlib.sha1((sign_str + os.environ['ADMIN_PASSWORD']).encode("utf-8")).hexdigest()

    if sign != expected_sign:
        resp.status_code = 403
        return 'MISSING OR INVALID SIGNATURE, STRING TO SIGN: "' + sign_str + '"'
    
    if issuer and sub and expire:
        if time.time() > expire:
            return get_expire()
        return get_sub()
    
    resp.status_code = 400
    return 'WTF? HOW DID YOU GET HERE?'
