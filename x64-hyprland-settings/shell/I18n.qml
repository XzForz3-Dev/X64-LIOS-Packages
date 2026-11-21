pragma Singleton
import QtQuick
import Quickshell

// =============================================================================
// X64 LIOS - Native Desktop Internationalization Layer (I18n.qml)
// Detects system language from $LANG / $LC_ALL / QLocale.
// Standard International English is default for all worldwide installations;
// Spanish is automatically enabled when system locale starts with "es".
// =============================================================================
QtObject {
    id: i18n

    readonly property string langEnv: {
        var envVal = Quickshell.env("LANG") || Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || "";
        if (envVal.length === 0) {
            try {
                envVal = Qt.locale().name || "en_US";
            } catch (e) {
                envVal = "en_US";
            }
        }
        return envVal.toLowerCase();
    }

    readonly property bool isEs: langEnv.indexOf("es") === 0

    // -------------------------------------------------------------------------
    // 1. TOP BAR & CALENDAR DATES
    // -------------------------------------------------------------------------
    readonly property var dayShortNames: isEs 
        ? ["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"]
        : ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    readonly property var monthShortNames: isEs
        ? ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"]
        : ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    readonly property var dayFullNames: isEs
        ? ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
        : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    readonly property var monthFullNames: isEs
        ? ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
        : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    readonly property var calWeekHeaders: isEs
        ? ["L", "M", "X", "J", "V", "S", "D"]
        : ["M", "T", "W", "T", "F", "S", "S"]

    readonly property string calTodayPill: isEs ? "HOY" : "TODAY"

    // -------------------------------------------------------------------------
    // 2. CONTROL CENTER
    // -------------------------------------------------------------------------
    readonly property string controlCenterTitle: isEs ? "CENTRO DE CONTROL" : "CONTROL CENTER"
    readonly property string caffeine: isEs ? "Modo Café" : "Caffeine"
    readonly property string nightLight: isEs ? "Luz Noche" : "Night Light"
    readonly property string dnd: isEs ? "No Molestar" : "Do Not Disturb"

    // Screen Capture & Recording Row
    readonly property string crop: isEs ? "Recortar" : "Crop"
    readonly property string screen: isEs ? "Pantalla" : "Screen"
    readonly property string record: isEs ? "Grabar" : "Record"
    readonly property string recordStop: isEs ? "Fin " : "Stop "
    readonly property string scopeFullscreen: isEs ? "󰍹 Pantalla Completa" : "󰍹 Fullscreen"
    readonly property string scopeRegion: isEs ? "󰆞 Seleccionar Región" : "󰆞 Select Region"
    readonly property string audioNone: isEs ? "󰝟 Sin Audio" : "󰝟 No Audio"
    readonly property string audioDesktop: isEs ? "󰕾 Audio PC" : "󰕾 Desktop Audio"
    readonly property string audioBoth: isEs ? "󰍬 PC + Mic" : "󰍬 Desktop + Mic"
    readonly property string startRecordingNow: isEs ? "Iniciar Grabación Ahora" : "Start Recording Now"

    // Quick App Tiles
    readonly property string termKitty: isEs ? "Terminal Kitty" : "Kitty Terminal"
    readonly property string filesDolphin: isEs ? "Archivos" : "Files"
    readonly property string x64Hello: "X64 Hello"
    readonly property string monitorBtop: isEs ? "Monitor Btop" : "Btop Monitor"

    // Sliders
    readonly property string masterVolume: isEs ? "󰕾 Volumen Principal" : "󰕾 Master Volume"
    readonly property string audioMuted: isEs ? "󰝟 Audio Silenciado" : "󰝟 Audio Muted"
    readonly property string displayBrightness: isEs ? "󰃠 Brillo de Pantalla" : "󰃠 Display Brightness"

    // Power Profiles & Smart Battery
    readonly property string powerProfile: isEs ? "󰾅 Perfil de Energía" : "󰾅 Power Profile"
    readonly property string acDirect: isEs ? "󰚥 AC Directo" : "󰚥 Direct AC"
    readonly property string profilePerformance: isEs ? "󰓅 Rendimiento" : "󰓅 Performance"
    readonly property string profileBalanced: isEs ? "󰾅 Equilibrado" : "󰾅 Balanced"
    readonly property string profilePowerSaver: isEs ? "󰌪 Ahorro" : "󰌪 Power Saver"

    // Display & Monitor Scaling
    readonly property string displayScaling: isEs ? "󰍹 Pantalla & Escalado" : "󰍹 Display & Scaling"

    // Power Actions
    readonly property string lock: isEs ? "Bloquear" : "Lock"
    readonly property string reboot: isEs ? "Reiniciar" : "Restart"
    readonly property string powerOff: isEs ? "Apagar" : "Shut Down"

    // -------------------------------------------------------------------------
    // 3. LOCK SCREEN
    // -------------------------------------------------------------------------
    readonly property string lockTitle: "X64 LIOS SECURITY LOCK • EXT-SESSION-LOCK-V1"
    readonly property string lockSessionLocked: isEs ? "SESIÓN BLOQUEADA" : "SESSION LOCKED"
    readonly property string lockPasswordPrompt: isEs ? "Contraseña del sistema..." : "System password..."
    readonly property string lockStatusReady: isEs ? "Introduce tu contraseña y presiona Enter" : "Enter password and press Enter"
    readonly property string lockStatusVerifying: isEs ? "Verificando credenciales PAM..." : "Verifying PAM credentials..."
    readonly property string lockStatusError: isEs ? "Contraseña incorrecta. Inténtalo de nuevo." : "Incorrect password. Please try again."

    // -------------------------------------------------------------------------
    // 4. NETWORK & WI-FI POPUP
    // -------------------------------------------------------------------------
    readonly property string netTitle: isEs ? "󰖩 CENTRO DE RED X64" : "󰖩 X64 NETWORK CENTER"
    readonly property string netLanWired: isEs ? "Red Cableada (LAN)" : "Wired Network (LAN)"
    readonly property string netConnected: isEs ? "Conectado" : "Connected"
    readonly property string netCableDisconnected: isEs ? "Cable desconectado" : "Cable disconnected"
    readonly property string netActive: isEs ? "Activo" : "Active"
    readonly property string netConnect: isEs ? "Conectar" : "Connect"
    readonly property string netDisconnect: isEs ? "Desconectar" : "Disconnect"
    readonly property string netIpAddress: isEs ? "DIRECCIÓN IP" : "IP ADDRESS"
    readonly property string netGateway: "GATEWAY"
    readonly property string netDnsPrimary: isEs ? "DNS PRIMARIO" : "PRIMARY DNS"
    readonly property string netWireless: isEs ? "Redes Inalámbricas (Wi-Fi)" : "Wireless Networks (Wi-Fi)"
    readonly property string netEthernetOnlyNotice: isEs 
        ? "Estación conectada por Ethernet LAN directo. Si conectas un adaptador Wi-Fi USB/PCIe aparecerán aquí las redes inalámbricas."
        : "Station connected via direct Ethernet LAN. Connect a USB or PCIe Wi-Fi adapter to scan for wireless networks."
    readonly property string netWifiOffNotice: isEs
        ? "󰤮 El radio Wi-Fi está apagado. Actívalo arriba para buscar redes."
        : "󰤮 Wi-Fi radio is off. Turn it on above to scan for networks."
    readonly property string netPasswordPrompt: isEs ? "Contraseña de " : "Password for "
    readonly property string netEnter: isEs ? "Entrar" : "Enter"
    readonly property string netAdvancedSettings: isEs ? "Ajustes Avanzados de Red / VPN" : "Advanced Network / VPN Settings"

    // -------------------------------------------------------------------------
    // 5. TELEMETRY COCKPIT POPUP
    // -------------------------------------------------------------------------
    readonly property string teleTitle: isEs ? "󰻠 TELEMETRÍA X64" : "󰻠 X64 TELEMETRY"
    readonly property string teleCpu: isEs ? "󰻠 Procesador (CPU)" : "󰻠 Processor (CPU)"
    readonly property string teleRam: isEs ? "󰍛 Memoria RAM" : "󰍛 RAM Memory"
    readonly property string teleDisk: isEs ? "󰋊 Disco del Sistema (/)" : "󰋊 System Disk (/)"
    readonly property string teleNet: isEs ? "󰈀 Red" : "󰈀 Network"
    readonly property string teleAvailable: isEs ? "disponibles" : "available"
    readonly property string teleActiveProcesses: isEs ? "PROCESOS ACTIVOS (TOP RECURSOS)" : "ACTIVE PROCESSES (TOP USAGE)"
    readonly property string teleOpenBtop: isEs ? "Abrir Monitor Completo (Btop)" : "Open Full Monitor (Btop)"

    // -------------------------------------------------------------------------
    // 6. AUDIO & DEVICES POPUP
    // -------------------------------------------------------------------------
    readonly property string audioTitle: isEs ? "AUDIO Y DISPOSITIVOS" : "AUDIO & DEVICES"
    readonly property string audioTabSinks: isEs ? "Salidas" : "Outputs"
    readonly property string audioTabSources: isEs ? "Micrófono" : "Microphone"
    readonly property string audioTabStreams: isEs ? "Aplicaciones" : "Applications"
    readonly property string audioOverdrive: "Boost 150%"
    readonly property string audioOverdriveNotice: isEs ? "Sobreamplificación activa hasta 150%" : "Overamplification active up to 150%"
    readonly property string audioOutputDevice: isEs ? "Dispositivo de Salida Activo" : "Active Output Device"
    readonly property string audioInputDevice: isEs ? "Dispositivo de Entrada Activo" : "Active Input Device"
    readonly property string audioOutputDevices: isEs ? "Dispositivos de Salida Disponibles" : "Available Output Devices"
    readonly property string audioInputDevices: isEs ? "Dispositivos de Captura Disponibles" : "Available Input Devices"
    readonly property string audioAppMixer: isEs ? "Mezclador de Aplicaciones" : "Application Mixer"
    readonly property string audioNoStreams: isEs ? "No hay aplicaciones reproduciendo audio" : "No applications playing audio"
    readonly property string audioVuMeter: isEs ? "Nivel de Entrada en Vivo" : "Live Input Level"
    readonly property string audioAdvancedSettings: isEs ? "Ajustes Avanzados de Sonido" : "Advanced Audio Settings"

    // -------------------------------------------------------------------------
    // 7. NOTIFICATION CENTER & X64 GAMING TELEMETRY ENGINE
    // -------------------------------------------------------------------------
    readonly property string notifCenterTitle: isEs ? "NOTIFICACIONES" : "NOTIFICATIONS"
    readonly property string notifClearAll: isEs ? "Limpiar" : "Clear all"
    readonly property string notifEmptyTitle: isEs ? "Todo al día" : "All caught up"
    readonly property string notifEmptySub: isEs
        ? "Las notificaciones del sistema aparecerán aquí guardadas."
        : "System notifications will be archived here."
    readonly property string notifEmptyDndSub: isEs
        ? "No Molestar activo — las nuevas alertas se archivarán aquí en silencio."
        : "Do Not Disturb active — incoming alerts will be archived here silently."

    readonly property string teleX64Engine: isEs ? "MOTOR X64 GAMING" : "X64 GAMING ENGINE"
    readonly property string teleSchedSwitch: isEs ? "Cambiar" : "Switch"
    readonly property string teleSchedOpenHello: "X64 Hello"

    // -------------------------------------------------------------------------
    // 8. POWER / SESSION OVERLAY (SUPER + M & BAR POWER BUTTON)
    // -------------------------------------------------------------------------
    readonly property string powerTitle: isEs ? "SESIÓN Y ENERGÍA" : "POWER & SESSION"
    readonly property string powerLock: isEs ? "Bloquear" : "Lock"
    readonly property string powerSuspend: isEs ? "Suspender" : "Suspend"
    readonly property string powerLogout: isEs ? "Cerrar sesión" : "Log Out"
    readonly property string powerReboot: isEs ? "Reiniciar" : "Reboot"
    readonly property string powerUefi: "BIOS / UEFI"
    readonly property string powerShutdown: isEs ? "Apagar" : "Power Off"
    readonly property string powerCancel: isEs ? "Cancelar" : "Cancel"
    readonly property string powerConfirmBtn: isEs ? "Confirmar" : "Confirm"

    readonly property string powerConfirmLogoutTitle: isEs ? "¿Cerrar la sesión actual?" : "Log out of current session?"
    readonly property string powerConfirmLogoutDesc: isEs
        ? "Se cerrarán las ventanas abiertas y volverás a la pantalla de inicio de sesión."
        : "Open applications will close and you will return to the login screen."
    readonly property string powerConfirmRebootTitle: isEs ? "¿Reiniciar el equipo?" : "Restart the system?"
    readonly property string powerConfirmRebootDesc: isEs
        ? "Se cerrarán todos los programas activos y el equipo se reiniciará."
        : "All running applications will close and the computer will restart."
    readonly property string powerConfirmUefiTitle: isEs ? "¿Reiniciar hacia BIOS / UEFI?" : "Reboot to BIOS / UEFI firmware?"
    readonly property string powerConfirmUefiDesc: isEs
        ? "El equipo se reiniciará entrando directamente al menú de configuración UEFI."
        : "The system will restart directly into the UEFI firmware setup menu."
    readonly property string powerConfirmShutdownTitle: isEs ? "¿Apagar el equipo?" : "Power off the system?"
    readonly property string powerConfirmShutdownDesc: isEs
        ? "Se cerrarán todas las aplicaciones abiertas y el equipo se apagará por completo."
        : "All open applications will close and the computer will shut down completely."

    readonly property string powerHintMain: isEs
        ? "← → Navegar  •  Enter Elegir  •  L S E R U P Atajo  •  Esc Cerrar"
        : "← → Navigate  •  Enter Select  •  L S E R U P Hotkey  •  Esc Close"
    readonly property string powerHintConfirm: isEs
        ? "Enter Confirmar acción  •  Esc Volver atrás"
        : "Enter Confirm action  •  Esc Go back"

    // -------------------------------------------------------------------------
    // 9. DESKTOP RIGHT-CLICK CONTEXT MENU
    // -------------------------------------------------------------------------
    readonly property string ctxApps: isEs ? "Aplicaciones" : "Applications"
    readonly property string ctxOverview: isEs ? "Vista General" : "Workspaces Overview"
    readonly property string ctxTerminal: isEs ? "Terminal (Kitty)" : "Terminal (Kitty)"
    readonly property string ctxFiles: isEs ? "Archivos (Dolphin)" : "Files (Dolphin)"
    readonly property string ctxThemes: "X64 Theme Studio"
    readonly property string ctxScreenshot: isEs ? "Captura de pantalla" : "Screenshot"
    readonly property string ctxPower: isEs ? "Sesión y Energía" : "Power & Session"

    // -------------------------------------------------------------------------
    // 10. FREEZE-FRAME SCREENSHOT OVERLAY & QUICK ACTIONS
    // -------------------------------------------------------------------------
    readonly property string shotFreezeHint: isEs
        ? "Arrastra para recortar  •  Enter Pantalla completa  •  Esc / Clic der. Cancelar"
        : "Drag to crop  •  Enter Full monitor  •  Esc / Right-click Cancel"
    readonly property string shotActionOpen: isEs ? "Abrir" : "Open"
    readonly property string shotActionFolder: isEs ? "Carpeta" : "Folder"
}

