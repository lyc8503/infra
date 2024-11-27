import datetime
import hashlib

key = "233"
params = []

print("以下内容建议只使用大小写英文字母、数字、下划线、连字符(-)")
issuer = input("请输入签名人名称:")
subject = input("被颁发给:")
params.append(("issuer", issuer))
params.append(("sub", subject))

t = input("输入有效时间(单位:天):")
expire_date = datetime.datetime.now() + datetime.timedelta(days=int(t))
params.append(("expire", int(expire_date.timestamp())))

traffic = input(
    "输入服务器最小流量要求(单位:GB)(建议留空取默认值, 填写越小的值可以得到越高质量的服务器, 对于流量使用大的场景, 建议填写较大的值(参考范围:200-1000), 强烈建议不要小于200, 只在完全信任可控且流量使用小的场景下可以填写0):"
)
if traffic == "":
    traffic = "<取服务器默认值>"
else:
    params.append(("min_traffic", traffic))

print("==========摘要==========")
print("签名人:", issuer)
print("被颁发给:", subject)
print("有效期至:", expire_date.strftime("%Y-%m-%d %H:%M:%S"))
print("服务器最小流量要求:", traffic)
print("========================")

input("请确认以上信息无误, 按回车继续, 按Ctrl+C取消.")

params.sort(key=lambda x: x[0])
sign_str = "&".join(list(map(lambda x: f"{x[0]}={x[1]}", params)))
sign = hashlib.sha1((sign_str + key).encode("utf-8")).hexdigest()

print("签名后的链接: https://example.com/?" + sign_str + "&sign=" + sign)
input("签名完成, 建议保留签名链接副本供吊销使用. 按回车退出.")
