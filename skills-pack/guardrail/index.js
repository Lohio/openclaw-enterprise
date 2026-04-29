/**
 * 🛡️ Guardrail — Skill de Seguridad para OpenClaw Enterprise
 *
 * Se ejecuta como interceptor ANTES de que cualquier otra herramienta actúe.
 * Detecta operaciones peligrosas y pide confirmación al usuario.
 *
 * Distribuido por DByte
 */

const DANGEROUS_KEYWORDS = [
  // Archivos
  'delete', 'remove', 'rm', 'unlink', 'truncate',
  'write', 'overwrite', 'replace', 'modificar', 'borrar',
  'eliminar', 'sobrescribir',
  // Shell / comandos
  'exec', 'spawn', 'shell', 'bash', 'sh ', 'sudo',
  'chmod', 'chown', 'dd ', 'format', 'mkfs',
  // Red
  'ddos', 'attack', 'flood', 'scan', 'nmap',
  // Base de datos peligroso
  'drop table', 'drop database', 'truncate table',
  'delete from', 'alter table',
  // Datos sensibles
  'password', 'contraseña', 'token', 'apikey', 'api_key',
  'secret', 'credential', 'dni', 'cuil', 'tarjeta',
  'credit card', 'cvv', 'ssn',
];

const READONLY_KEYWORDS = [
  'read', 'list', 'get', 'search', 'find', 'query',
  'leer', 'listar', 'buscar', 'consultar',
  'cat ', 'ls ', 'tail ', 'head ', 'grep ',
  'select ', 'show ',
];

/**
 * Determina si una acción es peligrosa basado en los parámetros
 */
function isDangerous(toolName, params) {
  const textToCheck = [
    toolName.toLowerCase(),
    ...Object.values(params || {}).filter(v => typeof v === 'string').map(v => v.toLowerCase()),
  ].join(' ');

  for (const kw of DANGEROUS_KEYWORDS) {
    if (textToCheck.includes(kw)) return true;
  }
  return false;
}

/**
 * Determina si una acción es de solo lectura (segura sin confirmar)
 */
function isReadOnly(toolName, params) {
  const textToCheck = [
    toolName.toLowerCase(),
    ...Object.values(params || {}).filter(v => typeof v === 'string').map(v => v.toLowerCase()),
  ].join(' ');

  for (const kw of READONLY_KEYWORDS) {
    if (textToCheck.includes(kw)) return true;
  }
  return false;
}

/**
 * Función principal: se ejecuta antes de cada herramienta
 */
async function guardrailInterceptor(ctx, next) {
  const { toolName, params } = ctx;

  // Siempre permitir herramientas del sistema y del propio guardrail
  if (toolName === 'guardrail' || toolName.startsWith('_')) {
    return next(ctx);
  }

  // Si es solo lectura → pasar sin preguntar
  if (isReadOnly(toolName, params)) {
    return next(ctx);
  }

  // Si es peligroso → pedir confirmación
  if (isDangerous(toolName, params)) {
    const confirmMsg = [
      `⚠️ **Acción peligrosa detectada**`,
      ``,
      `Herramienta: \`${toolName}\``,
      params?.path ? `Archivo: \`${params.path}\`` : '',
      params?.command ? `Comando: \`${params.command}\`` : '',
      params?.query ? `Query: \`${params.query}\`` : '',
      ``,
      `**¿Estás seguro de querer continuar?**`,
      `Respondé "**si**" para confirmar o "**no**" para cancelar.`,
      `_(Timeout: 60 segundos. Si no respondés, se cancela automáticamente)_`,
    ].filter(Boolean).join('\n');

    await ctx.sendMessage(confirmMsg);

    try {
      const respuesta = await ctx.waitForReply({ timeout: 60000 });

      if (respuesta.toLowerCase().startsWith('s')) {
        await ctx.sendMessage('✅ Confirmado. Ejecutando...');
        return next(ctx);
      } else {
        await ctx.sendMessage('🛑 Acción cancelada por el usuario.');
        return { cancelled: true, reason: 'Usuario canceló' };
      }
    } catch (err) {
      // Timeout
      await ctx.sendMessage('⏰ Tiempo de espera agotado. Acción cancelada por seguridad.');
      return { cancelled: true, reason: 'Timeout' };
    }
  }

  // Acción no clasificada como peligrosa ni de solo lectura
  // Por seguridad, también pedimos confirmación
  const confirmMsg = [
    `🤔 **¿Querés que ejecute esta acción?**`,
    ``,
    `Herramienta: \`${toolName}\``,
    ``,
    `Respondé "**si**" para continuar o "**no**" para cancelar.`,
  ].filter(Boolean).join('\n');

  await ctx.sendMessage(confirmMsg);

  try {
    const respuesta = await ctx.waitForReply({ timeout: 60000 });
    if (respuesta.toLowerCase().startsWith('s')) {
      return next(ctx);
    } else {
      await ctx.sendMessage('🛑 Acción cancelada.');
      return { cancelled: true, reason: 'Usuario canceló' };
    }
  } catch (err) {
    await ctx.sendMessage('⏰ Tiempo agotado. Acción cancelada.');
    return { cancelled: true, reason: 'Timeout' };
  }
}

module.exports = {
  name: 'guardrail',
  description: '🛡️ Guardrail de seguridad — Siempre pide confirmación antes de acciones peligrosas',
  version: '1.0.0',
  author: 'DByte',
  hooks: {
    beforeTool: guardrailInterceptor,
  },
  tools: [
    {
      name: 'guardrail_status',
      description: 'Muestra el estado actual del guardrail de seguridad',
      handler: async () => {
        return {
          active: true,
          dangerous_keywords: DANGEROUS_KEYWORDS.length,
          readonly_keywords: READONLY_KEYWORDS.length,
          timeout_seconds: 60,
          version: '1.0.0',
        };
      },
    },
    {
      name: 'guardrail_help',
      description: 'Explica cómo funciona el guardrail de seguridad',
      handler: async () => {
        return {
          message: `🛡️ **Guardrail de Seguridad**

El Guardrail protege tus datos interceptando cualquier operación potencialmente peligrosa antes de ejecutarse.

**¿Qué protege?**
- Borrado o modificación de archivos
- Ejecución de comandos del sistema
- Consultas destructivas a bases de datos
- Envío de datos sensibles
- Acceso a contraseñas, tokens o información personal

**¿Cómo funciona?**
1. Detecta la acción que querés ejecutar
2. Si es peligrosa → te pregunta "¿Estás seguro?"
3. Respondés "si" o "no"
4. Si no respondés en 60 segundos → se cancela automáticamente

**Acciones seguras (no preguntan):**
Lectura de archivos, búsquedas web, consultas SELECT, etc.

Si querés desactivar temporalmente el guardrail, decí "modo confianza" al asistente.`,
        };
      },
    },
  ],
};
