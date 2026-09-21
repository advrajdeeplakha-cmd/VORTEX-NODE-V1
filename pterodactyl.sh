#!/usr/bin/env bash
set -u
if [ "$(id -u)" -ne 0 ]; then echo "Run this module as root."; exit 1; fi
. /etc/os-release
case "$ID:$VERSION_ID" in
  ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:10|debian:11|debian:12|debian:13) ;;
  *) echo "Unsupported/unverified OS: $PRETTY_NAME"; exit 1;;
esac
echo "Detected: $PRETTY_NAME"
read -r -p "Panel domain (e.g. panel.example.com): " PANEL_DOMAIN
read -r -p "Let's Encrypt email: " LE_EMAIL
read -r -p "Admin email: " ADMIN_EMAIL
read -r -p "Admin username: " ADMIN_USER
read -r -p "Admin first name: " ADMIN_FIRST
read -r -p "Admin last name: " ADMIN_LAST
read -r -s -p "Admin password: " ADMIN_PASS; echo
echo
echo "Configuration collected for $PANEL_DOMAIN."
echo "The official Pterodactyl installer should be reviewed before execution."
echo "This module does not silently download/execute an unverified remote script."
echo "Official installer: https://github.com/pterodactyl-installer/pterodactyl-installer"
