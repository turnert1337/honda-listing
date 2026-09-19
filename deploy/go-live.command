#!/bin/bash
# Honda listing — bring the site online via Cloudflare Tunnel (copied from vibe-mart/deploy/go-live.command).
# Run ONCE on the always-on Mac. Prereq: pm2 process "honda-listing" running (./deploy.sh does that) and AUTH_PASSWORD set in ~/honda-listing-live/.env
set -e
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
SUBDOMAIN="honda"
DOMAIN="autopute.ai"
HOSTNAME="$SUBDOMAIN.$DOMAIN"
TUNNEL="honda-tunnel"
LOCAL_PORT=4700

echo "→ go-live: https://$HOSTNAME"
command -v cloudflared >/dev/null || { echo "→ installing cloudflared…"; brew install cloudflared; }
[ -f "$HOME/.cloudflared/cert.pem" ] || { echo "→ browser will open; authorize the $DOMAIN zone"; cloudflared tunnel login; }
cloudflared tunnel list | grep -q " $TUNNEL " || cloudflared tunnel create "$TUNNEL"
TUNNEL_ID=$(cloudflared tunnel list | awk -v t="$TUNNEL" '$2==t{print $1}')
echo "→ tunnel id: $TUNNEL_ID"
# NOTE: vibe-mart's config.yml is a single-tunnel file. To avoid clobbering it, this tunnel uses its own config.
CFGF="$HOME/.cloudflared/honda-config.yml"
cat > "$CFGF" <<CFG
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json
ingress:
  - hostname: $HOSTNAME
    service: http://localhost:$LOCAL_PORT
  - service: http_status:404
CFG
cloudflared tunnel route dns "$TUNNEL" "$HOSTNAME" || true
pm2 delete honda-tunnel 2>/dev/null || true
pm2 start "cloudflared --config $CFGF tunnel run $TUNNEL" --name honda-tunnel
pm2 save
echo "✅ Live at https://$HOSTNAME"
