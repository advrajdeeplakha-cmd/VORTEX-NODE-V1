#!/usr/bin/env bash
set -u
echo "Node / Panel diagnostics"
echo "Docker:"; docker ps 2>/dev/null || true
echo "Wings:"; systemctl status wings --no-pager 2>/dev/null || true
echo "Ports:"; ss -lntp 2>/dev/null | head -30
