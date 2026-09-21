#!/usr/bin/env bash
set -u
if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed:"
  docker --version
else
  echo "Docker is not installed."
  echo "Use Docker's official Ubuntu/Debian installation instructions for your OS."
fi
