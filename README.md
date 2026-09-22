# Honda listing site

Mobile-first product page for the 2018 Accord Hybrid. Same stack/pattern as `~/vibe-mart-live`:
Node built-ins only, cookie password gate, pm2 on the always-on Mac, Cloudflare Tunnel to `honda.autopute.ai`,
bare-repo backup on the NAS (`/Volumes/Repos/honda-listing.git`).

## Files
- `data/listing.json` — single source of truth (price, mileage, specs, service, disclosures, contact). Edit this, never the HTML.
- `public/index.html` — renders listing.json. Three visual themes: `clean`, `dark`, `editorial` (`?theme=dark`, picker shown on localhost).
- `public/photos/` — drop JPGs here; first file (alphabetical) is the hero. Name them `01_front.jpg`, `02_side.jpg`, … `90_scratch_rear.jpg`.
- `public/login.html` — password gate page.
- `server.js` — serves everything; `/api/listing`, `/api/photos`, `/api/login`.

## Local
`./start.command` (or `node server.js`) → http://localhost:4700 — no password locally (AUTH_PASSWORD empty).

## Public — option A (recommended): GitHub Pages, static, no password
Buyers coming from Facebook Marketplace won't type a password, so the public listing is static and open.
1. `./deploy-pages.sh init` once (creates public repo turnert1337/honda-listing, enables Pages from main:/docs).
2. Every content change: edit `data/listing.json` (or drop photos in `public/photos/`), then `./deploy-pages.sh`.
3. Live at https://turnert1337.github.io/honda-listing/ (custom domain optional: add a CNAME `honda.autopute.ai` in Cloudflare → `turnert1337.github.io`, and a `docs/CNAME` file).
`build.py` inlines listing.json + photo list into `docs/index.html`; `docs/` is the deployable, never hand-edit it.

## Public — option B: pm2 + Cloudflare Tunnel with password gate (vibe-mart pattern)
1. `cp .env.example .env`, set `AUTH_PASSWORD=<pick one>` (vibe-mart uses `rollback`; pick something different for buyers).
2. `./deploy.sh` → copies HEAD to `~/honda-listing-live`, starts `pm2 honda-listing`.
3. `./deploy/go-live.command` once → tunnel + DNS → https://honda.autopute.ai
4. Share the URL + password. To mark sold: set `"status": "sold"` in listing.json, `./deploy.sh`.

## NAS backup
On the Mac with the NAS mounted: `git init --bare /Volumes/Repos/honda-listing.git && git remote add nas /Volumes/Repos/honda-listing.git`.
