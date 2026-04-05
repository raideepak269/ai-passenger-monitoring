# Webcam Person Detection, Tracking, and Behavior Analysis

This project provides a production-oriented Python application for detecting, tracking, and analyzing people from a webcam feed using OpenCV, Ultralytics YOLOv8, and DeepSORT. It is structured as a reusable package, exposes a CLI, supports environment-driven configuration, and includes unit tests for the core logic that does not require a real camera.

## Features

- `src/`-based package layout
- Typed, modular code for config, camera IO, detection, tracking, behavior analysis, rendering, and output
- Dedicated alerting module for sound playback, console output, file logging, and SQLite persistence
- CLI entrypoint and `main.py` convenience launcher
- Environment variable configuration via `PERSON_DETECT_*`
- Deployment assets for Docker, Docker Compose, and bare-metal server installs
- Multi-camera support with independent pipelines and stable camera IDs
- DeepSORT multi-object tracking with stable person IDs
- Per-person movement trails built from retained center-point history
- ML-style behavior classification for loitering and running
- Structured alert events written to stdout, saved as JSON Lines or CSV, and stored in SQLite
- Query helpers for recent logs and camera, track, or behavior-specific history
- Optional Flask dashboard with a live webcam stream, current counts, suspicious activity feed, and login protection
- Optional annotated video recording
- Graceful shutdown with `q`, `Q`, `Esc`, or `Ctrl+C`
- Import-light tests for config validation, detection filtering, tracking helpers, and behavior analysis

## Project Layout

```text
.
|-- .env.example
|-- .dockerignore
|-- Dockerfile
|-- main.py
|-- pyproject.toml
|-- README.md
|-- requirements.txt
|-- docker-compose.yml
|-- src/
|   `-- person_detection/
|       |-- __init__.py
|       |-- __main__.py
|       |-- alerts.py
|       |-- app.py
|       |-- behavior.py
|       |-- camera.py
|       |-- cli.py
|       |-- config.py
|       |-- database.py
|       |-- dashboard.py
|       |-- detector.py
|       |-- exceptions.py
|       |-- logging_config.py
|       |-- metrics.py
|       |-- models.py
|       |-- output.py
|       |-- processing.py
|       |-- renderer.py
|       |-- tracking.py
|       |-- workers.py
|       `-- runtime.py
`-- tests/
    |-- test_alerts.py
    |-- test_behavior.py
    |-- test_dashboard.py
    |-- test_config.py
    |-- test_cli.py
    |-- test_database.py
    |-- test_detector.py
    `-- test_tracking.py
```

## Quick Start

1. Install Python 3.10 or newer.
2. Create and activate a virtual environment.
3. Install the project.
4. Run the webcam detector, tracker, and behavior analyzer.

