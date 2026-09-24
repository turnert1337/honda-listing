#!/bin/bash
# Double-click me: publishes the listing to GitHub Pages (first run creates the repo).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")"
if git remote get-url origin >/dev/null 2>&1; then ./deploy-pages.sh; else ./deploy-pages.sh init; fi
echo; echo "Done. Press any key to close."; read -n 1
