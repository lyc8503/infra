# -*- coding: utf-8 -*-
# This file is managed by ansible, do not modify manually.
from bases.FrameworkServices.SimpleService import SimpleService
import requests

def fetch_latest():
    r1 = requests.get("http://127.0.0.1:19999/api/v1/allmetrics?filter=cgroup*&format=json").json()
    r2 = requests.get("http://127.0.0.1:19999/api/v1/allmetrics?filter=*temperature&format=json").json()
    return r1, r2

NETDATA_UPDATE_EVERY = 1
TEMPRATURE_WHILELIST = ["smartctl.device_sd", "nvme-pci", "coretemp-isa", "systin"]
priority = 1000

ORDER = [
    'cgroup_cpu',
    'cgroup_mem',
    'temperature'
]

CHARTS = {
    'cgroup_cpu': {
        'options': ["cgroup_cpu", 'Containers & VMs CPU usage', 'percentage', 'cpu', 'cgroup.cpu', 'line'],
        'lines': []
    },
    'cgroup_mem': {
        'options': ["cgroup_mem", 'Containers & VMs memory usage', 'MiB', 'mem', 'cgroup.mem', 'line'],
        'lines': []
    },
    'temperature': {
        'options': ["temperature", 'Temperature', 'Celsius', 'temp', 'temperature', 'line'],
        'lines': []
    }
}


class Service(SimpleService):
    def __init__(self, configuration=None, name=None):
        SimpleService.__init__(self, configuration=configuration, name=name)
        self.order = ORDER
        self.definitions = CHARTS

    @staticmethod
    def check():
        return True

    def get_data(self):
        data = dict()
        r1, r2 = fetch_latest()

        for k in r1: 
            if k.endswith(".cpu"):
                dim = k.replace("cgroup_", "")
                if dim not in self.charts['cgroup_cpu']:
                    self.charts['cgroup_cpu'].add_dimension([dim, dim.replace(".cpu", ""), None, None, 100])

                data[dim] = sum(map(lambda x: x["value"] * 100, r1[k]["dimensions"].values()))

            if k.endswith(".mem"):
                dim = k.replace("cgroup_", "")
                if dim not in self.charts['cgroup_mem']:
                    self.charts['cgroup_mem'].add_dimension([dim, dim.replace(".mem", ""), None, None, 1000])
                    
                data[dim] = r1[k]["dimensions"]["anon"]["value"] * 1000

        for k in r2:
            if any([i in k for i in TEMPRATURE_WHILELIST]):
                dim = k.replace("sensors.sensor_chip_", "").replace("smartctl.device_", "")
                if r2[k]["dimensions"]["temperature"]["value"] is None:
                    continue

                if dim not in self.charts['temperature']:
                    self.charts['temperature'].add_dimension([dim, dim, None, None, 1000])

                data[dim] = r2[k]["dimensions"]["temperature"]["value"] * 1000

        return data
