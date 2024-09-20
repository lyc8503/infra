# -*- coding: utf-8 -*-
from bases.FrameworkServices.SimpleService import SimpleService
import requests

def fetch_latest():
    return requests.get("http://127.0.0.1:19999/api/v1/allmetrics?filter=cgroup*&format=json").json() 

NETDATA_UPDATE_EVERY = 1
priority = 1000

ORDER = [
    'cgroup_cpu',
    'cgroup_mem'
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
        resp = fetch_latest()

        for k in resp: 
            if k.endswith(".cpu"):
                dim = k.replace("cgroup_", "")
                if dim not in self.charts['cgroup_cpu']:
                    self.charts['cgroup_cpu'].add_dimension([dim, dim.replace(".cpu", ""), None, None, 100])

                data[dim] = sum(map(lambda x: x["value"] * 100, resp[k]["dimensions"].values()))

            if k.endswith(".mem"):
                dim = k.replace("cgroup_", "")
                if dim not in self.charts['cgroup_mem']:
                    self.charts['cgroup_mem'].add_dimension([dim, dim.replace(".mem", ""), None, None, 1000])
                    
                data[dim] = resp[k]["dimensions"]["anon"]["value"] * 1000

        return data
