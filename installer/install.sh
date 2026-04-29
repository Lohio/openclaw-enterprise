#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════
# OpenClaw Enterprise - Instalador Interactivo
# Distribuido por DByte
# ═══════════════════════════════════════════════

VERSION="1.0.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Funciones auxiliares ───────────────────────
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
    echo "║   Distribuido por DByte               ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

# ───────────────────────────────────────
# PASO 0: Términos y Condiciones
# ───────────────────────────────────────

show_terms() {
    header
    echo "╔══════════════════════════════════════════════════╗"
    echo "║        TÉRMINOS Y CONDICIONES DE USO            ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "Al instalar OpenClaw Enterprise usted acepta:"
    echo ""
    echo "1. El Software se proporciona \"TAL CUAL\", sin garantía"
    echo "   de ningún tipo, expresa o implícita."
    echo ""
    echo "2. DByte NO se responsabiliza por:"
    echo "   - Datos sensibles que usted envíe a través del Software"
    echo "   - El uso que los proveedores de IA (OpenAI, Anthropic,"
    echo "     Google, etc.) den a sus datos"
    echo "   - Pérdida, filtración o mal uso de información"
    echo "   - Daños directos o indirectos derivados del uso"
    echo ""
    echo "3. Usted es el único responsable de:"
    echo "   - No compartir información confidencial o protegida"
    echo "   - Cumplir con las leyes de protección de datos"
    echo "   - Obtener los consentimientos necesarios de usuarios"
    echo ""
    echo "4. DByte no recolecta ni almacena datos de clientes."
    echo ""
    echo "📄 Texto completo: docs/TERMS_OF_SERVICE.md"
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo ""

    # Loop hasta que acepte o cancele
    while true; do
        ask "¿Acepta los términos y condiciones? (s/n): "
        read -r accepted
        case "$accepted" in
            s|S|y|Y)
                ok "Términos aceptados. Continuando..."
                echo ""
                return 0
                ;;
            n|N)
                error "Instalación cancelada. Debe aceptar los términos para continuar."
                exit 1
                ;;
            *)
                warn "Respuesta inválida. Presione 's' para aceptar o 'n' para cancelar."
                ;;
        esac
    done
}

# ───────────────────────────────────────
# PASO 1: Modo de instalación
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
# PASO 2: Proveedor de LLM
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
# PASO 3: Gateway
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
# PASO 4: Skills
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

    echo "Elegí los skills que querés instalar (ej: 1,3,5-10,all):"
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
# Generar configuración
# ───────────────────────────────────────

