# ────────────────────────────────────────────────────
# OpenClaw Enterprise - Docker Image
# Basado en OpenClaw oficial + Node.js
# ────────────────────────────────────────────────────

FROM node:22-alpine

LABEL org.openclaw.enterprise.version="1.0.0"
LABEL org.openclaw.enterprise.description="OpenClaw Enterprise - Asistente AI multi-tenant"

# Instalar dependencias del sistema
RUN apk add --no-cache \
    curl \
    jq \
    ca-certificates \
    bash \
    tzdata

# Instalar OpenClaw globalmente
RUN npm install -g openclaw@2026.4.26

# Instalar ClawHub CLI
RUN npm install -g clawhub

# Directorios
RUN mkdir -p /config /data/workspace /data/skills

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -sf http://localhost:3000/health || exit 1

# Puerto por defecto
EXPOSE 3000

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["openclaw", "gateway", "start", "--config", "/config/openclaw.json"]
