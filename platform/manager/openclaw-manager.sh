#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════
# OpenClaw Enterprise - Multi-Tenant Manager
# ═══════════════════════════════════════════════
# Uso: ./openclaw-manager.sh <comando> [opciones]
#
# Comandos:
#   create     Crear un nuevo cliente
#   delete     Eliminar un cliente
#   list       Listar clientes activos
#   status     Ver estado de un cliente
#   restart    Reiniciar un cliente
#   logs       Ver logs de un cliente
#   backup     Backup de un cliente
# ═══════════════════════════════════════════════

VERSION="1.0.0"
BASE_DIR="${OPENCLAW_HOME:-/opt/openclaw-enterprise}"
DOCKER_NETWORK="openclaw-net"
TEMPLATE_DIR="$(dirname "$0")/../docker"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
    echo "OpenClaw Enterprise Manager v$VERSION"
    echo ""
    echo "Uso: $0 <comando> [opciones]"
    echo ""
    echo "Comandos:"
    echo "  create <nombre>    Crear un nuevo cliente"
    echo "                       --llm-key KEY       (requerido)"
    echo "                       --provider PROVIDER  (default: openai)"
    echo "                       --model MODEL        (default: gpt-4o)"
    echo "                       --port PORT          (default: auto)"
    echo "                       --domain DOMAIN      (para proxy reverso)"
    echo "                       --admin-pwd PASSWORD  (para el gateway)"
    echo ""
    echo "  delete <nombre>    Eliminar un cliente (con datos)"
    echo "  list               Listar todos los clientes"
    echo "  status <nombre>    Estado de un cliente"
    echo "  restart <nombre>   Reiniciar un cliente"
    echo "  logs <nombre>      Ver logs de un cliente"
    echo "  backup <nombre>    Backup de config + workspace"
    echo ""
    echo "Ejemplos:"
    echo "  $0 create empresa-x --llm-key sk-xxx --provider openai --port 3001"
    echo "  $0 list"
    echo "  $0 logs empresa-x -f"
}

# ───────────────────────────────────────
# Docker helpers
# ───────────────────────────────────────

ensure_network() {
    docker network inspect "$DOCKER_NETWORK" &>/dev/null || \
        docker network create "$DOCKER_NETWORK" &>/dev/null
}

find_available_port() {
    local port=3000
    while docker ps --format '{{.Ports}}' | grep -q "${port}->"; do
        port=$((port + 1))
    done
    echo "$port"
}

# ───────────────────────────────────────
# Comando: create
# ───────────────────────────────────────

cmd_create() {
    local name=""
    local llm_key=""
    local provider="openai"
    local model="gpt-4o"
    local port=""
    local domain=""
    local admin_pwd=""

    # Parsear args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --llm-key) llm_key="$2"; shift 2;;
            --provider) provider="$2"; shift 2;;
            --model) model="$2"; shift 2;;
            --port) port="$2"; shift 2;;
            --domain) domain="$2"; shift 2;;
            --admin-pwd) admin_pwd="$2"; shift 2;;
            *) name="$1"; shift;;
        esac
    done

    # Validaciones
    [ -z "$name" ] && error "Nombre de cliente requerido"
    [ -z "$llm_key" ] && error "--llm-key requerido"
    [ -z "$port" ] && port=$(find_available_port)

    local client_dir="$BASE_DIR/clients/$name"
    [ -d "$client_dir" ] && error "Cliente '$name' ya existe en $client_dir"

    info "Creando cliente: $name"
    info "  Proveedor: $provider | Modelo: $model | Puerto: $port"

    # Crear estructura
    mkdir -p "$client_dir"/{config,workspace,data}

    # Generar openclaw.json
    cat > "$client_dir/config/openclaw.json" << JSONEOF
{
  // OpenClaw Enterprise - Cliente: $name
  models: {
    providers: {
      "${provider}": {
        apiKey: "${llm_key}",
      },
    },
    defaultModel: {
      provider: "${provider}",
      model: "${model}",
    },
  },
  gateway: {
    port: 3000,
${admin_pwd:+    password: "${admin_pwd}",}
  },
  agents: {
    defaults: {
      workspace: "/data/workspace",
    },
  },
}
JSONEOF

    # Crear docker-compose para este cliente
    cat > "$client_dir/docker-compose.yml" << YAMLEOF
