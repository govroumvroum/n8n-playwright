#!/bin/sh
set -eu

N8N_NODES_DIR="/home/node/.n8n/nodes"
PLAYWRIGHT_PACKAGE="n8n-nodes-playwright"
PLAYWRIGHT_TGZ="/opt/n8n/community/${PLAYWRIGHT_PACKAGE}.tgz"

mkdir -p "$N8N_NODES_DIR"

# Start a virtual display so real Chrome can run HEADED (headless:false).
# Headed Chrome passes Cloudflare's stricter challenges that headless can't solve.
if command -v Xvfb >/dev/null 2>&1; then
  Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp >/dev/null 2>&1 &
  export DISPLAY=:99
fi

if [ ! -d "$N8N_NODES_DIR/node_modules/$PLAYWRIGHT_PACKAGE" ]; then
  echo "Installing $PLAYWRIGHT_PACKAGE into $N8N_NODES_DIR"
  npm install --prefix "$N8N_NODES_DIR" --omit=dev --ignore-scripts "$PLAYWRIGHT_TGZ"
fi

exec "$@"
