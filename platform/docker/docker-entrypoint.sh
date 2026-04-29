#!/bin/sh
set -e

# ───────────────────────────────────────
# OpenClaw Enterprise - Docker Entrypoint
# ───────────────────────────────────────

echo "╔═══════════════════════════════════════╗"
echo "║     OpenClaw Enterprise v1.0.0        ║"
echo "╚═══════════════════════════════════════╝"

# Verificar config
if [ ! -f /config/openclaw.json ]; then
    echo "[ERROR] No se encontró /config/openclaw.json"
    echo "Montá el archivo de configuración como volumen:"
    echo "  -v /path/to/openclaw.json:/config/openclaw.json:ro"
    exit 1
fi

echo "[INFO] Config: /config/openclaw.json"
echo "[INFO] Workspace: /data/workspace"
echo "[INFO] Skills: /data/skills"
echo ""

# Instalar skills del pack si hay lista
SKILLS_FILE="/config/skills.txt"
if [ -f "$SKILLS_FILE" ]; then
    echo "[INFO] Instalando skills desde skills.txt..."
    while IFS= read -r skill || [ -n "$skill" ]; do
        [ -z "$skill" ] || [ "${skill#\#}" != "$skill" ] && continue
        echo "  → Instalando: $skill"
        clawhub install "$skill" --dir /data/skills 2>/dev/null || \
            echo "  ⚠️  No se pudo instalar: $skill"
    done < "$SKILLS_FILE"
    echo "[INFO] Skills instalados"
    echo ""
fi

# Ejecutar OpenClaw
echo "[INFO] Iniciando OpenClaw Gateway..."
exec "$@"
