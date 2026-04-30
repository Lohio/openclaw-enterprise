; ═════════════════════════════════════════════════════════════
; OpenClaw Enterprise - Inno Setup Script
; Genera un instalador .exe profesional para Windows
;
; Cómo usarlo:
;   1. Descargá e instalá Inno Setup: https://jrsoftware.org/isdl.php
;   2. Abrí este archivo en Inno Setup
;   3. Click en Build → Compile
;   4. El .exe se genera en la carpeta Output/
;
; Distribuido por DByte
; ═════════════════════════════════════════════════════════════

#define MyAppName "OpenClaw Enterprise"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DByte"
#define MyAppURL "https://github.com/Lohio/openclaw-enterprise"
#define MyAppExeName "openclaw-config-gui.exe"

[Setup]
; Metadatos
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Directorio por defecto
DefaultDirName=C:\OpenClawEnterprise
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

; Archivo de salida
OutputDir=.\Output
OutputBaseFilename=openclaw-enterprise-setup-{#MyAppVersion}

; Configuración del instalador
SetupIconFile=.\installer\icon.ico
UninstallDisplayIcon={app}\icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

; EULA obligatorio
LicenseFile=.\installer\EULA.txt

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
; Personalizar textos del wizard
Spanish.SetupAppTitle=OpenClaw Enterprise - Instalador
Spanish.WelcomeLabel2=Este asistente lo guiará en la instalación de OpenClaw Enterprise en su sistema.
Spanish.LicenseLabel=Contrato de Licencia y Términos de Uso
Spanish.LicenseLabel3=Por favor, lea los siguientes términos antes de continuar.
Spanish.LicenseAccepted=He leído y acepto los términos
Spanish.LicenseNotAccepted=Debe aceptar los términos para continuar.

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"
Name: "quicklaunchicon"; Description: "Crear acceso directo en inicio rápido"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Files]
; ─── Node.js portable ───
Source: ".\deps\nodejs\node.exe"; DestDir: "{app}\deps\nodejs"; Flags: ignoreversion
Source: ".\deps\nodejs\*"; DestDir: "{app}\deps\nodejs"; Flags: ignoreversion recursesubdirs createallsubdirs

; ─── OpenClaw CLI ───
Source: ".\deps\openclaw\*"; DestDir: "{app}\deps\openclaw"; Flags: ignoreversion recursesubdirs createallsubdirs

; ─── ClawHub CLI ───
Source: ".\deps\clawhub\*"; DestDir: "{app}\deps\clawhub"; Flags: ignoreversion recursesubdirs createallsubdirs

; ─── Skills pack (incluye guardrail) ───
Source: ".\skills-pack\*"; DestDir: "{app}\skills-pack"; Flags: ignoreversion recursesubdirs createallsubdirs

; ─── Configurador GUI ───
Source: ".\installer\openclaw-config-gui.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\installer\openclaw-config-gui.exe.config"; DestDir: "{app}"; Flags: ignoreversion

; ─── Icono ───
Source: ".\installer\icon.ico"; DestDir: "{app}"; Flags: ignoreversion

; ─── Scripts auxiliares ───
Source: ".\installer\start-openclaw.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\installer\stop-openclaw.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\installer\openclaw-manager.bat"; DestDir: "{app}"; Flags: ignoreversion

; ─── Documentación ───
Source: ".\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs

; ─── Términos legales ───
Source: ".\installer\TERMS_OF_SERVICE.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Acceso directo en el escritorio
Name: "{commondesktop}\OpenClaw Enterprise"; Filename: "{app}\openclaw-config-gui.exe"; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\icon.ico"

; Acceso directo en menú inicio
Name: "{group}\OpenClaw Enterprise"; Filename: "{app}\openclaw-config-gui.exe"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\Documentación"; Filename: "{app}\docs\README.md"; WorkingDir: "{app}"
Name: "{group}\Términos de Servicio"; Filename: "{app}\TERMS_OF_SERVICE.md"; WorkingDir: "{app}"
Name: "{group}\Desinstalar OpenClaw Enterprise"; Filename: "{uninstallexe}"; WorkingDir: "{app}"

