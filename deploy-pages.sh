#!/bin/sh
# Publish the static listing to GitHub Pages. Run on the Mac (needs gh CLI logged in, or a git remote named origin).
#   1st time:  ./deploy-pages.sh init     -> creates public repo turnert1337/honda-listing, pushes, enables Pages from main:/docs
#   updates:   ./deploy-pages.sh          -> rebuild docs/, commit, push
set -e
cd "$(dirname "$0")"
REPO="turnert1337/honda-listing"
python3 build.py
git add -A
git commit -qm "Publish listing $(date +%Y-%m-%d\ %H:%M)" || true
if [ "$1" = "init" ]; then
  gh repo create "$REPO" --public --source=. --remote=origin --push
  gh api -X POST "repos/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/docs' >/dev/null 2>&1 || \
  gh api -X PUT "repos/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/docs' >/dev/null
  echo "Pages enabled. URL (allow ~1 min): https://turnert1337.github.io/honda-listing/"
else
  git push origin HEAD:main
  echo "pushed — live in ~1 min at https://turnert1337.github.io/honda-listing/"
fi
