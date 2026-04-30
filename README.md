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
| `installer/` | Wizard de instalación interactivo (bash + Windows .exe via Inno Setup) |
| `installer/openclaw-enterprise.iss` | Script de Inno Setup para compilar el instalador .exe |
| `installer/EULA.txt` | Contrato de licencia que se muestra en el instalador |
| `platform/manager/` | CLI para gestionar clientes (crear, listar, eliminar) |
| `platform/docker/` | Dockerfiles y docker-compose |
| `platform/web/` | Dashboard web de administración |
| `skills-pack/` | Skills empaquetados y templates (incluye Guardrail 🛡️) |
| `docs/` | Documentación del producto |

## Instalación

### Linux (recomendado para servidores)

```bash
bash <(curl -s https://raw.githubusercontent.com/Lohio/openclaw-enterprise/main/bootstrap.sh)
```

O descargar y ejecutar:

```bash
git clone https://github.com/Lohio/openclaw-enterprise.git
cd openclaw-enterprise
./installer/install.sh
```

### Windows

1. Descargá Inno Setup: https://jrsoftware.org/isdl.php
2. Cloná el repo: `git clone https://github.com/Lohio/openclaw-enterprise.git`
3. Abrí `installer/openclaw-enterprise.iss` en Inno Setup
4. Click en **Build → Compile**
5. El `.exe` se genera en `installer/Output/`
6. Ejecutalo como administrador en la PC destino

> **Nota:** En Windows se requiere Node.js (se descarga automáticamente).
> El instalador despliega icono en el escritorio + menú inicio + desinstalador.

## 🛡️ Guardrail de Seguridad

El Guardrail es un skill que se instala **siempre** y protege al usuario:

- ✅ **Acciones seguras** (leer, buscar, consultar) → pasan sin preguntar
- ⚠️ **Acciones peligrosas** (borrar, modificar, ejecutar comandos) → pide confirmación
- ⏰ **Timeout de 60 segundos** → si no respondés, se cancela automáticamente
- 🔒 **Protección de datos sensibles** → bloquea contraseñas, tokens, DNI, tarjetas

## Licencia

**Proyecto**: MIT (basado en OpenClaw MIT License)
**Skills personalizados**: Propietarios, incluidos con el producto
**EULA**: Ver `installer/EULA.txt` — DByte no se responsabiliza por datos sensibles

---

*Powered by [OpenClaw](https://github.com/openclaw/openclaw) - MIT License*
*Distribuido por DByte*
