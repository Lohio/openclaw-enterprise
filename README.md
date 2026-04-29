# 🦞 OpenClaw Enterprise

**Plataforma multi-tenant de asistentes AI empacada para empresas.**

Instalación con wizard, skills preconfigurados, y orquestación Docker para manejar decenas de clientes desde un mismo servidor.

## Arquitectura

```
[Caddy / nginx proxy reverso]
    ├── cliente-1.miweb.io → Docker: openclaw-cliente-1:3000
    ├── cliente-2.miweb.io → Docker: openclaw-cliente-2:3000
    ├── ...
    └── admin.miweb.io → Dashboard de administración
```

Cada cliente corre su propia instancia OpenClaw completamente aislada:
- Config propia (`openclaw.json`)
- Workspace propio
- Skills autorizados
- Su propia API key de LLM
- Base de datos de memoria independiente

## Componentes

| Componente | Descripción |
|------------|-------------|
| `installer/` | Wizard de instalación interactivo (bash + node) |
| `platform/manager/` | CLI para gestionar clientes (crear, listar, eliminar) |
| `platform/docker/` | Dockerfiles y docker-compose |
| `platform/web/` | Dashboard web de administración |
| `skills-pack/` | Skills empaquetados y templates |
| `docs/` | Documentación del producto |

## Instalación Rápida

```bash
curl -fsSL https://raw.githubusercontent.com/tuusuario/openclaw-enterprise/main/installer/install.sh | bash
```

O descargar y ejecutar:

```bash
git clone https://github.com/tuusuario/openclaw-enterprise.git
cd openclaw-enterprise
./installer/install.sh
```

## Licencia

**Proyecto**: MIT (basado en OpenClaw MIT License)
**Skills personalizados**: Propietarios, incluidos con el producto

---

*Powered by [OpenClaw](https://github.com/openclaw/openclaw) - MIT License*