; Acceso directo en inicio rápido
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\OpenClaw Enterprise"; Filename: "{app}\openclaw-config-gui.exe"; WorkingDir: "{app}"; Tasks: quicklaunchicon

[Run]
; Abrir el configurador después de la instalación
Filename: "{app}\openclaw-config-gui.exe"; Description: "Abrir OpenClaw Enterprise Configurador"; Flags: postinstall nowait skipifsilent shellexec

[UninstallRun]
; Detener OpenClaw si está corriendo
Filename: "{app}\stop-openclaw.bat"; Flags: runhidden

[Code]

// ───────────────────────────────────────
// Variables globales
// ───────────────────────────────────────

var
  // Páginas personalizadas
  LLMPage: TInputQueryWizardPage;
  GatewayPage: TInputQueryWizardPage;
  SkillsPage: TInputQueryWizardPage;
  CustomPage: TOutputMsgWizardPage;

  // Estado
  LLMProvider: String;
  LLMApiKey: String;
  LLMModel: String;
  GatewayPort: String;
  GatewayPassword: String;
  SelectedSkills: String;

  // Radio buttons para el proveedor
  rbOpenAI: TNewRadioButton;
  rbAnthropic: TNewRadioButton;
  rbGoogle: TNewRadioButton;
  rbDeepSeek: TNewRadioButton;
  rbCustom: TNewRadioButton;

  // Checkboxes para skills
  SkillsCheckboxes: array of TNewCheckListBox;
  SkillNames: array of String;

// ───────────────────────────────────────
// Inicialización
// ───────────────────────────────────────

procedure InitializeWizard;
begin
  // ─── Página 1: Bienvenida personalizada ───
  CustomPage := CreateOutputMsgPage(
    wpLicense,
    'OpenClaw Enterprise v1.0.0',
    'Asistente AI multi-plataforma',
    'Distribuido por DByte'#13#10 +
    ''#13#10 +
    'Este asistente lo guiará para configurar:'#13#10 +
    '• Conexión con su proveedor de IA preferido'#13#10 +
    '• Puertos y seguridad del gateway'#13#10 +
    '• Skills a instalar (incluye Guardrail de seguridad)'#13#10 +
    #13#10 +
    'Al finalizar, se creará un acceso directo en el escritorio.'
  );

  // ─── Página 2: Selección de LLM ───
  LLMPage := CreateInputQueryPage(
    wpSelectTasks,
    'Configuración del Proveedor de IA',
    'Seleccioná el motor de IA que usará tu asistente',
    'Necesitás una API Key del proveedor que elijas. No compartas esta clave con nadie.'
  );

  // Radio buttons para proveedores
  rbOpenAI := TNewRadioButton.Create(LLMPage);
  rbOpenAI.Parent := LLMPage.Surface;
  rbOpenAI.Caption := 'OpenAI (GPT-4o, GPT-4, GPT-3.5)';
  rbOpenAI.Top := 16;
  rbOpenAI.Left := 8;
  rbOpenAI.Width := 400;
  rbOpenAI.Checked := True;

  rbAnthropic := TNewRadioButton.Create(LLMPage);
  rbAnthropic.Parent := LLMPage.Surface;
  rbAnthropic.Caption := 'Anthropic (Claude 3.5 Sonnet, Haiku)';
  rbAnthropic.Top := rbOpenAI.Top + 24;
  rbAnthropic.Left := 8;
  rbAnthropic.Width := 400;

  rbGoogle := TNewRadioButton.Create(LLMPage);
  rbGoogle.Parent := LLMPage.Surface;
  rbGoogle.Caption := 'Google (Gemini 2.0 Pro, Flash)';
  rbGoogle.Top := rbAnthropic.Top + 24;
  rbGoogle.Left := 8;
  rbGoogle.Width := 400;

  rbDeepSeek := TNewRadioButton.Create(LLMPage);
  rbDeepSeek.Parent := LLMPage.Surface;
  rbDeepSeek.Caption := 'DeepSeek (V3, R1)';
  rbDeepSeek.Top := rbGoogle.Top + 24;
  rbDeepSeek.Left := 8;
  rbDeepSeek.Width := 400;

  rbCustom := TNewRadioButton.Create(LLMPage);
  rbCustom.Parent := LLMPage.Surface;
  rbCustom.Caption := 'Otro / API personalizada';
  rbCustom.Top := rbDeepSeek.Top + 24;
  rbCustom.Left := 8;
  rbCustom.Width := 400;

  // Campos de texto
  LLMPage.Add('API Key:', False);
  LLMPage.Add('Modelo (ej: gpt-4o):', False);
  LLMPage.Edits[0].Top := rbCustom.Top + 40;
  LLMPage.Edits[1].Top := LLMPage.Edits[0].Top + 32;

  // ─── Página 3: Gateway ───
  GatewayPage := CreateInputQueryPage(
    LLMPage.ID,
    'Configuración del Gateway',
    'Puerto y acceso al servidor OpenClaw',
    'El Gateway es el servidor que recibe y procesa los mensajes de tus canales (Telegram, WhatsApp, etc.).'
  );

  GatewayPage.Add('Puerto del Gateway (por defecto 3000):', False);
  GatewayPage.Add('Contraseña de administrador (opcional):', True);
  GatewayPage.Edits[0].Text := '3000';

  // ─── Página 4: Skills ───
  SkillsPage := CreateInputQueryPage(
    GatewayPage.ID,
    'Selección de Skills',
    'Elegí qué habilidades querés que tenga tu asistente',
    'Los skills son extensiones que le dan capacidades específicas a tu asistente. El Guardrail de seguridad se instala automáticamente.'
  );
