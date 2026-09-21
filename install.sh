#!/usr/bin/env bash
set -e
BASE="${HOME}/.vortex-node-runtime"
rm -rf "$BASE"
mkdir -p "$BASE/modules"
cleanup(){ rm -rf "$BASE"; }
trap cleanup EXIT

cat > "$BASE/modules/pterodactyl.sh" <<'VORTEX_MODULE_pterodactyl_sh_EOF'
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

VORTEX_MODULE_pterodactyl_sh_EOF
chmod +x "$BASE/modules/pterodactyl.sh"

cat > "$BASE/modules/wings.sh" <<'VORTEX_MODULE_wings_sh_EOF'
#!/usr/bin/env bash
set -u
echo "Wings installer"
echo "Checking Docker..."
command -v docker >/dev/null && docker --version || echo "Docker not installed."
echo
echo "For Wings, install/configure the version matching your Pterodactyl Panel."
echo "Official documentation: https://pterodactyl.io/wings/1.0/installing.html"

VORTEX_MODULE_wings_sh_EOF
chmod +x "$BASE/modules/wings.sh"

cat > "$BASE/modules/hvm.sh" <<'VORTEX_MODULE_hvm_sh_EOF'
#!/usr/bin/env bash
set -u
echo "HVM installer placeholder."
echo "Send the exact HVM installer source/command you want VORTEX NODE to use."
echo "It will then be wired into option 3 with OS checks and confirmations."

VORTEX_MODULE_hvm_sh_EOF
chmod +x "$BASE/modules/hvm.sh"

cat > "$BASE/modules/blueprint.sh" <<'VORTEX_MODULE_blueprint_sh_EOF'
#!/usr/bin/env bash
set -u
echo "Blueprint installer"
echo "This module is prepared for the Blueprint installer compatible with your Panel version."
echo "Provide the exact Blueprint release/source if you want it pinned."

VORTEX_MODULE_blueprint_sh_EOF
chmod +x "$BASE/modules/blueprint.sh"

cat > "$BASE/modules/blueprint-fix.sh" <<'VORTEX_MODULE_blueprint-fix_sh_EOF'
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

VORTEX_MODULE_blueprint-fix_sh_EOF
chmod +x "$BASE/modules/blueprint-fix.sh"

cat > "$BASE/modules/docker.sh" <<'VORTEX_MODULE_docker_sh_EOF'
#!/usr/bin/env bash
set -u
if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed:"
  docker --version
else
  echo "Docker is not installed."
  echo "Use Docker's official Ubuntu/Debian installation instructions for your OS."
fi

VORTEX_MODULE_docker_sh_EOF
chmod +x "$BASE/modules/docker.sh"

cat > "$BASE/modules/cloudflare.sh" <<'VORTEX_MODULE_cloudflare_sh_EOF'
#!/usr/bin/env bash
set -u
echo "Cloudflare Tunnel setup"
if command -v cloudflared >/dev/null 2>&1; then cloudflared --version; else echo "cloudflared is not installed."; fi
echo "Use a runtime Cloudflare token; do not hard-code credentials into this repository."

VORTEX_MODULE_cloudflare_sh_EOF
chmod +x "$BASE/modules/cloudflare.sh"

cat > "$BASE/modules/repair.sh" <<'VORTEX_MODULE_repair_sh_EOF'
#!/usr/bin/env bash
set -u
echo "Node / Panel diagnostics"
echo "Docker:"; docker ps 2>/dev/null || true
echo "Wings:"; systemctl status wings --no-pager 2>/dev/null || true
echo "Ports:"; ss -lntp 2>/dev/null | head -30

VORTEX_MODULE_repair_sh_EOF
chmod +x "$BASE/modules/repair.sh"

cat > "$BASE/modules/cleanup.sh" <<'VORTEX_MODULE_cleanup_sh_EOF'
#!/usr/bin/env bash
set -u
echo "System cleanup diagnostics"
df -h /
echo
echo "No destructive deletion is performed automatically."

VORTEX_MODULE_cleanup_sh_EOF
chmod +x "$BASE/modules/cleanup.sh"

cat > "$BASE/vortex" <<'VORTEX_MAIN_EOF'
#!/usr/bin/env bash
set -u

BLUE='\033[1;34m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'
YELLOW='\033[1;33m'; RED='\033[1;31m'; RESET='\033[0m'

BASE="${BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

banner() {
clear
printf "${BLUE}"
cat <<'EOF'
██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗
██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝
╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗
 ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗
  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
EOF
printf "${RESET}"
printf "${CYAN}                 V O R T E X   N O D E${RESET}\n"
printf "${CYAN}              ALL-IN-ONE INSTALLER${RESET}\n\n"
}

loading() {
  local frames=("V" "VO" "VOR" "VORT" "VORTE" "VORTEX" "VORTEX N" "VORTEX NO" "VORTEX NOD" "VORTEX NODE")
  for f in "${frames[@]}"; do
    clear; banner
    printf "${CYAN}                         %s${RESET}\n" "$f"
    printf "${YELLOW}                     LOADING...${RESET}\n"
    sleep 0.5
  done
  sleep 1
}

pause_menu() { echo; read -r -p "Press ENTER to return..." _; }

run_module() {
  local title="$1" file="$2"
  banner
  echo -e "${CYAN}${title}${RESET}\n"
  if [[ -f "$file" ]]; then
    bash "$file"
  else
    echo -e "${RED}Module missing: $file${RESET}"
  fi
  pause_menu
}

main_menu() {
while true; do
  banner
  cat <<'EOF'
╔══════════════════════════════════════════════════╗
║              VORTEX NODE INSTALLER               ║
╠══════════════════════════════════════════════════╣
║ [1] Pterodactyl Panel Installer                  ║
║ [2] Wings Installer                               ║
║ [3] HVM Installer                                 ║
║ [4] Blueprint Installer                           ║
║ [5] Blueprint 500 Error Fixer                     ║
║ [6] Docker Installer                              ║
║ [7] Cloudflare Tunnel                             ║
║ [8] Node / Panel Repair                           ║
║ [9] System Cleanup                                ║
║ [0] Exit                                          ║
╚══════════════════════════════════════════════════╝
EOF
  echo
  read -r -p "VORTEX-NODE > " choice
  case "$choice" in
    1) run_module "PTERODACTYL PANEL INSTALLER" "$BASE/modules/pterodactyl.sh" ;;
    2) run_module "WINGS INSTALLER" "$BASE/modules/wings.sh" ;;
    3) run_module "HVM INSTALLER" "$BASE/modules/hvm.sh" ;;
    4) run_module "BLUEPRINT INSTALLER" "$BASE/modules/blueprint.sh" ;;
    5) run_module "BLUEPRINT 500 ERROR FIXER" "$BASE/modules/blueprint-fix.sh" ;;
    6) run_module "DOCKER INSTALLER" "$BASE/modules/docker.sh" ;;
    7) run_module "CLOUDFLARE TUNNEL" "$BASE/modules/cloudflare.sh" ;;
    8) run_module "NODE / PANEL REPAIR" "$BASE/modules/repair.sh" ;;
    9) run_module "SYSTEM CLEANUP" "$BASE/modules/cleanup.sh" ;;
    0) clear; echo "VORTEX NODE closed."; exit 0 ;;
    *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
  esac
done
}

loading
main_menu

VORTEX_MAIN_EOF
chmod +x "$BASE/vortex"
exec bash "$BASE/vortex"
