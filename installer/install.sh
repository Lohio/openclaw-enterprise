#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════
# OpenClaw Enterprise - Instalador Interactivo
# ═══════════════════════════════════════════════

VERSION="1.0.0"
OPENCLAW_VERSION="2026.4.26"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ───────────────────────────────────────
# Funciones auxiliares
# ───────────────────────────────────────

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
ask()   { echo -e "${CYAN}[?]${NC} $1"; }

header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║       OpenClaw Enterprise v${VERSION}        ║"
    echo "║   Asistente AI para tu empresa        ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "No estás ejecutando como root."
        warn "Algunas funciones (instalar Docker, systemd) necesitarán sudo."
        echo ""
        ask "¿Querés continuar igual? (s/N): "
        read -r resp
        if [[ ! "$resp" =~ ^[sS]$ ]]; then
            exit 1
        fi
    fi
}

# ───────────────────────────────────────
# Paso 1: Seleccionar modo de instalación
# ───────────────────────────────────────

select_mode() {
    header
    echo "Elegí el modo de instalación:"
    echo ""
    echo "  1) 🖥️  Single - Una instancia local (para probar)"
    echo "  2) 🏢  Multi-tenant - Varios clientes con Docker (producción)"
    echo ""
    ask "Opción [1/2] (por defecto 1): "
    read -r mode
    mode=${mode:-1}

    case "$mode" in
        1) INSTALL_MODE="single";;
        2) INSTALL_MODE="multi";;
        *) INSTALL_MODE="single";;
    esac
}

# ───────────────────────────────────────
# Paso 2: Elegir proveedor de LLM
# ───────────────────────────────────────

select_llm() {
    header
    echo "¿Qué proveedor de IA querés usar?"
    echo ""
    echo "  1) OpenAI (GPT-4o, GPT-4, etc.)"
    echo "  2) Anthropic (Claude 3.5 Sonnet, Haiku)"
    echo "  3) Google (Gemini 2.0 Pro, Flash)"
    echo "  4) DeepSeek (DeepSeek V3, R1)"
    echo "  5) Otro / Custom API"
    echo ""
    ask "Opción [1-5]: "
    read -r llm_choice

    case "$llm_choice" in
        1)
            LLM_PROVIDER="openai"
            LLM_DEFAULT_MODEL="gpt-4o"
            ask "API Key de OpenAI: "
            read -r LLM_API_KEY
            ;;
        2)
            LLM_PROVIDER="anthropic"
            LLM_DEFAULT_MODEL="claude-sonnet-4-20250514"
            ask "API Key de Anthropic: "
            read -r LLM_API_KEY
            ;;
        3)
            LLM_PROVIDER="google"
            LLM_DEFAULT_MODEL="gemini-2.0-flash-001"
            ask "API Key de Google AI: "
            read -r LLM_API_KEY
            ;;
        4)
            LLM_PROVIDER="deepseek"
            LLM_DEFAULT_MODEL="deepseek-chat"
            ask "API Key de DeepSeek: "
            read -r LLM_API_KEY
            ;;
        5)
            LLM_PROVIDER="custom"
            ask "Base URL de la API (ej: https://api.miproxy.com/v1): "
            read -r LLM_BASE_URL
            ask "Modelo por defecto: "
            read -r LLM_DEFAULT_MODEL
            ask "API Key: "
            read -r LLM_API_KEY
            ;;
        *)
            LLM_PROVIDER="openai"
            LLM_DEFAULT_MODEL="gpt-4o"
            ask "API Key de OpenAI: "
            read -r LLM_API_KEY
            ;;
    esac
}

# ───────────────────────────────────────
# Paso 3: Configurar Gateway
# ───────────────────────────────────────

configure_gateway() {
    header
    echo "Configuración del Gateway (servidor OpenClaw)"
    echo ""

    ask "Puerto para el Gateway (por defecto 3000): "
    read -r GW_PORT
    GW_PORT=${GW_PORT:-3000}

    ask "Contraseña para el Gateway (dejá vacío para desactivar auth): "
    read -rs GW_PASSWORD
    echo ""

    ask "¿Querés conectar canales? (Telegram, Discord, WhatsApp) (s/N): "
    read -r setup_channels
}

# ───────────────────────────────────────
# Paso 4: Skills a instalar
# ───────────────────────────────────────

