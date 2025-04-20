FROM python:3.13-slim

WORKDIR /app

COPY order-v1.py .

RUN pip install --no-cache-dir boto3

CMD ["python", "order-v1.py"]