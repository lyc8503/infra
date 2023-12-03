from fastapi import FastAPI, Response, Request
from fastapi.responses import PlainTextResponse
import os
import hashlib
import time

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
    return """mixed-port: 7890
ipv6: true
allow-lan: false
mode: Rule
log-level: info
external-controller: :9090

proxies:
  - {name: Default, server: V2RAY_DOMAIN, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选azhz, server: cn.azhz.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选whoint, server: www.who.int, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选hostmonit, server: blog.hostmonit.com, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选cfnode, server: cloudflare.cfgo.cc, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选cfnodeEU, server: default.cfnode.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}

proxy-groups:
  - name: CN
    type: select
    proxies:
      - Default
      - 优选azhz
      - 优选whoint
      - 优选hostmonit
      - 优选cfnode
      - 优选cfnodeEU
  - name: Proxy
    type: select
    proxies:
      - Default
      - 优选azhz
      - 优选whoint
      - 优选hostmonit
      - 优选cfnode
      - 优选cfnodeEU
  - name: Other
    type: select
    proxies:
      - Default
      - 优选azhz
      - 优选whoint
      - 优选hostmonit
      - 优选cfnode
      - 优选cfnodeEU

rules:
  - GEOSITE,cn,CN
  - GEOSITE,geolocation-!cn,Proxy
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,CN
  - MATCH,Other
""".replace("V2RAY_DOMAIN", os.environ['V2RAY_DOMAIN']).replace("UUID", os.environ['UUID'])


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
