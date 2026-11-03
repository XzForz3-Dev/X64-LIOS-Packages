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
    readonly property string netWireless: isEs ? "󰤨 Redes Inalámbricas (Wi-Fi)" : "󰤨 Wireless Networks (Wi-Fi)"
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
}

