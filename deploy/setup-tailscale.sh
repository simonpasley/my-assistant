#!/usr/bin/env bash
set -euo pipefail

# Tailscale Setup for OpenClaw Pi
# Provides secure remote access to the gateway over your private tailnet

echo "=== Tailscale Setup ==="

# Install Tailscale if not present
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "Tailscale already installed: $(tailscale version 2>/dev/null | head -1)"
fi

# Check if Tailscale is running
if ! tailscale status &>/dev/null; then
  echo ""
  echo "Starting Tailscale..."
  sudo systemctl enable --now tailscaled
  echo ""
  echo "Authenticate with your Tailscale account:"
  echo "  sudo tailscale up"
  echo ""
  echo "Then re-run this script."
  exit 0
fi

echo ""
echo "Tailscale is connected."
echo "Your Pi's tailnet IP: $(tailscale ip -4 2>/dev/null || echo 'unknown')"
echo ""
echo "OpenClaw gateway config already has tailscale.mode = 'serve'."
echo "The gateway will be accessible over your tailnet at port 18789."
echo ""
echo "From any device on your tailnet:"
echo "  https://$(tailscale ip -4 2>/dev/null || echo 'PI_TAILNET_IP'):18789"
echo ""
echo "Or use SSH tunnel (no Tailscale on client needed):"
echo "  ssh -L 18789:localhost:18789 $(whoami)@$(hostname)"
echo "  Then open: http://localhost:18789"
echo ""
echo "=== Tailscale setup complete ==="
