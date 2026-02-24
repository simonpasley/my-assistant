#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Pi Setup Script
# Run this on your Raspberry Pi (4B 4GB+ or Pi 5 8GB)
# Requires: Raspberry Pi OS Lite 64-bit (ARM64)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_HOME="$HOME/.openclaw"

echo "=== OpenClaw Pi Setup ==="
echo "Repo: $REPO_DIR"
echo "Config dir: $OPENCLAW_HOME"
echo ""

# --- Phase 1: System Dependencies ---
echo "--- Installing system dependencies ---"

# Node 22+
if ! command -v node &>/dev/null || [[ "$(node -v | sed 's/v//' | cut -d. -f1)" -lt 22 ]]; then
  echo "Installing Node.js 22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
  sudo apt install -y nodejs
else
  echo "Node.js $(node -v) already installed"
fi

# pnpm
if ! command -v pnpm &>/dev/null; then
  echo "Installing pnpm..."
  sudo npm install -g pnpm@latest
else
  echo "pnpm $(pnpm -v) already installed"
fi

# Git (should be pre-installed on Pi OS)
if ! command -v git &>/dev/null; then
  sudo apt install -y git
fi

# signal-cli native ARM64
if ! command -v signal-cli &>/dev/null; then
  echo ""
  echo "--- signal-cli not found ---"
  echo "Download the native ARM64 build from:"
  echo "  https://github.com/AsamK/signal-cli/releases"
  echo ""
  echo "Example:"
  echo "  wget https://github.com/AsamK/signal-cli/releases/download/v0.13.12/signal-cli-0.13.12-Linux-native.tar.gz"
  echo "  tar xf signal-cli-*-Linux-native.tar.gz"
  echo "  sudo mv signal-cli-*-Linux-native/bin/signal-cli /usr/local/bin/"
  echo "  sudo chmod +x /usr/local/bin/signal-cli"
  echo ""
  echo "Then re-run this script."
  exit 1
fi

echo "signal-cli found: $(which signal-cli)"

# --- Phase 2: OpenClaw Config Directory ---
echo ""
echo "--- Setting up config directory ---"

mkdir -p "$OPENCLAW_HOME"

# Copy config if not already present
if [ ! -f "$OPENCLAW_HOME/openclaw.json" ]; then
  cp "$SCRIPT_DIR/openclaw.json" "$OPENCLAW_HOME/openclaw.json"
  echo "Copied openclaw.json to $OPENCLAW_HOME/"
  echo ""
  echo "IMPORTANT: Edit $OPENCLAW_HOME/openclaw.json and replace:"
  echo "  +YOUR_PHONE_NUMBER  -> your actual phone number (E.164 format)"
  echo "  YOUR_VOICE_ID       -> your ElevenLabs voice ID"
else
  echo "openclaw.json already exists, skipping copy"
fi

# Copy .env template if not already present
if [ ! -f "$OPENCLAW_HOME/.env" ]; then
  cp "$SCRIPT_DIR/.env.template" "$OPENCLAW_HOME/.env"
  echo "Copied .env template to $OPENCLAW_HOME/.env"
  echo ""
  echo "IMPORTANT: Edit $OPENCLAW_HOME/.env and fill in your API keys"
else
  echo ".env already exists, skipping copy"
fi

# Generate gateway token if placeholder still present
if grep -q "GENERATE_ME" "$OPENCLAW_HOME/.env" 2>/dev/null; then
  TOKEN=$(openssl rand -hex 32)
  sed -i "s/GENERATE_ME_WITH_openssl_rand_hex_32/$TOKEN/" "$OPENCLAW_HOME/.env"
  echo "Generated gateway auth token"
fi

# --- Phase 3: Filesystem Hardening ---
echo ""
echo "--- Applying filesystem permissions ---"

chmod 700 "$OPENCLAW_HOME"
chmod 600 "$OPENCLAW_HOME/openclaw.json"
chmod 600 "$OPENCLAW_HOME/.env"

echo "Permissions set: 700 on dir, 600 on config files"

# --- Phase 4: Firewall ---
echo ""
echo "--- Configuring firewall ---"

if command -v ufw &>/dev/null; then
  sudo ufw default deny incoming 2>/dev/null || true
  sudo ufw allow ssh 2>/dev/null || true
  echo "y" | sudo ufw enable 2>/dev/null || true
  echo "Firewall configured: deny incoming, allow SSH"
  echo "Gateway port 18789 is loopback-only (no rule needed)"
else
  echo "ufw not found. Install with: sudo apt install ufw"
fi

# --- Phase 5: Build ---
echo ""
echo "--- Building OpenClaw ---"

cd "$REPO_DIR"
pnpm install
pnpm build

echo ""
echo "=== Build complete ==="

# --- Phase 6: Signal Registration ---
echo ""
echo "--- Signal Setup ---"
echo "Register or link your Signal account:"
echo ""
echo "  Option A (link to existing account):"
echo "    signal-cli -a $SIGNAL_ACCOUNT link"
echo ""
echo "  Option B (register new number):"
echo "    signal-cli -a +YOUR_NUMBER register"
echo "    signal-cli -a +YOUR_NUMBER verify CODE"
echo ""

# --- Phase 7: Start ---
echo "--- Starting OpenClaw ---"
echo ""
echo "To start manually:"
echo "  cd $REPO_DIR && pnpm openclaw gateway run"
echo ""
echo "To install as a systemd service:"
echo "  pnpm openclaw gateway install"
echo "  systemctl --user enable --now openclaw-gateway.service"
echo "  sudo loginctl enable-linger \$USER"
echo ""
echo "=== Setup complete ==="
