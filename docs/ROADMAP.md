# Roadmap de OpenClaw Enterprise

## v1.0 — MVP (ahora)
- [x] Instalador interactivo (wizard bash)
- [x] Multi-tenant via Docker
- [x] Gestor de clientes (CLI)
- [x] Skills pack recomendado (30 skills)
- [x] Proxy reverso con Caddy
- [x] Documentación de arquitectura

## v1.1 — Próximo
- [ ] Dashboard web de administración
  - Lista de clientes con estado
  - Crear/eliminar desde UI
  - Logs en vivo
  - Métricas (tickets procesados, tokens gastados)
- [ ] Monitoreo de uso por cliente
  - Consumo de API (tokens/día)
  - Alertas de gasto excesivo
- [ ] Backup automático programado
- [ ] Comando `openclaw-manager update` (actualizar clientes)

## v1.2 — Crecimiento
- [ ] Marketplace de skills propietarios
  - Skills de integración (Zoho, Salesforce, HubSpot)
  - Skills de monitoreo proactivo
  - Skills de análisis de datos
- [ ] Planes de facturación
  - Free: 1 cliente, skills básicos
  - Pro: 5 clientes, skills premium
  - Enterprise: ilimitado
- [ ] API REST para integración con sistemas externos

## v1.3 — Enterprise
- [ ] SSO / LDAP / Active Directory
- [ ] Auditoría de logs por cliente
- [ ] Roles y permisos (admin, operador, lector)
- [ ] SLA monitoring
- [ ] Multi-región (desplegar en diferentes datacenters)
- [ ] White-label (cada cliente ve su propia marca)

## Ideas a futuro
- [ ] Agente compartido multi-cliente (resuelve tickets similares)
- [ ] Fine-tuning con datos del cliente
- [ ] On-premise deploy (Docker offline)
- [ ] Integración con WhatsApp Business API
- [ ] Centro de ayuda / FAQ autogenerado
