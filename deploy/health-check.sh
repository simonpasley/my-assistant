#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Health Check & Maintenance Script
# Run periodically to verify everything is working

OPENCLAW_HOME="$HOME/.openclaw"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== OpenClaw Health Check ==="
echo ""

# 1. Service status
echo "--- Service Status ---"
if systemctl --user is-active openclaw-gateway.service &>/dev/null; then
  echo "Gateway service: RUNNING"
else
  echo "Gateway service: NOT RUNNING"
  echo "  Start with: systemctl --user start openclaw-gateway.service"
fi

# 2. Port check
echo ""
echo "--- Port Check ---"
if ss -ltnp 2>/dev/null | grep -q 18789; then
  echo "Port 18789: LISTENING"
else
  echo "Port 18789: NOT LISTENING"
fi

# 3. Config permissions
echo ""
echo "--- Config Permissions ---"
if [ -d "$OPENCLAW_HOME" ]; then
  PERMS=$(stat -c %a "$OPENCLAW_HOME" 2>/dev/null || stat -f %Lp "$OPENCLAW_HOME" 2>/dev/null)
  echo "~/.openclaw/: $PERMS $([ "$PERMS" = "700" ] && echo "(OK)" || echo "(SHOULD BE 700)")"
fi
if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
  PERMS=$(stat -c %a "$OPENCLAW_HOME/openclaw.json" 2>/dev/null || stat -f %Lp "$OPENCLAW_HOME/openclaw.json" 2>/dev/null)
  echo "openclaw.json: $PERMS $([ "$PERMS" = "600" ] && echo "(OK)" || echo "(SHOULD BE 600)")"
fi
if [ -f "$OPENCLAW_HOME/.env" ]; then
  PERMS=$(stat -c %a "$OPENCLAW_HOME/.env" 2>/dev/null || stat -f %Lp "$OPENCLAW_HOME/.env" 2>/dev/null)
  echo ".env: $PERMS $([ "$PERMS" = "600" ] && echo "(OK)" || echo "(SHOULD BE 600)")"
fi

# 4. Firewall
echo ""
echo "--- Firewall ---"
if command -v ufw &>/dev/null; then
  sudo ufw status 2>/dev/null | head -5
else
  echo "ufw not installed"
fi

# 5. Signal-cli
echo ""
echo "--- Signal CLI ---"
if command -v signal-cli &>/dev/null; then
  echo "signal-cli: $(signal-cli --version 2>/dev/null || echo 'installed')"
else
  echo "signal-cli: NOT FOUND"
fi

# 6. Disk space
echo ""
echo "--- Disk Space ---"
df -h / | tail -1

# 7. Memory
echo ""
echo "--- Memory ---"
free -h 2>/dev/null | head -2 || vm_stat 2>/dev/null | head -5

echo ""
echo "=== Health check complete ==="
