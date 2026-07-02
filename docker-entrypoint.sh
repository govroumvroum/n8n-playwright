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

# Patch playwright-core to hide the CDP Runtime.enable leak that Cloudflare's jsd
# bot-detection fingerprints (blocks the whole /xhr/ path otherwise). Runs once per volume.
PW_CORE=$(find "$N8N_NODES_DIR/node_modules" -maxdepth 4 -type d -name playwright-core 2>/dev/null | head -1)
if [ -n "${PW_CORE:-}" ] && [ ! -f "$PW_CORE/.rebrowser-patched" ]; then
  PATCH_ROOT=$(dirname "$(dirname "$PW_CORE")")
  echo "Patching playwright-core (rebrowser) in $PATCH_ROOT"
  if (cd "$PATCH_ROOT" && npx --yes rebrowser-patches@latest patch --packageName playwright-core); then
    touch "$PW_CORE/.rebrowser-patched"
    echo "rebrowser patch applied"
  else
    echo "rebrowser patch failed (continuing without it)"
  fi
fi

exec "$@"
