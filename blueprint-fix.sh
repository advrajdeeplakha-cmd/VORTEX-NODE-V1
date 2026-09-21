#!/usr/bin/env bash
set -Eeuo pipefail

# ================================================================
#   F R O Z E N P L A Y Z Z
#   B L U E P R I N T   F I X E R
#   Pterodactyl Panel - Nginx / PHP-FPM / Laravel Blueprint Fixer
# ================================================================

BLUE="\033[1;34m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

banner() {
  clear || true
  printf "${BLUE}"
  cat <<'EOF'
███████╗██████╗  ██████╗ ███████╗███████╗███╗   ██╗
██╔════╝██╔══██╗██╔═══██╗╚══███╔╝██╔════╝████╗  ██║
█████╗  ██████╔╝██║   ██║  ███╔╝ █████╗  ██╔██╗ ██║
██╔══╝  ██╔══██╗██║   ██║ ███╔╝  ██╔══╝  ██║╚██╗██║
██║     ██║  ██║╚██████╔╝███████╗███████╗██║ ╚████║
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═══╝

██████╗ ██╗      █████╗ ██╗   ██╗██████╗ ██╗███╗   ██╗
██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝██╔══██╗██║████╗  ██║
██████╔╝██║     ███████║ ╚████╔╝ ██████╔╝██║██╔██╗ ██║
██╔══██╗██║     ██╔══██║  ╚██╔╝  ██╔═══╝ ██║██║╚██╗██║
██████╔╝███████╗██║  ██║   ██║   ██║     ██║██║ ╚████║
╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═══╝

                 B L U E P R I N T   F I X E R
EOF
  printf "${RESET}\n"
}

log()  { printf "${CYAN}[FROZEN]${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}[ OK ]${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${RESET} %s\n" "$*"; }
fail() { printf "${RED}[FAIL]${RESET} %s\n" "$*"; }

trap 'fail "Command failed at line $LINENO. Check the output above."; exit 1' ERR

banner

if [[ $EUID -ne 0 ]]; then
  fail "Run this script as root: sudo bash frozenplayzz-blueprint-fixer.sh"
  exit 1
fi

PANEL_DIR="/var/www/pterodactyl"

if [[ ! -d "$PANEL_DIR" ]]; then
  fail "$PANEL_DIR was not found. Is Pterodactyl installed there?"
  exit 1
fi

cd "$PANEL_DIR"

log "Setting Pterodactyl ownership..."
chown -R www-data:www-data "$PANEL_DIR"
ok "Ownership fixed."

log "Checking PHP-FPM..."
PHP_FPM_SERVICE=""
for svc in php8.4-fpm php8.3-fpm php8.2-fpm php8.1-fpm; do
  if systemctl list-unit-files --type=service | grep -q "^${svc}"; then
    PHP_FPM_SERVICE="$svc"
    break
  fi
done

if [[ -n "$PHP_FPM_SERVICE" ]]; then
  systemctl restart "$PHP_FPM_SERVICE"
  ok "Restarted $PHP_FPM_SERVICE."
else
  warn "No supported PHP-FPM service (8.1-8.4) was detected."
fi

log "Restarting nginx..."
systemctl restart nginx
ok "Nginx restarted."

log "Bringing Laravel maintenance state back to normal..."
php artisan up || true

log "Clearing Laravel caches..."
php artisan optimize:clear

log "Rebuilding Laravel configuration..."
php artisan config:cache

log "Rebuilding Laravel route cache..."
php artisan route:cache || warn "Route cache could not be rebuilt; continuing."

log "Rebuilding Laravel view cache..."
php artisan view:cache || warn "View cache could not be rebuilt; continuing."

# Migrations are intentionally opt-in because --force can change the database.
if [[ "${RUN_MIGRATIONS:-0}" == "1" ]]; then
  warn "RUN_MIGRATIONS=1 detected; running forced migrations."
  php artisan migrate --force
  ok "Database migrations completed."
else
  warn "Database migrations were NOT run automatically."
  warn "If the blueprint specifically requires them, run:"
  warn "  cd $PANEL_DIR && php artisan migrate --force"
fi

log "Final service restart..."
if [[ -n "$PHP_FPM_SERVICE" ]]; then
  systemctl restart "$PHP_FPM_SERVICE"
fi
systemctl restart nginx

printf "\n"
printf "${GREEN}============================================================${RESET}\n"
printf "${GREEN}        FROZENPLAYZZ BLUEPRINT FIXER COMPLETE${RESET}\n"
printf "${GREEN}============================================================${RESET}\n"
printf "Panel directory : %s\n" "$PANEL_DIR"
printf "PHP-FPM service : %s\n" "${PHP_FPM_SERVICE:-not detected}"
printf "Nginx           : restarted\n"
printf "Laravel cache   : cleared + rebuilt\n"
printf "\n"
printf "If the blueprint requires DB migrations:\n"
printf "  RUN_MIGRATIONS=1 bash %s\n" "$(basename "$0")"
printf "\n"
