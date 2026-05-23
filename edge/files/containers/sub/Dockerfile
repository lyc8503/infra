FROM python:3.11.7-alpine

WORKDIR /

RUN pip3 install uvicorn requests fastapi pyyaml

COPY sub.py /sub.py

CMD ["uvicorn", "--host", "0.0.0.0", "--port", "8002", "sub:app"]
