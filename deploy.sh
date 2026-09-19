#!/bin/sh
# Same shape as vibe-mart/deploy.sh: archive HEAD into the live dir, restart pm2, NAS push as background backup.
set -e
cd "$(dirname "$0")"
LIVE="$HOME/honda-listing-live"
mkdir -p "$LIVE"
( git push nas main >/dev/null 2>&1 && echo "[deploy] nas backup pushed" || echo "[deploy] nas push skipped/failed" ) &
git archive HEAD | tar -x -C "$LIVE"
[ -f "$LIVE/.env" ] || cp .env "$LIVE/.env" 2>/dev/null || true
# photos are gitignored? no — they're committed. Copy anyway in case of local-only additions:
cp -n public/photos/* "$LIVE/public/photos/" 2>/dev/null || true
pm2 describe honda-listing >/dev/null 2>&1 && pm2 restart honda-listing --silent || (cd "$LIVE" && pm2 start server.js --name honda-listing && pm2 save)
echo "[deploy] $(git rev-parse --short HEAD) -> $LIVE (pm2 honda-listing)"
