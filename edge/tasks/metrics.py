from io import StringIO

from pyinfra import host
from pyinfra.operations import apt, files, server, systemd

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

files.put(
    name="Add Grafana Alloy APT repo",
    src=StringIO("deb [trusted=yes] https://apt.grafana.com stable main\n"),
    dest="/etc/apt/sources.list.d/grafana.list",
)

apt.packages(
    name="Install Alloy",
    packages=["alloy"],
    update=True
)

alloy_config = f"""prometheus.exporter.unix "local_system" {{
  disable_collectors = ["systemd"]
  netclass {{
    ignored_devices = "^(br|veth|fw).*"
  }}
}}

prometheus.scrape "scrape_metrics" {{
  targets = prometheus.exporter.unix.local_system.targets
  forward_to = [prometheus.relabel.filter_metrics.receiver]
}}

prometheus.relabel "filter_metrics" {{
  forward_to = [prometheus.remote_write.prom.receiver]
}}

prometheus.remote_write "prom" {{
  endpoint {{
    url = "{d.push_endpoint}"
  }}
}}

loki.source.journal "read"  {{
  forward_to    = [loki.write.endpoint.receiver]
  labels        = {{component = "{host.name}"}}
}}

loki.write "endpoint" {{
  endpoint {{
    url = "{d.loki_endpoint}"
  }}
}}
"""

config = files.put(
    name="Put Alloy config",
    src=StringIO(alloy_config),
    dest="/etc/alloy/config.alloy",
)

systemd.service(
    name="Enable and start Alloy",
    service="alloy",
    running=True,
    enabled=True,
    restarted=config.changed,
)