end;

// ───────────────────────────────────────
// Validación de datos
// ───────────────────────────────────────

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = LLMPage.ID then
  begin
    // Validar que la API Key no esté vacía
    if Trim(LLMPage.Edits[0].Text) = '' then
    begin
      MsgBox('La API Key no puede estar vacía. Ingresá la clave de tu proveedor.', mbError, MB_OK);
      Result := False;
      Exit;
    end;

    // Guardar valores seleccionados
    if rbOpenAI.Checked then
      LLMProvider := 'openai'
    else if rbAnthropic.Checked then
      LLMProvider := 'anthropic'
    else if rbGoogle.Checked then
      LLMProvider := 'google'
    else if rbDeepSeek.Checked then
      LLMProvider := 'deepseek'
    else
      LLMProvider := 'custom';

    LLMApiKey := Trim(LLMPage.Edits[0].Text);
    LLMModel := Trim(LLMPage.Edits[1].Text);

    // Si no especificó modelo, usar default por proveedor
    if LLMModel = '' then
    begin
      case LLMProvider of
        'openai': LLMModel := 'gpt-4o';
        'anthropic': LLMModel := 'claude-sonnet-4-20250514';
        'google': LLMModel := 'gemini-2.0-flash-001';
        'deepseek': LLMModel := 'deepseek-chat';
        else LLMModel := 'gpt-4o';
      end;
    end;
  end;

  if CurPageID = GatewayPage.ID then
  begin
    GatewayPort := Trim(GatewayPage.Edits[0].Text);
    GatewayPassword := Trim(GatewayPage.Edits[1].Text);

    // Validar puerto
    if GatewayPort = '' then
      GatewayPort := '3000';
  end;

  if CurPageID = SkillsPage.ID then
  begin
    SelectedSkills := 'guardrail'; // Siempre instalado
  end;
end;

