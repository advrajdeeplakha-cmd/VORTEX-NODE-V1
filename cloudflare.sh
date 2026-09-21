#!/usr/bin/env bash
set -u
echo "Cloudflare Tunnel setup"
if command -v cloudflared >/dev/null 2>&1; then cloudflared --version; else echo "cloudflared is not installed."; fi
echo "Use a runtime Cloudflare token; do not hard-code credentials into this repository."