generate_config() {
    header
    info "Generando configuración..."

    mkdir -p "$INSTALL_DIR"

    cat > "$INSTALL_DIR/openclaw.json" << JSONEOF
{
  // OpenClaw Enterprise v${VERSION} — Generado por el instalador
  // Distribuido por DByte — https://github.com/Lohio/openclaw-enterprise
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

    if command -v node &>/dev/null; then
        NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VER" -ge 22 ]; then
            ok "Node.js $(node -v) detectado"
        else
            warn "Node.js $(node -v) es muy viejo (necesita >=22)"
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

    if command -v openclaw &>/dev/null; then
        ok "OpenClaw $(openclaw --version 2>/dev/null || echo 'detectado')"
    else
        info "Instalando OpenClaw..."
        npm install -g openclaw
        ok "OpenClaw instalado"
    fi

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

    if command -v clawhub &>/dev/null; then
        ok "ClawHub CLI detectado"
    else
        info "Instalando ClawHub CLI..."
        npm install -g clawhub 2>/dev/null
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
        clawhub install "$skill" 2>/dev/null || warn "No se pudo instalar $skill"
    done

    ok "Skills instalados en $INSTALL_DIR/workspace/skills/"
}

# ───────────────────────────────────────
# Crear icono en el escritorio
# ───────────────────────────────────────

create_desktop_icon() {
    local desktop_file="$HOME/Escritorio/openclaw-enterprise.desktop"
    # También en inglés
    if [ ! -d "$HOME/Escritorio" ]; then
        desktop_file="$HOME/Desktop/openclaw-enterprise.desktop"
    fi

    mkdir -p "$(dirname "$desktop_file")"

    cat > "$desktop_file" << DESKTOPFILE
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenClaw Enterprise
Comment=Configurar y administrar tu asistente AI
Icon=${INSTALL_DIR}/icon.png
Exec=${INSTALL_DIR}/config-gui.sh
Terminal=true
Categories=Network;Utility;
Keywords=ai;assistant;openclaw;dbyte;
DESKTOPFILE

    chmod +x "$desktop_file"

    # Si estamos en Linux con gio, fijar confianza
    if command -v gio &>/dev/null; then
        gio set "$desktop_file" "metadata::trusted" true 2>/dev/null || true
    fi

    ok "Icono creado en: $desktop_file"
    info "Hacé doble clic en el icono para re-configurar tu asistente"
}

# ───────────────────────────────────────
# Crear script de configuración visual
# ───────────────────────────────────────

create_config_script() {
    cat > "$INSTALL_DIR/config-gui.sh" << 'CONFIGSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
ask()   { echo -e "${CYAN}[?]${NC} $1"; }

clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════╗"
echo "║   OpenClaw Enterprise - Configurador  ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"
echo "Directorio: $INSTALL_DIR"
echo ""

while true; do
    echo "═══════════════════════════════════════"
    echo "  1) 🔄 Cambiar API Key / Proveedor LLM"
    echo "  2) 📡 Cambiar puerto del Gateway"
    echo "  3) 🔐 Cambiar contraseña del Gateway"
    echo "  4) 🔧 Agregar/quitar skills"
    echo "  5) 📋 Ver configuración actual"
    echo "  6) ▶️  Iniciar / Reiniciar OpenClaw"
    echo "  7) ⏹️  Detener OpenClaw"
    echo "  8) 📊 Ver estado"
    echo "  9) 📝 Ver logs en tiempo real"
    echo "  0) 🚪 Salir"
    echo ""
    ask "Opción: "
    read -r opt

    case "$opt" in
        1)
            echo ""
            echo "Proveedores disponibles: openai, anthropic, google, deepseek"
            ask "Nuevo proveedor: "
            read -r new_provider
            ask "Nueva API Key: "
            read -r new_key
            ask "Modelo (ej: gpt-4o, claude-sonnet-4-20250514): "
            read -r new_model

            if [ -f "$INSTALL_DIR/openclaw.json" ]; then
                # Actualizar JSON usando sed (aproximado, funciona para este formato)
                sed -i "s|\"provider\": *\"[^\"]*\"|\"provider\": \"$new_provider\"|" "$INSTALL_DIR/openclaw.json"
                sed -i "s|\"model\": *\"[^\"]*\"|\"model\": \"$new_model\"|" "$INSTALL_DIR/openclaw.json"
                sed -i "s|apiKey: *\"[^\"]*\"|apiKey: \"$new_key\"|" "$INSTALL_DIR/openclaw.json"
                ok "Configuración actualizada"
            else
                warn "No se encuentra openclaw.json"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        2)
            ask "Nuevo puerto: "
            read -r new_port
            if [ -f "$INSTALL_DIR/openclaw.json" ]; then
                sed -i "s|port: *[0-9]*|port: $new_port|" "$INSTALL_DIR/openclaw.json"
                ok "Puerto actualizado a $new_port"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        3)
            ask "Nueva contraseña: "
            read -rs new_pass
            echo ""
            if [ -f "$INSTALL_DIR/openclaw.json" ]; then
                if grep -q "password:" "$INSTALL_DIR/openclaw.json"; then
                    sed -i "s|password: *\"[^\"]*\"|password: \"$new_pass\"|" "$INSTALL_DIR/openclaw.json"
                else
                    sed -i "/port:/a\    password: \"$new_pass\"," "$INSTALL_DIR/openclaw.json"
                fi
                ok "Contraseña actualizada"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        4)
            echo ""
            ask "Nombre del skill a agregar (ej: github): "
            read -r add_skill
            if [ -n "$add_skill" ]; then
                cd "$INSTALL_DIR/workspace"
                clawhub install "$add_skill" 2>/dev/null && ok "Skill $add_skill instalado" || warn "No se pudo instalar $add_skill"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        5)
            echo ""
            info "Configuración actual:"
            echo ""
            if [ -f "$INSTALL_DIR/openclaw.json" ]; then
                cat "$INSTALL_DIR/openclaw.json"
            else
                warn "No hay configuración"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        6)
            echo ""
            # Detener si está corriendo
            if [ -f "$INSTALL_DIR/openclaw.pid" ] && kill -0 "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null; then
                info "Deteniendo instancia actual..."
                kill "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null || true
                sleep 1
            fi
            info "Iniciando OpenClaw..."
            nohup openclaw gateway start --config "$INSTALL_DIR/openclaw.json" > "$INSTALL_DIR/openclaw.log" 2>&1 &
            echo $! > "$INSTALL_DIR/openclaw.pid"
            sleep 2
            if kill -0 "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null; then
                ok "OpenClaw corriendo (PID: $(cat "$INSTALL_DIR/openclaw.pid"))"
            else
                warn "No se pudo iniciar. Revisá los logs."
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        7)
            echo ""
            if [ -f "$INSTALL_DIR/openclaw.pid" ] && kill -0 "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null; then
                kill "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null
                ok "OpenClaw detenido"
            else
                warn "OpenClaw no está corriendo"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        8)
            echo ""
            if [ -f "$INSTALL_DIR/openclaw.pid" ] && kill -0 "$(cat "$INSTALL_DIR/openclaw.pid")" 2>/dev/null; then
                PID=$(cat "$INSTALL_DIR/openclaw.pid")
                ok "OpenClaw está CORRIENDO (PID: $PID)"
                # Mostrar puerto
                PORT=$(grep -oP 'port: \K\d+' "$INSTALL_DIR/openclaw.json" 2>/dev/null || echo "desconocido")
                info "Puerto: $PORT"
                info "Uptime: $(ps -o etime= -p "$PID" 2>/dev/null || echo 'N/A')"
            else
                warn "OpenClaw NO está corriendo"
            fi
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        9)
            echo ""
            info "Logs (Ctrl+C para salir):"
            echo ""
            tail -f "$INSTALL_DIR/openclaw.log" 2>/dev/null || warn "No hay logs aún"
            echo ""
            ask "Presioná Enter para continuar..."
            read -r
            ;;
        0)
            echo ""
            ok "Hasta luego!"
            exit 0
            ;;
        *)
            warn "Opción inválida"
            sleep 1
            ;;
    esac
