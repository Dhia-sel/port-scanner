FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN mkdir -p /backups
COPY src/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ /app/
RUN chmod +x /app/scan.sh
EXPOSE 5000
CMD ["python", "app.py"]
