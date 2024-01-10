FROM python:3.11.7-alpine

WORKDIR /

RUN pip3 install uvicorn requests fastapi

COPY sub.py /sub.py

CMD ["uvicorn", "sub:app"]
