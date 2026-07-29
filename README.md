# Aruvi — Telegram Media Streaming Platform

Stream your Telegram media files (videos, audio) to any browser or Android TV using multi-bot parallel streaming with intelligent caching.

## Repository Structure

```
aruvi-combined/
├── backend/             # FastAPI backend + SPA frontend
│   ├── app/             # Python backend code
│   │   ├── main.py      # FastAPI application entrypoint
│   │   ├── routers/     # API routes (files, auth, streaming, download, legal)
│   │   ├── static/      # Landing page (landing.html), SPA (index.html + JS bundle)
│   │   └── models/      # SQLAlchemy models
│   ├── requirements.txt
│   └── run.py           # Startup script (uvicorn + uvloop)
├── android/             # Android app source (Gradle project)
│   ├── app/             # Kotlin source
│   ├── build.gradle.kts
│   └── *.apk            # Pre-built APKs
├── Dockerfile           # Production container image
├── setup-cloudflare.sh  # Cloudflare tunnel setup script
└── README.md
```

## Quick Start

### 1. Backend (Docker)

```bash
docker build -t aruvi-backend .
docker run -p 7680:7680 \
  -e TELEGRAM_API_ID=... \
  -e TELEGRAM_API_HASH=... \
  -e TELEGRAM_BOT_TOKEN=... \
  -e TELEGRAM_STORAGE_CHANNEL_ID=... \
  -e DATABASE_URL=sqlite+aiosqlite:///data/db.sqlite \
  aruvi-backend
```

Environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `TELEGRAM_API_ID` | yes | Telegram API ID |
| `TELEGRAM_API_HASH` | yes | Telegram API hash |
| `TELEGRAM_BOT_TOKEN` | yes | Main bot token |
| `TELEGRAM_STORAGE_CHANNEL_ID` | yes | Channel ID for media storage |
| `TELEGRAM_HELPER_BOT_TOKENS` | no | Comma-separated helper bot tokens for parallel fetching |
| `DATABASE_URL` | no | Default: `sqlite+aiosqlite:///data/db.sqlite` |
| `TUNNEL_TOKEN` | no | Cloudflare tunnel token |

### 2. Android App

Open `android/` in Android Studio, or install a pre-built APK:
- `android/Aruvi-v2.0.0-mobile.apk` — Phone/tablet
- `android/Aruvi-v2.0.0-tv.apk` — Android TV

### 3. Cloudflare Tunnel (optional)

```bash
chmod +x setup-cloudflare.sh
./setup-cloudflare.sh
```

This script installs `cloudflared`, authenticates, creates a tunnel, routes a DNS record, and installs as a systemd service.

## Architecture

```
Browser/TV App → Cloudflare Tunnel → FastAPI (uvicorn) → PyroTGFork clients → Telegram MTProto
                                    ↕
                         Sliding Window Cache (700MB per-video RAM)
                                    ↕
                          ChunkCache (700MB max, 600s TTL)
```

### Key Components

| Component | Description |
|-----------|-------------|
| **FastAPI backend** | REST API for auth, file listing, streaming, download |
| **11 Telegram bots** | 1 main + 10 helpers for parallel chunk fetching |
| **ChunkCache** | Per-video 700MB RAM cache, BATCH_SIZE=10, CHUNK_SIZE=1MB |
| **Landing page** | Dark-themed `/` with Inter font, gradient AR logo |
| **SPA** | React player at `/login` (pre-built, served as static files) |
| **Download page** | `/download` — lists Android APK files |

## Deployments

### HidenCloud (current)

3.3GB ARM64 container, daily restart at 3:30 AM IST.

| Domain | Service |
|--------|---------|
| `movie.aaruvi.space` | Aruvi web player (via Cloudflare tunnel) |
| `opencode.aaruvi.space` | AI coding assistant (debug) |

### Persistence

Code lives at `github.com/Thirupathi-pirate/Aruvi-combined`. On container restart, the platform does a fresh `git clone` — changes must be pushed to the repo.

## Memory

- Baseline Python RSS: ~160-220MB
- ChunkCache: 700MB max per video, Semaphore(700)
- jemalloc via `LD_PRELOAD` with background threads
- uvloop 0.21.0 pinned (0.22.x segfaults on aarch64)

## License

MIT
