from fastapi import FastAPI, Response, Request
from fastapi.responses import PlainTextResponse
import os
import hashlib
import time
import yaml
import copy

app = FastAPI()

proxies = {}

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

def get_sub(min_traffic, hysteria_up = 0, hysteria_down = 0):
    payload = {
        "proxies": [],
        "use_proxies": {
            "proxies": ["DIRECT", "REJECT"]
        }
    }

    for p in proxies.items():
        id, [sub, cf, traffic] = p

        if traffic < min_traffic:
            continue
        
        if hysteria_up > 0 and hysteria_down > 0 and 'type' in sub and sub['type'] == 'hysteria2':
            sub['up'] = f'{hysteria_up} Mbps'
            sub['down'] = f'{hysteria_down} Mbps'
        
        payload['proxies'].append(sub)
        payload['use_proxies']['proxies'].append(sub['name'])

        # Add optimized IPs for Cloudflare-based proxies
        if cf:
            for optimized in [
                    ("优选", "blog.hostmonit.com")
                ]:
                sub_opt = copy.deepcopy(sub)
                sub_opt['name'] = str(sub_opt['name']) + "_" + optimized[0]
                sub_opt['server'] = optimized[1]
                payload['proxies'].append(sub_opt)
                payload['use_proxies']['proxies'].append(sub_opt['name'])

    
    payload = yaml.dump(payload, allow_unicode=True).replace("use_proxies:", "use_proxies: &use_proxies")
    
    return """mixed-port: 7890
ipv6: true
allow-lan: false
mode: Rule
log-level: info
external-controller: :9090

###PAYLOAD###

proxy-groups:
  - name: 代理选择
    type: select
    <<: *use_proxies
  
  - name: 国内直连
    type: select
    proxies:
      - DIRECT
      - 代理选择
  
  - name: 海外网站
    type: select
    proxies:
      - DIRECT
      - 代理选择

  - name: 漏网之鱼
    type: select
    proxies:
      - DIRECT
      - 代理选择

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
  - RULE-SET,direct,国内直连
  - RULE-SET,proxy,海外网站
  - RULE-SET,gfw,海外网站
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,国内直连
  - MATCH,漏网之鱼
""".replace("###PAYLOAD###", payload)


@app.get("/", response_class=PlainTextResponse)
async def root(req: Request, resp: Response, admin: str = '', sign: str = '', issuer: str = '', sub: str = '', expire: int = 0, min_traffic: int = 200, up: int = 0, down: int = 0):

    # Admin access
    if admin == os.environ['ADMIN_PASSWORD']:
        return get_sub(-1, up, down)

    # Sign
    params = list(req.query_params.items())
    params = list(filter(lambda x: x[0] not in ['host', 'sign', 'up', 'down'], params))  # host is always included in params smh
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
        return get_sub(min_traffic, up, down)
    
    resp.status_code = 400
    return 'WTF? HOW DID YOU GET HERE?'


@app.get("/reg", response_class=PlainTextResponse)
async def reg(req: Request, resp: Response, token, id, subscription: str = "", cf: bool = False, traffic: int = 500):
    if token != os.environ['REG_PASSWORD']:
        resp.status_code = 403
        return 'WRONG TOKEN'

    global proxies

    if subscription == "":
        if id in proxies:
            del proxies[id]
        return 'DELETED, LEFT: ' + ",".join(proxies.keys())

    proxies[id] = (yaml.safe_load(subscription), cf, traffic)
    return 'ADDED'