Windows PowerShell example:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e .
python main.py
```

Console script example after install:

```powershell
person-detect-webcam
```

Dashboard script example after install:

```powershell
person-detect-dashboard
```

Package module example:

```powershell
python -m person_detection
```

The first launch may download the pretrained YOLOv8 weights if they are not already cached locally.

## CLI Usage

```powershell
python main.py --camera-index 0 --confidence 0.5 --device cpu
python main.py --camera-indices 0,1 --camera-id-prefix gate --dashboard
python main.py --save-output --output-path outputs\session.mp4
python main.py --no-show-window --save-output --max-fps 15
python main.py --camera-backend dshow --frame-width 1280 --frame-height 720
python main.py --tracker-max-age 45 --track-history-length 60
python main.py --loitering-min-duration-seconds 20 --running-speed-threshold-px-per-sec 250
python main.py --alert-sound --alert-log-path alerts.log
python main.py --alert-log-path alerts.csv
python main.py --database-enabled --database-path alerts.db
python main.py --dashboard --dashboard-host 127.0.0.1 --dashboard-port 5000
python main.py --dashboard --dashboard-username ops --dashboard-password s3cret
```

Available configuration is also exposed through environment variables. Copy `.env.example`, set the values you want in your shell or service manager, and then run the app.

## Common Options

- `--model`: YOLO weights path, default `yolov8n.pt`
- `--camera-index`: webcam index, default `0`
- `--camera-indices`: comma-separated camera indices for multi-camera mode
- `--camera-id-prefix`: prefix used to derive stable camera IDs such as `cam-0`
- `--camera-backend`: one of `auto`, `dshow`, `msmf`, `v4l2`, `ffmpeg`
- `--confidence`: confidence threshold
- `--iou`: NMS IoU threshold
- `--imgsz`: inference image size
- `--device`: inference device such as `cpu`, `0`, or `0,1`
- `--show-window` or `--no-show-window`: toggle live preview window
- `--save-output`: save annotated frames to a video file
- `--output-path`: output video path
- `--max-fps`: cap the processing loop
- `--tracker-max-age`: number of frames DeepSORT keeps a missing track alive
- `--tracker-n-init`: detections required before a track is confirmed
- `--track-history-length`: number of previous center points drawn for each person
- `--tracker-embedder`: DeepSORT appearance embedder backend
- `--loitering-min-duration-seconds`: trigger loitering alert after this dwell time
- `--loitering-radius-pixels`: radius used to define the same area for loitering
- `--running-speed-threshold-px-per-sec`: trigger running alert above this movement speed
- `--behavior-history-max-seconds`: maximum stored movement history per tracked person
- `--alert-sound` or `--no-alert-sound`: toggle alert audio playback
- `--alert-log-path`: destination for structured alert log lines; use `.csv` for CSV, any other suffix for JSON Lines
- `--database-enabled` or `--no-database-enabled`: toggle SQLite persistence for emitted behavior alerts
- `--database-path`: SQLite database file used for alert and behavior logs
- `--dashboard` or `--no-dashboard`: run the Flask dashboard instead of the native OpenCV loop
- `--dashboard-auth-enabled` or `--no-dashboard-auth-enabled`: toggle dashboard login protection
- `--dashboard-host`: dashboard bind host
- `--dashboard-port`: dashboard bind port
- `--dashboard-max-alerts`: number of suspicious activity entries shown in the dashboard
- `--dashboard-jpeg-quality`: JPEG quality for the live MJPEG stream
- `--dashboard-username`: username used to log into the dashboard
- `--dashboard-password`: password used to log into the dashboard; prefer env vars in production
- `--dashboard-secret-key`: secret key used to sign dashboard sessions
- `--hide-labels`: hide object class labels
- `--hide-confidence`: hide confidence scores
- `--log-level`: logging verbosity

Exit the live window with `q`, `Q`, or `Esc`.

When dashboard mode is enabled, open the configured host and port in a browser, sign in, and then view one live stream card per configured camera plus the shared suspicious activity feed.

Dashboard authentication is enabled by default. Override the default `admin` / `change-me-now` credentials before exposing the service beyond a local development machine, and set `PERSON_DETECT_DASHBOARD_SECRET_KEY` if you want session cookies to remain valid across restarts.

## Testing

The included tests use the standard library `unittest` runner.

```powershell
python -m unittest discover -s tests -v
```

## Server Deployment

### Docker

Build the image:

```powershell
docker build -t airport-ai-person-detection .
```

Run the dashboard container on a server:

```powershell
docker run --rm -p 5000:5000 --env-file .env -v ${PWD}/data:/app/data airport-ai-person-detection
```

For a Linux host with a local USB webcam, pass the device through:

```bash
docker run --rm -p 5000:5000 --env-file .env -v "$(pwd)/data:/app/data" --device /dev/video0:/dev/video0 airport-ai-person-detection
```

### Docker Compose

The included [`docker-compose.yml`](docker-compose.yml) is ready for a server-style deployment with restart policy, persistent data storage, and a dashboard healthcheck:

```powershell
docker compose up -d --build
```

Set the dashboard credentials in `.env` before starting the stack. On Linux, uncomment the `devices` section in `docker-compose.yml` if the container needs direct access to `/dev/video0`.

### Bare-Metal Server

If you want to run directly on a server without Docker, install from [`requirements.txt`](requirements.txt):

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python main.py --dashboard --dashboard-host 0.0.0.0 --no-show-window
```

On Linux/macOS, use the platform-appropriate virtualenv activation command and keep the dashboard credentials and secret key in environment variables.

## Querying Stored Logs

Use the SQLite helpers from Python when you want to inspect recent behavior history programmatically.

```python
from person_detection.database import fetch_logs_for_camera, fetch_recent_behavior_logs

recent_logs = fetch_recent_behavior_logs("alerts.db", limit=20)
cam0_logs = fetch_logs_for_camera("alerts.db", camera_id="cam-0", limit=10)
```

## Production Notes

- This project intentionally uses the official `ultralytics` package for YOLOv8, not the placeholder `yolov8` package on PyPI.
- This project uses the `deep-sort-realtime` package for DeepSORT-based multi-object tracking and persistent person IDs.
- The Flask dashboard uses MJPEG streaming and serves through Waitress when available, which keeps the browser UI simple while avoiding dependence on Flask's development server.
- Dashboard routes are protected with signed Flask sessions and a dedicated login page when dashboard auth is enabled.
- Multi-camera mode derives stable IDs such as `cam-0` and `cam-1`, and each camera keeps an independent detector, tracker, behavior analyzer, and alert dispatcher.
- SQLite logging uses a busy timeout and automatically falls back to a filesystem-compatible journal mode when WAL is unavailable, which keeps multi-camera appends reliable across environments.
- Loitering and running are inferred by a lightweight linear classifier over motion features such as dwell time, compactness, speed, path efficiency, and acceleration.
- Alert events are deduplicated per active person/behavior pair so a persistent alert does not replay every frame.
- Analysis logs include `camera_id`, `track_id`, behavior type, wall-clock timestamp, and `duration_seconds` for each newly triggered alert.
- Review the Ultralytics license before commercial deployment. As of April 5, 2026, PyPI lists `ultralytics` under AGPLv3+ with an enterprise license option.
- `opencv-python` is the desktop package used here because it includes GUI support for webcam preview windows.

## Reference Docs

- Ultralytics GitHub quickstart: https://github.com/ultralytics/ultralytics
- Ultralytics PyPI package: https://pypi.org/project/ultralytics/
- Ultralytics results API: https://docs.ultralytics.com/reference/engine/results/
- DeepSORT realtime tracker GitHub: https://github.com/levan92/deep_sort_realtime
- DeepSORT realtime PyPI package: https://pypi.org/project/deep-sort-realtime/
- OpenCV `VideoCapture` reference: https://docs.opencv.org/4.x/d8/dfe/classcv_1_1VideoCapture.html
- OpenCV Python package: https://pypi.org/project/opencv-python/