version: '3.8'

services:
  openclaw-${name}:
    image: openclaw/openclaw:latest
    container_name: openclaw-${name}
    restart: unless-stopped
    ports:
      - "${port}:3000"
    volumes:
      - ./config:/config:ro
      - ./workspace:/data/workspace
      - ./data:/data
    environment:
      - NODE_ENV=production
      - OPENCLAW_CONFIG_PATH=/config/openclaw.json
    networks:
      - ${DOCKER_NETWORK}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  ${DOCKER_NETWORK}:
    external: true
YAMLEOF

    # Si tiene dominio, crear config de nginx
    if [ -n "$domain" ]; then
        info "Configurando proxy reverso para $domain → localhost:$port"

        mkdir -p "$client_dir/proxy"
        cat > "$client_dir/proxy/nginx.conf" << NGINXEOF
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINXEOF

        # Registrar en el proxy global
        local nginx_available="/etc/nginx/sites-available/openclaw-${name}"
        local nginx_enabled="/etc/nginx/sites-enabled/openclaw-${name}"

        if [ -d "/etc/nginx" ]; then
            sudo cp "$client_dir/proxy/nginx.conf" "$nginx_available"
            sudo ln -sf "$nginx_available" "$nginx_enabled"
            sudo nginx -t && sudo systemctl reload nginx
            ok "Nginx: $domain → localhost:$port"
        else
            warn "Nginx no instalado. Config manual: $client_dir/proxy/nginx.conf"
        fi
    fi

    # Iniciar contenedor
    info "Iniciando contenedor..."
    (cd "$client_dir" && docker-compose up -d 2>&1)

    # Esperar healthcheck
    info "Esperando que arranque..."
    for i in {1..10}; do
        if curl -sf "http://localhost:${port}/health" &>/dev/null; then
            ok "Cliente '$name' corriendo en puerto $port"
            ok "URL: http://localhost:${port}"
            [ -n "$domain" ] && ok "URL pública: https://${domain}"
            return 0
        fi
        sleep 2
    done

    warn "Cliente creado pero puede no estar respondiendo aún"
    warn "Revisá: $0 logs $name"
}

# ───────────────────────────────────────
# Comando: delete
# ───────────────────────────────────────

cmd_delete() {
    local name="$1"
    [ -z "$name" ] && error "Nombre de cliente requerido"

    local client_dir="$BASE_DIR/clients/$name"
    [ ! -d "$client_dir" ] && error "Cliente '$name' no encontrado"

    warn "⚠️  Esto ELIMINARÁ todos los datos del cliente '$name'"
    read -p "¿Estás seguro? (escribí el nombre del cliente para confirmar): " confirm
    [ "$confirm" != "$name" ] && error "Confirmación incorrecta"

    info "Deteniendo contenedor..."
    (cd "$client_dir" && docker-compose down -v 2>&1 || true)

    # Eliminar nginx config si existe
    if [ -f "/etc/nginx/sites-enabled/openclaw-${name}" ]; then
        sudo rm -f "/etc/nginx/sites-available/openclaw-${name}" "/etc/nginx/sites-enabled/openclaw-${name}"
        sudo nginx -t && sudo systemctl reload nginx || true
    fi

    rm -rf "$client_dir"
    ok "Cliente '$name' eliminado"
}

# ───────────────────────────────────────
# Comando: list
# ───────────────────────────────────────

