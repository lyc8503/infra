from fastapi import FastAPI, Response
from fastapi.responses import PlainTextResponse
import os

app = FastAPI()


def get_sub():
    return """
proxies:
  - {name: Default, server: V2RAY_DOMAIN, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选azhz, server: cn.azhz.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选whoint, server: www.who.int, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选hostmonit, server: blog.hostmonit.com, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选cfnode, server: cloudflare.cfgo.cc, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
  - {name: 优选cfnodeEU, server: default.cfnode.eu.org, port: 443, type: vmess, uuid: UUID, alterId: 0, cipher: auto, tls: true, servername: V2RAY_DOMAIN, client-fingerprint: chrome, network: grpc, grpc-opts: { grpc-service-name: v2grpc }, udp: true}
""".replace("V2RAY_DOMAIN", os.environ['V2RAY_DOMAIN']).replace("UUID", os.environ['UUID'])


@app.get("/", response_class=PlainTextResponse)
async def root(resp: Response, config: str = '', admin: str = ''):
    
    if admin == os.environ['ADMIN_PASSWORD']:
        return get_sub()
    
    if config:
        return 'TODO'

    resp.status_code = 403
    return "ILLEGAL REQUEST"