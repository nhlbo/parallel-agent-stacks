#!/usr/bin/env bash
# One-time setup for a devbox VM (Ubuntu).
# From your laptop:  scp scripts/devbox-setup.sh devbox: && ssh -t devbox 'bash devbox-setup.sh'
set -euo pipefail

# make, for running the Makefile targets directly on the devbox
if ! command -v make >/dev/null; then
  sudo apt-get update -qq && sudo apt-get install -y -qq make
fi

# Docker Engine + Compose plugin
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
fi

# Tailscale (the VM itself joins the tailnet so you can ssh/mutagen to it from anywhere)
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
  sudo tailscale up
fi

mkdir -p ~/code
echo "Devbox ready. Log out and back in for the docker group to apply."
