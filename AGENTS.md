# Aruvi Backend — Current Deploy

## Stack
- **FastAPI** on port **7680** — Aruvi backend (streaming, auth, gdrive, legal pages)
- **opencode** on port **24696** — AI coding assistant web UI
- **cloudflared** tunnel — `movie.aaruvi.space` → `localhost:7680`, `opencode.aaruvi.space` → `localhost:24696`
- **Python 3.11.15** — portable at `/home/container/python3.11/python/bin/python3.11`
- **uvloop 0.21.0** (pinned) — only stable on aarch64. 0.22.x segfaults on ARM64 Python 3.12/3.13.

## Startup
- `startup.js` at `/home/container/startup.js` — spawns cloudflared, opencode, telegram bot. Managed by HidenCloud platform.
- Aruvi backend started manually via `setsid` from `/home/container/aruvi-app/repo/backend/`
- No auto-restart daemon for Aruvi backend — must restart manually after code changes.
- Container restarts daily at 3:30 AM IST with fresh `git clone --depth=1` from `origin/main`.

## Repo
- Lives at `/home/container/aruvi-app/repo/`
- Cloned from `github.com/Thirupathi-pirate/Aruvi-backend.git`
- On container restart: fresh clone; uncommitted changes are LOST.
- No Git credentials stored — cannot `git push` from this machine.

## Domain routing
| Domain | Target | Service |
|--------|--------|---------|
| `movie.aaruvi.space` | `localhost:7680` | Aruvi backend |
| `opencode.aaruvi.space` | `localhost:24696` | opencode Web UI |

## Key files
- `backend/app/main.py` — FastAPI app, SPA catch-all for any non-API route
- `backend/app/routers/legal.py` — Privacy & Terms pages (Python-rendered HTML; requires server restart after edit)
- `backend/app/static/landing.html` — Landing page at `/` (static file; updates immediately)
- `backend/app/static/index.html` — React SPA shell at `/login` (pre-built TelePlay frontend; DO NOT TOUCH React code)
- `backend/app/static/assets/` — Minified JS/CSS for the SPA

## Color theming (landing + legal)
All text uses solid hex colors (no `rgba()` opacity) to avoid subpixel anti-aliasing artifacts:
- **Primary text**: `#E6E8EB`
- **Secondary text**: `#9CA3AF`
- **Muted text**: `#6B7280`
- **Background**: `#0a0a0f`
- **Accent**: `#6366f1` / `#a855f7` / `#ec4899` (gradient)
- **Links**: `#a5b4fc`

## Notebook-style workstate (current session)

### Work State
- Landing page (`/`) redesigned with Inter font, "AR" gradient logo, inline SVG icons, dark `#0a0a0f` bg
- Privacy & Terms (`/privacy`, `/terms`) restyled to match landing theme
- All text colors switched from `rgba()` to solid hex (`#E6E8EB`/`#9CA3AF`/`#6B7280`) — fixes uneven character brightness
- Legal pages require server restart after editing (Python-rendered)
- Landing page is static HTML — updates take effect immediately
- SPA login page at `/login` untouched (pre-built React app, not themed)

### Memory leak test (Jul 29, 2026)
Streamed 58MB video (msg_id=197, channel=-1003950847652) via diagnostic endpoint + 5 concurrent range requests + second file. Monitored RAM for 12 minutes.

| Metric | Value |
|--------|-------|
| Baseline Python RSS | 219 MB |
| Peak during stream | 243 MB (+24 MB) |
| Post-TTL (600s) | 156 MB (cache evicted) |
| Cgroup baseline | ~2,540 MB |
| Cgroup peak | ~2,596 MB |
| Cgroup max | 3,379 MB |
| Free cgroup | ~783 MB |

**Verdict: No memory leak.** RSS returned to and stabilized below baseline after ChunkCache TTL expiry. CacheManager's `_evict_one()` + `_periodic_housekeeping()` work correctly.

**Bandwidth:**
- Localhost: 321 Mbps (40 MB/s)
- CF Tunnel: 33 Mbps (4 MB/s)
- TTFB local: 239ms, tunnel: 697ms

## Known issues
- No git push capability (no GitHub credentials on this machine)
- Commits are local only; changes will be lost on container restart unless pushed externally
- Server must be manually restarted after changing any `.py` file