done
CONFIGSCRIPT

    chmod +x "$INSTALL_DIR/config-gui.sh"
    ok "Script de configuración creado en: $INSTALL_DIR/config-gui.sh"
}

# ───────────────────────────────────────
# Crear icono PNG minimalista
# ───────────────────────────────────────

create_icon() {
    # Generar un icono SVG simple (se ve bien en cualquier escritorio Linux)
    cat > "$INSTALL_DIR/icon.svg" << SVGEOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#2563eb;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#7c3aed;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="24" fill="url(#bg)"/>
  <!-- Langosta / OpenClaw -->
  <g transform="translate(64,60)" fill="white" text-anchor="middle" font-family="sans-serif">
    <text y="-20" font-size="48">🦞</text>
    <text y="30" font-size="12" font-weight="bold">OpenClaw</text>
    <text y="45" font-size="8" opacity="0.8">Enterprise</text>
  </g>
</svg>
SVGEOF

    # Intentar convertir a PNG (si no, queda SVG que también funciona)
    if command -v convert &>/dev/null; then
        convert "$INSTALL_DIR/icon.svg" "$INSTALL_DIR/icon.png" 2>/dev/null
        ok "Icono PNG creado"
    else
        # Copiar como PNG (los DE admiten SVG)
        cp "$INSTALL_DIR/icon.svg" "$INSTALL_DIR/icon.png"
        info "Icono SVG (compatible con la mayoría de escritorios)"
    fi
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

    if [ "$INSTALL_MODE" = "multi" ] && [ -d /etc/systemd/system ]; then
        create_systemd_service
    fi
}

create_systemd_service() {
    local SERVICE_NAME="openclaw-$(basename "$INSTALL_DIR")"
    local SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    cat > /tmp/openclaw-service << SERVICEEOF
[Unit]
Description=OpenClaw Enterprise - $(basename "$INSTALL_DIR") (DByte)
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
    echo "📌 Hacé doble clic en el icono del escritorio"
    echo "   para administrar tu asistente (cambiar API,"
    echo "   skills, iniciar/detener, ver logs)"
    echo ""
    echo "Para iniciar manualmente:"
    echo "  $INSTALL_DIR/config-gui.sh"
    echo ""
    echo -e "${GREEN}Gracias por usar OpenClaw Enterprise — DByte${NC}"
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
    echo "  ║  Distribuido por DByte                   ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo ""

    INSTALL_DIR="${INSTALL_DIR:-$HOME/openclaw-enterprise}"

    # Primero: mostrar términos y condiciones
    show_terms

    # Luego: wizard de configuración
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
    create_icon
    create_desktop_icon
    create_config_script
    start_service
    show_summary

    # Guardar aceptación de términos (para constancia)
    echo "Aceptado el $(date '+%Y-%m-%d %H:%M:%S')" > "$INSTALL_DIR/.terms_accepted"
}

main "$@"
