#!/usr/bin/env bash
set -euo pipefail

echo "=== Aruvi — Cloudflare Tunnel Setup ==="
echo ""

# ── 1. Check cloudflared ──────────────────────────────────────────
if ! command -v cloudflared &>/dev/null; then
    echo "[1] Downloading cloudflared..."
    curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
fi
echo "  cloudflared: $(cloudflared --version)"

# ── 2. Authenticate ────────────────────────────────────────────────
echo ""
echo "[2] Opening Cloudflare login..."
echo "    Complete the browser login, then return here."
cloudflared tunnel login

# ── 3. Create tunnel ──────────────────────────────────────────────
echo ""
read -rp "  Enter a name for your tunnel (e.g. aruvi): " TUNNEL_NAME
TUNNEL_ID=$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1 | grep -oP '(?<=id ).+')
echo "  Tunnel created: $TUNNEL_ID"

# ── 4. DNS route ──────────────────────────────────────────────────
echo ""
read -rp "  Enter your domain (e.g. movie.example.com): " DOMAIN
cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN"

# ── 5. Write config ───────────────────────────────────────────────
mkdir -p ~/.cloudflared
CONFIG="$HOME/.cloudflared/config.yml"
cat > "$CONFIG" <<EOF
tunnel: $TUNNEL_NAME
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:7680
  - service: http_status:404
EOF
echo ""
echo "  Config written: $CONFIG"

# ── 6. Install as service ────────────────────────────────────────
echo ""
echo "[6] Installing cloudflared as a system service..."
sudo cloudflared service install

echo ""
echo "=== Done! ==="
echo "  Start the tunnel:   sudo systemctl start cloudflared"
echo "  Check status:       sudo systemctl status cloudflared"
echo "  Backend runs on:    http://localhost:7680"
echo "  Public URL:         https://$DOMAIN"
echo ""
echo "  Make sure your backend is running before starting the tunnel."