cmd_list() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           OpenClaw Enterprise - Clientes Activos        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local clients_dir="$BASE_DIR/clients"
    if [ ! -d "$clients_dir" ]; then
        info "No hay clientes configurados"
        return
    fi

    printf "%-20s %-8s %-15s %-15s %-10s\n" "CLIENTE" "PUERTO" "PROVEEDOR" "MODELO" "ESTADO"
    echo "────────────────────────────────────────────────────────────────"

    for client_dir in "$clients_dir"/*/; do
        local name=$(basename "$client_dir")
        local port=$(docker ps --format '{{.Ports}}' --filter "name=openclaw-${name}" | sed 's/.*:\([0-9]*\)->.*/\1/' 2>/dev/null || echo "N/A")
        local status=$(docker ps --format '{{.Status}}' --filter "name=openclaw-${name}" 2>/dev/null || echo "stopped")

        # Leer provider y model del config
        local config_file="$client_dir/config/openclaw.json"
        local provider=""
        local model=""
        if [ -f "$config_file" ]; then
            provider=$(grep -o '"provider": *"[^"]*"' "$config_file" 2>/dev/null | head -1 | sed 's/"provider": *"\(.*\)"/\1/')
            model=$(grep -o '"model": *"[^"]*"' "$config_file" 2>/dev/null | head -1 | sed 's/"model": *"\(.*\)"/\1/')
        fi

        if docker ps --format '{{.Names}}' --filter "name=openclaw-${name}" | grep -q "openclaw-${name}"; then
            printf "%-20s %-8s %-15s %-15s ${GREEN}%-10s${NC}\n" "$name" "${port:-N/A}" "${provider:-N/A}" "${model:-N/A}" "running"
        else
            printf "%-20s %-8s %-15s %-15s ${RED}%-10s${NC}\n" "$name" "N/A" "${provider:-N/A}" "${model:-N/A}" "stopped"
        fi
    done

    echo ""
    info "Total contenedores: $(docker ps --filter 'name=openclaw-' --format '{{.Names}}' 2>/dev/null | wc -l)"
}

# ───────────────────────────────────────
# Comando: status
# ───────────────────────────────────────

cmd_status() {
    local name="$1"
    [ -z "$name" ] && error "Nombre de cliente requerido"

    echo ""
    echo -e "${CYAN}Estado del cliente: $name${NC}"
    echo "──────────────────────────────────────"
    echo ""

    docker ps --filter "name=openclaw-${name}" --format="table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No running"

    echo ""
    if [ -f "$BASE_DIR/clients/$name/config/openclaw.json" ]; then
        info "Config: $BASE_DIR/clients/$name/config/openclaw.json"
        info "Workspace: $BASE_DIR/clients/$name/workspace"
    fi
}

# ───────────────────────────────────────
# Comando: logs
# ───────────────────────────────────────

cmd_logs() {
    local name="$1"
    shift
    [ -z "$name" ] && error "Nombre de cliente requerido"

    docker logs "openclaw-${name}" "$@" 2>&1 || error "Contenedor 'openclaw-${name}' no encontrado"
}

# ───────────────────────────────────────
# Comando: restart
# ───────────────────────────────────────

cmd_restart() {
    local name="$1"
    [ -z "$name" ] && error "Nombre de cliente requerido"

    info "Reiniciando cliente: $name"
    docker restart "openclaw-${name}" 2>&1 || error "Contenedor 'openclaw-${name}' no encontrado"
    ok "Cliente '$name' reiniciado"
}

# ───────────────────────────────────────
# Comando: backup
# ───────────────────────────────────────

cmd_backup() {
    local name="$1"
    [ -z "$name" ] && error "Nombre de cliente requerido"

    local client_dir="$BASE_DIR/clients/$name"
    [ ! -d "$client_dir" ] && error "Cliente '$name' no encontrado"

    local backup_dir="$BASE_DIR/backups"
    local backup_file="$backup_dir/${name}-$(date +%Y%m%d_%H%M%S).tar.gz"

    mkdir -p "$backup_dir"

    info "Respaldando cliente: $name"
    tar -czf "$backup_file" -C "$client_dir" config workspace data 2>/dev/null || tar -czf "$backup_file" -C "$client_dir" config workspace
    ok "Backup creado: $backup_file ($(du -h "$backup_file" | cut -f1))"
}

# ───────────────────────────────────────
# MAIN
# ───────────────────────────────────────

main() {
    [ $# -eq 0 ] && { usage; exit 1; }

    local cmd="$1"
    shift

    case "$cmd" in
        create)  cmd_create "$@";;
        delete)  cmd_delete "$@";;
        list)    cmd_list;;
        status)  cmd_status "$@";;
        logs)    cmd_logs "$@";;
        restart) cmd_restart "$@";;
        backup)  cmd_backup "$@";;
        help)    usage;;
        *)       error "Comando desconocido: $cmd";;
    esac
}

main "$@"
