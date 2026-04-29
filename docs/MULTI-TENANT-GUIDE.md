# 🏢 OpenClaw Enterprise - Guía Multi-Tenant

## ¿Dónde corre OpenClaw?

OpenClaw Enterprise corre sobre **cualquier servidor Linux**:

| Proveedor | Plan mínimo | Costo aprox. |
|-----------|-------------|:------------:|
| DigitalOcean | Droplet básico (1 CPU, 2GB RAM) | ~$6/mes |
| Hetzner | CX22 (2 CPUs, 4GB RAM) | ~$4/mes |
| Linode | Nanode 1GB (1 CPU, 1GB RAM) | ~$5/mes |
| Vultr | 1 CPU, 2GB RAM | ~$6/mes |
| AWS EC2 | t3.small (2 CPUs, 2GB RAM) | ~$20/mes |
| Servidor propio | Cualquier PC con Linux | Solo electricidad |

### Requisitos del sistema

- **Sistema operativo**: Ubuntu 22.04 o 24.04 (recomendado), Debian 12
- **Arquitectura**: x86_64 (AMD/Intel)
- **RAM**: 2 GB mínimo (4 GB recomendado para multi-cliente)
- **Disco**: 20 GB mínimo
- **Conexión**: Internet (para la API del LLM y actualizaciones)
- **No necesita**: interfaz gráfica, monitor, teclado

### Diagrama de infraestructura

```
┌──────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└──────────┬─────────────────────┬─────────────────────────────┘
           │                     │
    ┌──────▼──────┐      ┌──────▼──────┐
    │ Cliente A   │      │ Cliente B   │
    │ (Telegram)  │      │ (WhatsApp)  │
    └──────┬──────┘      └──────┬──────┘
           │                     │
    ┌──────┴─────────────────────┴─────────────────────────┐
    │                 Caddy Proxy Reverso                  │
    │           (SSL automático con Let's Encrypt)          │
    └──────┬─────────────────────┬─────────────────────────┘
           │                     │
    ┌──────▼─────────┐    ┌──────▼─────────┐
    │ Docker:        │    │ Docker:        │
    │ openclaw-A     │    │ openclaw-B     │
    │ Puerto :3001   │    │ Puerto :3002   │
    │ API Key: sk-xxx│    │ API Key: sk-yyy│
    │ Workspace A/   │    │ Workspace B/   │
    │ Modelo: GPT-4o │    │ Modelo: Claude │
    └────────────────┘    └────────────────┘
```

Cada recuadro Docker es una instalación COMPLETAMENTE INDEPENDIENTE.

---

## Escenario 1: Una sola empresa, varios usuarios

**Caso**: Tenés una PyME con 5 empleados. Instalás OpenClaw UNA VEZ y todos se conectan al mismo asistente.

```
┌──────────────────────┐
│     Servidor VPS     │
│   OpenClaw Single    │
└────────┬─────────────┘
         │
    ┌────┴────┐
    │Telegram │
    │Bot      │
    └────┬────┘
         │
    ┌────┴──────────────────┐
    │ Juan  │ María │ Pedro │
    │ (todos en el mismo   │
    │  grupo/canal)         │
    └───────────────────────┘
```

**Configuración**: Instalás con modo "Single", conectás un bot de Telegram, y agregás a todos los del equipo al grupo. Todos hablan con el mismo asistente.

**⚠️ Limitación**: Comparten workspace, memoria y skills. Si Juan pide "resumí las ventas de ayer", María ve ese mismo resumen.

---

## Escenario 2: Revender a múltiples clientes (Multi-Tenant)

**Caso**: Querés que la Empresa X, Empresa Y y Empresa Z tengan CADA UNA su propio asistente independiente.

