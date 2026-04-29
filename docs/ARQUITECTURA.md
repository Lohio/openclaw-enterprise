# Arquitectura de OpenClaw Enterprise

## Visión General

```
┌──────────────────────────────────────────────────────────────┐
│                    Internet (Clientes)                        │
└──────────┬──────────────┬────────────────┬───────────────────┘
           │              │                │
    ┌──────▼──────┐ ┌─────▼──────┐  ┌──────▼────────┐
    │ cliente-a   │ │ cliente-b  │  │ admin         │
    │ .miweb.io   │ │ .miweb.io  │  │ .miweb.io     │
    └──────┬──────┘ └─────┬──────┘  └──────┬────────┘
           │              │                │
    ┌──────▼──────────────────────────────▼──────────────┐
    │           Caddy / Nginx (Proxy Reverso)            │
    │         + SSL Automático (Let's Encrypt)           │
    └──────┬──────────────┬────────────────┬─────────────┘
           │              │                │
    ┌──────▼──────┐ ┌─────▼──────┐  ┌──────▼────────┐
    │ Docker:     │ │ Docker:    │  │ Docker:       │
    │ openclaw-a  │ │ openclaw-b │  │ admin-panel   │
    │ :3001       │ │ :3002      │  │ :8080         │
    └──────┬──────┘ └─────┬──────┘  └───────────────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ /data/a/    │ │ /data/b/   │
    │  ├ config/  │ │  ├ config/ │
    │  ├ workspace│ │  ├ workspace│
    │  └ data/    │ │  └ data/   │
    └─────────────┘ └────────────┘
```

## Componentes

### 1. Instalador (Wizard)
Script bash interactivo que guía al usuario paso a paso:
1. Elegir modo (single / multi-tenant)
2. Seleccionar proveedor de IA
3. Ingresar API Key
4. Configurar puerto y password
5. Elegir skills a instalar
6. Generar configuración
7. Iniciar servicio

### 2. Gestor Multi-Tenant (CLI)
Script que administra clientes:
- `create`: Crea Docker + configuración + proxy
- `delete`: Elimina todo (con confirmación)
- `list`: Muestra todos los clientes
- `status`, `logs`, `restart`, `backup`

### 3. Infraestructura Docker
- Dockerfile basado en `node:22-alpine`
- docker-compose.yml con Caddy (auto SSL)
- Red aislada por cliente
- Healthchecks y restart automático

### 4. Dashboard Web (próximamente)
Panel de administración con:
- Lista de clientes
- Estado de cada instancia
- Logs en vivo
- Crear/eliminar desde UI
- Métricas de uso

## Seguridad

| Aspecto | Implementación |
|---------|---------------|
| Aislamiento | Cada cliente en su Docker + su workspace |
| API Keys | En el config.json de cada cliente (no compartidas) |
| Network | Docker network interna, solo proxy expuesto |
| SSL | Caddy con Let's Encrypt automático |
| Gateway Auth | Password opcional por cliente |
| Backup | TAR.GZ de config + workspace por cliente |

## Requisitos del Sistema

| Componente | Mínimo | Recomendado |
|------------|:-----:|:-----------:|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Disco | 20 GB | 50+ GB |
| Docker | 20.10+ | 24+ |
| Node.js | 22.x | 22.x LTS |
| OpenClaw | 2026.4.26+ | latest |
