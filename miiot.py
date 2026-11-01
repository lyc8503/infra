import base64, os, time
from miio import GenericMiot
# pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.resources import Resource

mi_dev = GenericMiot(os.environ['MIIOT_IP'], os.environ['MIIOT_TOKEN'])

auth = base64.b64encode(f"{os.environ['GLC_AUTH']}".encode()).decode()
exporter = OTLPMetricExporter(
    endpoint="https://otlp-gateway-prod-ap-southeast-1.grafana.net/otlp/v1/metrics",
    headers={"Authorization": f"Basic {auth}"},
)

provider = MeterProvider(
    resource=Resource.create({"service.name": "homelab-iot"}),
    metric_readers=[PeriodicExportingMetricReader(exporter, export_interval_millis=5_000)],
)

metrics.set_meter_provider(provider)

gauge = metrics.get_meter("meter").create_gauge("miiot_power", unit="W")

while True:
    try:
        power = mi_dev.get_property_by(11, 2)[0]['value']
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Current power: {power} W")
        gauge.set(power)
    except Exception as e:
        print(f"Error occurred while fetching power: {e}")
    time.sleep(5)