```
┌────────────────────────────────────────────────────┐
│              VPS GRANDE (8GB RAM, 4 CPU)           │
│              Alquilado por VOS (dbyte)             │
│                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ Docker:     │  │ Docker:     │  │ Docker:    │ │
│  │ Empresa X  │  │ Empresa Y  │  │ Empresa Z │ │
│  │ :3001      │  │ :3002      │  │ :3003     │ │
│  │ GPT-4o     │  │ Claude     │  │ Gemini    │ │
│  │ API Key X  │  │ API Key Y  │  │ API Key Z │ │
│  │ Wsp X      │  │ TG Y       │  │ TG Z+Wsp  │ │
│  └─────┬──────┘  └─────┬──────┘  └─────┬─────┘ │
│        │               │                │        │
│  ┌─────┴───────────────┴────────────────┴──┐    │
│  │          Caddy Proxy Reverso            │    │
│  │   emp-x.midominio.com → :3001          │    │
│  │   emp-y.midominio.com → :3002          │    │
│  │   emp-z.midominio.com → :3003          │    │
│  └────────────────┬────────────────────────┘    │
└───────────────────┼─────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
    emp-x.midominio.com   emp-y.midominio.com
    (habla Laura de X)    (habla Carlos de Y)
```

### Cómo se administra

Con el CLI `openclaw-manager.sh`:

```bash
# Dar de alta un cliente nuevo
./openclaw-manager.sh crear cliente-nuevo \
  --llm-key sk-pro-xxx \
  --provider openai \
  --model gpt-4o \
  --puerto 3004 \
  --dominio cliente-nuevo.midominio.com

# Ver todos los clientes activos
./openclaw-manager.sh list

# Resultado:
# CLIENTE         PUERTO  PROVEEDOR  MODELO   ESTADO
# empresa-x       3001    openai     gpt-4o   running
# empresa-y       3002    anthropic  claude   running
# empresa-z       3003    google     gemini   running

# Ver logs de un cliente en vivo
./openclaw-manager.sh logs empresa-x -f

# Backup de un cliente (config + datos)
./openclaw-manager.sh backup empresa-x
# → backup/empresa-x-20260429_120000.tar.gz

# Eliminar un cliente (con confirmación)
./openclaw-manager.sh eliminar empresa-z
```

### Modelo de negocio

Como revendedor (dbyte):

| Concepto | Detalle |
|----------|---------|
| **Tu inversión** | 1 VPS de ~$20-40/mes |
| **Tu trabajo** | Correr `openclaw-manager.sh crear` por cada cliente |
| **Lo que cobrás** | $50-200/mes por cliente (según skills y soporte) |
| **Margen** | Si tenés 10 clientes a $100 = $1000/mes, gasto $40 = **96% margen** |

Cada cliente es 100% independiente:
- ✅ No ven los datos del otro
- ✅ Cada uno tiene su propia API key (o puede ser la tuya)
- ✅ Cada uno elige su LLM (OpenAI, Anthropic, Google, DeepSeek)
- ✅ Cada uno tiene sus propios canales (Telegram, WhatsApp, Slack)
- ✅ Si un cliente se cae, el resto sigue funcionando
- ✅ Podés migrar un cliente a otro servidor sin afectar a nadie

---

## Preguntas frecuentes

### ¿Puedo instalar en Windows?
No recomendado. OpenClaw corre sobre Node.js y Docker. En Windows se puede con WSL2 pero no para producción.

### ¿Necesito dominio propio?
Para probar, no. Para producción con varios clientes, sí (para SSL y acceso web).

### ¿Cada cliente necesita su propia API key?
No es obligatorio. Podés usar una key tuya y prorratear el costo, o que cada cliente ponga la suya. El instalador pregunta esto.

### ¿Qué pasa si un cliente usa muchos tokens?
Cada contenedor es independiente, así que podés monitorear el uso por separado. Está en el roadmap agregar alertas de gasto.

### ¿Puedo migrar un cliente a otro servidor?
Sí. Con `openclaw-manager.sh backup` generás un tar.gz con toda su configuración y workspace. Lo descomprimís en el nuevo server y levantás el contenedor.

### ¿Escala para 100 clientes?
Técnicamente sí (cada cliente = 1 contenedor Docker), pero necesitarías un servidor grande. Para 100+ clientes se recomienda usar Kubernetes u orquestación multi-server.
