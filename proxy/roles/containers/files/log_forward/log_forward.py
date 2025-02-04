import datetime
import re
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
import logging
import os
import requests

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)

log_rules = {
    'homelab-pve': [
        '.*authentication failure.*',
        '.*successful auth.*',
        '.*(Accepted|preauth).*sshd.*'
    ],
    'homelab-openwrt': [
        '.*login.*',
        '.*publickey.*'
    ]
}


def bot_push(msg):
    for _ in range(3):
        try:
            return requests.post("http://tgbot:8000/push", json={
                "key": "wepushkey",
                "msg": msg
            }, timeout=5)
        except Exception as e:
            logging.error(f"Failed to push message: {e}")


def scheduled_task():
    now = datetime.datetime.now()
    end = now.replace(second=0, microsecond=0)
    start = end - datetime.timedelta(minutes=1)

    url = f'https://{os.environ["LOKI_TOKEN"]}@logs-prod-020.grafana.net/loki/api/v1/query_range'
    params = {
        'query': '{service_name=~".+"}',
        'start': int(start.timestamp() * 1000 ** 3),
        'end': int(end.timestamp() * 1000 ** 3),
        'limit': 5000
    }

    logging.info(f"Fetch logs from {start.strftime('%Y-%m-%d %H:%M:%S')} to {end.strftime('%Y-%m-%d %H:%M:%S')}")

    for _ in range(3):
        try:
            r = requests.get(url, params=params, timeout=10).json()
            break
        except Exception as e:
            logging.error(f"Failed to fetch logs: {e}")

    for stream in r['data']['result']:
        logging.info(f'Fetched {len(stream["values"])} log from {stream["stream"]["service_name"]}')
        if stream['stream']['service_name'] not in log_rules:
            continue
        for entry in stream['values']:
            for rule in log_rules[stream['stream']['service_name']]:
                if re.match(rule, str(entry[1])):
                    time = datetime.datetime.fromtimestamp(int(entry[0]) / 1000 ** 3).strftime('%Y-%m-%d %H:%M:%S')
                    msg = f'Log from {stream["stream"]["service_name"]} at {time}:\n{entry[1]}'
                    logging.info(f'Matched log from {stream["stream"]["service_name"]}: {entry[1]}')
                    bot_push(msg)

scheduler = BlockingScheduler()
scheduler.add_job(scheduled_task, CronTrigger(second=40))
scheduler.start()

if __name__ == "__main__":
    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        pass