// ───────────────────────────────────────
// Instalación personalizada
// ───────────────────────────────────────

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigPath: String;
  ConfigContent: String;
  WorkspacePath: String;
  GuardrailPath: String;
  SkillsDir: String;
begin
  if CurStep = ssPostinstall then
  begin
    // ─── Crear directorio workspace ───
    WorkspacePath := ExpandConstant('{app}\workspace');
    CreateDir(WorkspacePath);
    CreateDir(WorkspacePath + '\skills');

    // ─── Copiar Guardrail al workspace ───
    GuardrailPath := WorkspacePath + '\skills\guardrail';
    CreateDir(GuardrailPath);
    FileCopy(ExpandConstant('{app}\skills-pack\guardrail\SKILL.md'), GuardrailPath + '\SKILL.md', False);
    FileCopy(ExpandConstant('{app}\skills-pack\guardrail\index.js'), GuardrailPath + '\index.js', False);

    // ─── Copiar skills seleccionados ───
    SkillsDir := ExpandConstant('{app}\skills-pack');
    // (En una versión completa, copiaría los skills de ClawHub descargados)

    // ─── Generar openclaw.json ───
    ConfigPath := ExpandConstant('{app}\openclaw.json');
    ConfigContent :=
      '{' + #13#10 +
      '  // OpenClaw Enterprise v1.0.0 — Generado por el instalador' + #13#10 +
      '  // Distribuido por DByte — https://github.com/Lohio/openclaw-enterprise' + #13#10 +
      '  models: {' + #13#10 +
      '    providers: {' + #13#10 +
      '      "' + LLMProvider + '": {' + #13#10 +
      '        apiKey: "' + LLMApiKey + '",' + #13#10 +
      '      },' + #13#10 +
      '    },' + #13#10 +
      '    defaultModel: {' + #13#10 +
      '      provider: "' + LLMProvider + '",' + #13#10 +
      '      model: "' + LLMModel + '",' + #13#10 +
      '    },' + #13#10 +
      '  },' + #13#10 +
      '  gateway: {' + #13#10 +
      '    port: ' + GatewayPort + ',' + #13#10';

    if GatewayPassword <> '' then
      ConfigContent := ConfigContent +
      '    password: "' + GatewayPassword + '",' + #13#10';

    ConfigContent := ConfigContent +
      '  },' + #13#10 +
      '  agents: {' + #13#10 +
      '    defaults: {' + #13#10 +
      '      workspace: "' + ExpandConstant('{app}') + '\\workspace",' + #13#10 +
      '      skills: ["guardrail"],' + #13#10 +
      '    },' + #13#10 +
      '  },' + #13#10 +
      '}' + #13#10;

    SaveStringToFile(ConfigPath, ConfigContent, False);

    // ─── Guardar aceptación de términos ───
    SaveStringToFile(
      ExpandConstant('{app}\.terms_accepted'),
      'Aceptado el ' + GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':') + ' vía instalador Windows',
      False
    );
  end;
end;

// ───────────────────────────────────────
// Desinstalación
// ───────────────────────────────────────

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Preguntar si quiere eliminar configuración
    if MsgBox('¿Querés eliminar también los archivos de configuración y workspace? (recomendado si no vas a reinstalar)', mbConfirmation, MB_YESNO) = IDYES then
    begin
      DelTree(ExpandConstant('{app}'), True, True, True);
    end;
  end;
end;

[CustomMessages]
Spanish.WelcomeLabel2=OpenClaw Enterprise v1.0.0
Spanish.SelectTasksDesc=Configurá los accesos directos
Spanish.SelectDirDesc=¿Dónde querés instalar OpenClaw Enterprise?
Spanish.SelectDirLabel3=El instalador colocará los archivos en la siguiente carpeta.

[UninstallDelete]
Type: filesifempty; Name: "{app}\workspace\*"
Type: dirifempty; Name: "{app}\workspace"
Type: filesifempty; Name: "{app}\logs\*"
Type: dirifempty; Name: "{app}\logs"
