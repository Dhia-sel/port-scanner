FROM python:3.10-slim
RUN apt-get update && apt-get install -y \
    nmap \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN mkdir -p /backups
COPY app/src/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY app/ /app/
RUN chmod +x /app/src/scan.sh 2>/dev/null || true
EXPOSE 5000
CMD ["python", "src/app.py"]