select_skills() {
    header
    echo "Skills recomendados para instalar:"
    echo ""

    SKILLS=(
        "github:GitHub - Issues, PRs, repos"
        "notion:Notion - Documentos y bases"
        "slack:Slack - Mensajes y canales"
        "calendar:Calendar - Google Calendar"
        "weather:Weather - Pronóstico"
        "spotify:Spotify - Música"
        "trello:Trello - Kanban"
        "docker:Docker - Contenedores"
        "jira:JIRA - Tickets y sprints"
        "gmail:Gmail - Correo"
        "translate:Translate - Traducción"
        "news:News - Resumen noticias"
        "nano-pdf:Nano PDF - Documentos PDF"
        "diagram:Diagram - Diagramas"
        "memory:Memory - Memoria persistente"
        "search:Search - Búsqueda web"
        "voice:Voice - Voz y TTS"
        "server-health:Server Health - Monitoreo"
        "nginx-config:Nginx Config"
        "ssl-certificate:SSL Certificate"
        "firewall:Firewall"
        "sql-toolkit:SQL Toolkit"
        "screenshot:Screenshot"
        "stock:Stock y Crypto"
        "backup:Backup Automation"
        "meeting:Meeting Notes"
        "crm:CRM"
        "alert-manager:Alert Manager"
        "git:Git"
        "webhook-notify:Webhook Notify"
    )

    echo "Elegí los skills que querés instalar (ej: 1,3,5-10,all): "
    echo ""
    for i in "${!SKILLS[@]}"; do
        printf "  %2d) %s\n" $((i+1)) "${SKILLS[$i]##*:}"
    done
    echo ""
    echo "  a) Todos"
    echo "  n) Ninguno (solo los esenciales)"
    echo ""
    ask "Tu selección: "
    read -r skill_selection

    SELECTED_SKILLS=()
    if [ "$skill_selection" = "a" ]; then
        for s in "${SKILLS[@]}"; do
            SELECTED_SKILLS+=("${s%%:*}")
        done
    elif [ "$skill_selection" = "n" ]; then
        SELECTED_SKILLS=("memory" "search" "weather")
    else
        # Parsear selección "1,3,5-10"
        IFS=',' read -ra parts <<< "$skill_selection"
        for part in "${parts[@]}"; do
            if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                for ((idx=${BASH_REMATCH[1]}-1; idx<${BASH_REMATCH[2]}; idx++)); do
                    SELECTED_SKILLS+=("${SKILLS[$idx]%%:*}")
                done
            else
                idx=$((part - 1))
                SELECTED_SKILLS+=("${SKILLS[$idx]%%:*}")
            fi
        done
    fi

    ok "Skills seleccionados: ${SELECTED_SKILLS[*]}"
}

# ───────────────────────────────────────
# Generar archivos de configuración
# ───────────────────────────────────────

