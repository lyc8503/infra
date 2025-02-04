FROM python:3.11.7-alpine

WORKDIR /

ENV TZ="Asia/Shanghai"

RUN pip3 install apscheduler requests

COPY log_forward.py log_forward.py

CMD ["python3", "log_forward.py"]
