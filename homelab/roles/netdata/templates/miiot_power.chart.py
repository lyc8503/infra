# -*- coding: utf-8 -*-
# This file is managed by ansible, do not modify manually.
from bases.FrameworkServices.SimpleService import SimpleService
from miio import GenericMiot

NETDATA_UPDATE_EVERY = 1
mi_dev = GenericMiot("192.168.1.244", "248e201bed14c01cec1e44de04e0ec26")

ORDER = [
    'power_usage'
]
priority = 1000

CHARTS = {
    'power_usage': {
        'options': ["power_usage", 'Power usage', 'watt', None, None, 'line'],
        'lines': [["power_usage", "Server current power usage", None, None, None]]
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
        # ID: 11-2 is current power usage in watts
        data['power_usage'] = mi_dev.get_property_by(11, 2)[0]['value']
        return data
