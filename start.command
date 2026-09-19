#!/bin/bash
# Double-click: starts the listing server locally and opens the browser (theme picker visible on localhost).
cd "$(dirname "$0")"
( sleep 1.2; open "http://localhost:4700" ) &
node server.js
