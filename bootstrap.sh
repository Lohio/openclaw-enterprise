#!/usr/bin/env bash
# ═══════════════════════════════════════════════
# OpenClaw Enterprise - Bootstrap Installer
# Distribuido por DByte
# ═══════════════════════════════════════════════
# One-liner:
#   bash <(curl -s https://raw.githubusercontent.com/Lohio/openclaw-enterprise/main/bootstrap.sh)
# ═══════════════════════════════════════════════

set -euo pipefail

REPO="https://github.com/Lohio/openclaw-enterprise"
BRANCH="main"
INSTALLER_URL="${REPO}/raw/${BRANCH}/installer/install.sh"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════╗"
echo "║   OpenClaw Enterprise - Bootstrap     ║"
echo "║   Distribuido por DByte               ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Verificar dependencias mínimas
if ! command -v curl &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} curl no está instalado. Instalando..."
    sudo apt-get update -qq && sudo apt-get install -y -qq curl
fi

if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} git no está instalado. Instalando..."
    sudo apt-get update -qq && sudo apt-get install -y -qq git
fi

# Descargar e instalar
echo -e "${CYAN}[INFO]${NC} Descargando instalador desde GitHub..."
echo ""

bash <(curl -sL "$INSTALLER_URL")
