FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app/src \
    PERSON_DETECT_DASHBOARD_ENABLED=true \
    PERSON_DETECT_DASHBOARD_HOST=0.0.0.0 \
    PERSON_DETECT_SHOW_WINDOW=false \
    PERSON_DETECT_ALERT_LOG_PATH=/app/data/alerts.log \
    PERSON_DETECT_DATABASE_PATH=/app/data/alerts.db \
    PERSON_DETECT_OUTPUT_PATH=/app/data/outputs/person_detection.mp4

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
        libsm6 \
        libxext6 \
        libxrender1 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system appuser \
    && useradd --system --create-home --gid appuser appuser

COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt

COPY --chown=appuser:appuser src ./src
COPY --chown=appuser:appuser yolov8n.pt ./yolov8n.pt

RUN mkdir -p /app/data/outputs \
    && chown -R appuser:appuser /app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
  CMD python -c "from urllib.request import urlopen; response = urlopen('http://127.0.0.1:5000/login', timeout=5); raise SystemExit(0 if response.status == 200 else 1)"

USER appuser

CMD ["python", "-m", "person_detection", "--dashboard", "--dashboard-host", "0.0.0.0"]