generate_config() {
    header
    info "Generando configuración..."

    mkdir -p "$INSTALL_DIR/openclaw.json"

    # Config principal
    cat > "$INSTALL_DIR/openclaw.json" << JSONEOF
{
  // OpenClaw Enterprise - Configuración generada por el instalador
  // Documentación: https://docs.openclaw.ai/gateway/configuration

  models: {
    providers: {
      "${LLM_PROVIDER}": {
        apiKey: "${LLM_API_KEY}",
        ${LLM_BASE_URL:+baseUrl: "${LLM_BASE_URL}",}
      },
    },
    defaultModel: {
      provider: "${LLM_PROVIDER}",
      model: "${LLM_DEFAULT_MODEL}",
    },
  },

  gateway: {
    port: ${GW_PORT},
    ${GW_PASSWORD:+password: "${GW_PASSWORD}",}
  },

  agents: {
    defaults: {
      workspace: "${INSTALL_DIR}/workspace",
      skills: [${SELECTED_SKILLS[*]/#/\"}${SELECTED_SKILLS[*]// /\"\,\"}\"],
    },
  },
}
JSONEOF

    mkdir -p "$INSTALL_DIR/workspace"
    ok "Configuración generada en $INSTALL_DIR/openclaw.json"
}

# ───────────────────────────────────────
# Instalar dependencias
# ───────────────────────────────────────

install_deps() {
    header
    info "Verificando dependencias..."

    # Node.js
    if command -v node &>/dev/null; then
        NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VER" -ge 22 ]; then
            ok "Node.js $(node -v) detectado"
        else
            warn "Node.js $(node -v) es muy viejo. Se necesita >=22"
            ask "¿Instalar Node.js 22? (s/N): "
            read -r install_node
            if [[ "$install_node" =~ ^[sS]$ ]]; then
                install_nodejs
            fi
        fi
    else
        warn "Node.js no está instalado"
        ask "¿Instalar Node.js 22? (s/N): "
        read -r install_node
        if [[ "$install_node" =~ ^[sS]$ ]]; then
            install_nodejs
        else
            error "Node.js es requerido. Instalalo manualmente: https://nodejs.org"
        fi
    fi

    # OpenClaw
    if command -v openclaw &>/dev/null; then
        ok "OpenClaw $(openclaw --version 2>/dev/null || echo 'detectado')"
    else
        info "Instalando OpenClaw..."
        npm install -g openclaw
        ok "OpenClaw instalado"
    fi

    # Docker (solo multi-tenant)
    if [ "$INSTALL_MODE" = "multi" ]; then
        if command -v docker &>/dev/null; then
            ok "Docker detectado"
        else
            warn "Docker no está instalado"
            ask "¿Instalar Docker? (requiere sudo) (s/N): "
            read -r install_docker
            if [[ "$install_docker" =~ ^[sS]$ ]]; then
                install_docker
            fi
        fi
    fi

    # ClawHub CLI (para skills)
    if command -v clawhub &>/dev/null; then
        ok "ClawHub CLI detectado"
    else
        info "Instalando ClawHub CLI..."
        npm install -g clawhub
        ok "ClawHub CLI instalado"
    fi
}

install_nodejs() {
    info "Instalando Node.js v22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    ok "Node.js $(node -v) instalado"
}

install_docker() {
    info "Instalando Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    ok "Docker instalado (puede requerir reinicio de sesión)"
}

# ───────────────────────────────────────
# Instalar skills
# ───────────────────────────────────────

install_skills() {
    header
    info "Instalando skills desde ClawHub..."

    for skill in "${SELECTED_SKILLS[@]}"; do
        info "Instalando skill: $skill..."
        cd "$INSTALL_DIR/workspace"
        clawhub install "$skill" 2>/dev/null || warn "No se pudo instalar $skill (puede no existir en el registry)"
    done

    ok "Skills instalados en $INSTALL_DIR/workspace/skills/"
}

# ───────────────────────────────────────
# Iniciar servicio
# ───────────────────────────────────────

start_service() {
    header
    echo "¿Querés iniciar OpenClaw ahora?"
    echo ""
    ask "Iniciar? (S/n): "
    read -r start_now
    start_now=${start_now:-s}

    if [[ "$start_now" =~ ^[sS]$ ]]; then
        info "Iniciando OpenClaw..."
        nohup openclaw gateway start --config "$INSTALL_DIR/openclaw.json" > "$INSTALL_DIR/openclaw.log" 2>&1 &
        echo $! > "$INSTALL_DIR/openclaw.pid"

        # Esperar a que arranque
        sleep 2

        if kill -0 "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null; then
            ok "OpenClaw corriendo en puerto $GW_PORT (PID: $(cat "$INSTALL_DIR/openclaw.pid"))"
            echo ""
            echo "  Logs:  tail -f $INSTALL_DIR/openclaw.log"
            echo "  Docs:  https://docs.openclaw.ai"
        else
            warn "No se pudo iniciar. Revisá $INSTALL_DIR/openclaw.log"
        fi
    fi

    # Crear systemd si es multi-tenant
    if [ "$INSTALL_MODE" = "multi" ] && [ -d /etc/systemd/system ]; then
        create_systemd_service
    fi
}

create_systemd_service() {
    local SERVICE_NAME="openclaw-$(basename "$INSTALL_DIR")"
    local SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    cat > /tmp/openclaw-service << SERVICEEOF
[Unit]
Description=OpenClaw Enterprise - $(basename "$INSTALL_DIR")
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$(which openclaw) gateway start --config $INSTALL_DIR/openclaw.json
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SERVICEEOF

    ask "¿Instalar como servicio systemd? (requiere sudo) (s/N): "
    read -r install_systemd
    if [[ "$install_systemd" =~ ^[sS]$ ]]; then
        sudo cp /tmp/openclaw-service "$SERVICE_FILE"
        sudo systemctl daemon-reload
        sudo systemctl enable "${SERVICE_NAME}.service"
        sudo systemctl start "${SERVICE_NAME}.service"
        ok "Servicio systemd instalado: $SERVICE_NAME"
    fi
}

# ───────────────────────────────────────
# Resumen final
# ───────────────────────────────────────

show_summary() {
    header
    echo "╔═══════════════════════════════════════╗"
    echo "║        Instalación Completada!        ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    echo "  Modo:        $INSTALL_MODE"
    echo "  Proveedor:   $LLM_PROVIDER"
    echo "  Modelo:      $LLM_DEFAULT_MODEL"
    echo "  Puerto:      $GW_PORT"
    echo "  Skills:      ${#SELECTED_SKILLS[@]} seleccionados"
    echo "  Directorio:  $INSTALL_DIR"
    echo ""
    echo "Para iniciar manualmente:"
    echo "  openclaw gateway start --config $INSTALL_DIR/openclaw.json"
    echo ""
    echo "Para probar tu asistente:"
    echo "  openclaw run 'Hola! Quién soy?'"
    echo ""
    echo -e "${GREEN}Gracias por usar OpenClaw Enterprise!${NC}"
    echo ""
}

# ───────────────────────────────────────
# MAIN
# ───────────────────────────────────────

main() {
    echo ""
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     OpenClaw Enterprise v${VERSION}         ║"
    echo "  ║  Wizard de Instalación Interactivo       ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo ""

    INSTALL_DIR="${INSTALL_DIR:-$HOME/openclaw-enterprise}"

    select_mode
    select_llm
    configure_gateway
    select_skills

    # Confirmar
    echo ""
    warn "Se instalará en: $INSTALL_DIR"
    ask "¿Confirmar instalación? (S/n): "
    read -r confirm
    confirm=${confirm:-s}

    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        info "Instalación cancelada."
        exit 0
    fi

    install_deps
    generate_config
    install_skills
    start_service
    show_summary
}

main "$@"
