#!/usr/bin/env python3
"""Build a static copy of the listing into docs/ (GitHub Pages) — no server, no password.
Inlines data/listing.json and the photo list into index.html; copies photos."""
import json, os, re, shutil
root = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(root, 'public/index.html')).read()
L = json.load(open(os.path.join(root, 'data/listing.json')))
photos = sorted(f for f in os.listdir(os.path.join(root, 'public/photos')) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')))
out = src.replace(
    "const [L, photos] = await Promise.all([fetch('/api/listing').then((r) => r.json()), fetch('/api/photos').then((r) => r.json())]);",
    "const L = " + json.dumps(L) + ";\n  const photos = " + json.dumps(photos) + ";")
out = out.replace('src="/photos/', 'src="photos/')
out = out.replace("if (location.hostname === 'localhost' || q.get('pick'))", "if (q.get('pick'))")
dist = os.path.join(root, 'docs')
os.makedirs(os.path.join(dist, 'photos'), exist_ok=True)
for stale in os.listdir(os.path.join(dist, 'photos')):
    if stale not in photos:
        try: os.remove(os.path.join(dist, 'photos', stale))
        except OSError: print('could not remove stale', stale)
open(os.path.join(dist, 'index.html'), 'w').write(out)
open(os.path.join(dist, '.nojekyll'), 'w').close()
for f in photos:
    shutil.copy(os.path.join(root, 'public/photos', f), os.path.join(dist, 'photos', f))
print(f'built docs/ with {len(photos)} photos, {len(out)//1024} KB html')
