import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: shortcutsWindow

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#cc050508"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: shortcutsWindow.closeRequested()
    }

    // Comprehensive Hyprland & X64 LIOS Keybinding Catalog
    readonly property var allShortcuts: [
        // =====================================================================
        // 1. IMPRESCINDIBLES (ESSENTIALS)
        // =====================================================================
        {
            keys: ["SUPER", "Return"],
            title: I18n.isEs ? "Terminal Kitty" : "Kitty Terminal",
            desc: I18n.isEs ? "Lanza la terminal acelerada por GPU por defecto" : "Launches default GPU-accelerated terminal",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "Espacio"],
            title: I18n.isEs ? "Lanzador de Aplicaciones" : "App Launcher",
            desc: I18n.isEs ? "Menú interactivo con buscador de programas y juegos" : "Interactive application launcher and search menu",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "Q"],
            title: I18n.isEs ? "Cerrar Ventana" : "Close Window",
            desc: I18n.isEs ? "Cierra de forma segura la ventana que tiene el foco" : "Safely closes the currently focused window",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "E"],
            title: I18n.isEs ? "Explorador de Archivos" : "File Manager",
            desc: I18n.isEs ? "Abre Dolphin con soporte nativo de miniaturas y pestañas" : "Opens Dolphin with tabs and thumbnail previews",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "F1"],
            title: I18n.isEs ? "Guía de Atajos de Teclado" : "Shortcuts Guide",
            desc: I18n.isEs ? "Muestra u oculta este centro interactivo de ayuda" : "Toggles this interactive help center and guide",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "L"],
            title: I18n.isEs ? "Bloquear Pantalla" : "Lock Screen",
            desc: I18n.isEs ? "Bloqueo de seguridad cinematográfico con Hyprlock" : "Cinematic security lockscreen with Hyprlock",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "M"],
            title: I18n.isEs ? "Menú de Sesión / Apagado" : "Session / Power Menu",
            desc: I18n.isEs ? "Opciones de apagar, reiniciar, suspender o cerrar sesión" : "Power off, reboot, suspend, or logout options",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },

        // =====================================================================
        // 2. MOSAICO Y CONTROL DE VENTANAS (TILING & WINDOW MANAGEMENT)
        // =====================================================================
        {
            keys: ["SUPER", "V"],
            title: I18n.isEs ? "Alternar Ventana Flotante" : "Toggle Floating",
            desc: I18n.isEs ? "Alterna la ventana enfocada entre modo mosaico y flotante" : "Switches focused window between tiled and floating mode",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "F"],
            title: I18n.isEs ? "Pantalla Completa" : "Toggle Fullscreen",
            desc: I18n.isEs ? "Maximiza la ventana a pantalla completa total (sin barras)" : "Expands the active window to true fullscreen",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "J"],
            title: I18n.isEs ? "Alternar División (Split)" : "Toggle Split",
            desc: I18n.isEs ? "Cambia la división del árbol entre horizontal y vertical" : "Toggles dwindle split between horizontal and vertical",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "Flechas"],
            title: I18n.isEs ? "Cambiar Foco de Ventana" : "Move Window Focus",
            desc: I18n.isEs ? "Mueve el foco entre ventanas adyacentes en cualquier dirección" : "Shifts focus to adjacent window in the given direction",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "SHIFT", "Flechas"],
            title: I18n.isEs ? "Mover Ventana de Lugar" : "Swap / Move Window",
            desc: I18n.isEs ? "Intercambia la posición física de la ventana en el mosaico" : "Swaps window position within the tiling layout tree",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "Tab"],
            title: I18n.isEs ? "Ciclar Siguiente Ventana" : "Cycle Next Window",
            desc: I18n.isEs ? "Pasa el foco en bucle a la siguiente ventana del escritorio" : "Cycles window focus forward in the current workspace",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },

        // =====================================================================
        // 3. RATÓN Y PANTALLAS (MOUSE & MULTI-MONITOR)
        // =====================================================================
        {
            keys: ["SUPER", "Arrastre Clic Izq"],
            title: I18n.isEs ? "Mover Ventana con Ratón" : "Drag Window with Mouse",
            desc: I18n.isEs ? "Mantén SUPER y arrastra con clic izquierdo para mover la ventana" : "Hold SUPER and drag left-click to move window freely",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["SUPER", "Arrastre Clic Der"],
            title: I18n.isEs ? "Redimensionar con Ratón" : "Resize Window with Mouse",
            desc: I18n.isEs ? "Mantén SUPER y arrastra con clic derecho desde cualquier punto" : "Hold SUPER and drag right-click to resize window smoothly",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["Rueda", "Sobre Barra Superior"],
            title: I18n.isEs ? "Cambiar Escritorio con Rueda" : "Scroll Switch Workspace",
            desc: I18n.isEs ? "Girar la rueda del ratón sobre la barra superior cambia de escritorio" : "Scrolling over the top bar cycles active workspace",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["SUPER", "SHIFT", "Izq / Der"],
            title: I18n.isEs ? "Mover a Otro Monitor" : "Move to Next Monitor",
            desc: I18n.isEs ? "Envía la ventana activa directamente al monitor adyacente" : "Moves the focused window across connected monitors",
            category: "mouse",
            catLabel: I18n.isEs ? "Pantallas" : "Displays"
        },

        // =====================================================================
        // 4. HERRAMIENTAS EXCLUSIVAS X64 LIOS (X64 SUITE & GAMING)
        // =====================================================================
        {
            keys: ["SUPER", "S"],
            title: I18n.isEs ? "Scratchpad IA (OpenCode / WebApps)" : "AI Scratchpad (OpenCode)",
            desc: I18n.isEs ? "Despliega consola flotante centrada con modelos IA y agentes" : "Opens floating drop-down AI terminal with free models",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "A"],
            title: I18n.isEs ? "Atajo Alternativo Scratchpad IA" : "Alt AI Scratchpad Key",
            desc: I18n.isEs ? "Acceso directo ergonómico con una sola mano al agente IA" : "One-handed fast access key to the AI Scratchpad",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "G"],
            title: I18n.isEs ? "Modo Gaming • Latencia Cero" : "Gaming Mode • Zero Latency",
            desc: I18n.isEs ? "Quita blur/gaps, fija CPU a max y optimiza tearing para juegos" : "Disables blur/gaps, boosts CPU clock, enables direct scanout",
            category: "x64",
            catLabel: "Gaming"
        },
        {
            keys: ["ALT", "Rueda Ratón"],
            title: I18n.isEs ? "Lupa Zoom Cinematográfico" : "Live Magnifier Zoom",
            desc: I18n.isEs ? "Acerca o aleja la pantalla suavemente (cuando la lupa está activa)" : "Zooms viewport in and out smoothly (when magnifier is ON)",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["ALT", "0"],
            title: I18n.isEs ? "Resetear Lupa Zoom a 1.0x" : "Reset Zoom to 1.0x",
            desc: I18n.isEs ? "Restaura la escala visual instantáneamente a resolución nativa" : "Instantly resets compositor zoom factor back to 1.0x",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "C"],
            title: I18n.isEs ? "Centro de Control X64" : "X64 Control Center",
            desc: I18n.isEs ? "Panel lateral con brillo, volumen, perfiles, red y telemetría" : "Sidebar with brightness, volume, power profiles, and network",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "CTRL", "N"],
            title: I18n.isEs ? "Gestor de Redes Wi-Fi" : "Wi-Fi Network Manager",
            desc: I18n.isEs ? "Abre el panel rápido de conexión y escaneo de redes" : "Direct popup for scanning and connecting to Wi-Fi networks",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["Print"],
            title: I18n.isEs ? "Captura de Pantalla Completa" : "Full Screenshot",
            desc: I18n.isEs ? "Guarda la pantalla completa en ~/Imágenes/Screenshots con sonido" : "Saves full display to ~/Pictures/Screenshots with audio cues",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "SHIFT", "S"],
            title: I18n.isEs ? "Captura de Región / Selección" : "Region Snipping Tool",
            desc: I18n.isEs ? "Permite recortar un área rectangular de la pantalla con slurp" : "Interactive rectangular area snip copied to clipboard and disk",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "SHIFT", "R"],
            title: I18n.isEs ? "Grabación de Pantalla (GPU)" : "Screen Recording (GPU)",
            desc: I18n.isEs ? "Inicia o detiene la grabación con aceleración por hardware" : "Toggles hardware-accelerated screen recording (GPU-powered)",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "B"],
            title: I18n.isEs ? "Monitor de Recursos Btop" : "Btop System Monitor",
            desc: I18n.isEs ? "Monitor detallado de CPU, GPU, RAM, temperaturas y procesos" : "Advanced monitor for CPU, GPU, memory, temperatures, and disks",
            category: "x64",
            catLabel: "Sistema"
        },
        {
            keys: ["SUPER", "H"],
            title: I18n.isEs ? "X64 LIOS Hello" : "X64 LIOS Hello",
            desc: I18n.isEs ? "Centro de bienvenida, optimizaciones gamer e instaladores" : "Welcome hub, gaming tweaker, and system post-installer",
            category: "x64",
            catLabel: "Sistema"
        },

        // =====================================================================
        // 5. ESCRITORIOS VIRTUALES (WORKSPACES)
        // =====================================================================
        {
            keys: ["SUPER", "1 .. 6"],
            title: I18n.isEs ? "Ir al Escritorio 1 al 6" : "Go to Workspace 1..6",
            desc: I18n.isEs ? "Cambia instantáneamente al espacio de trabajo correspondiente" : "Directly switches to workspace numbers 1 through 6",
            category: "workspaces",
            catLabel: I18n.isEs ? "Escritorios" : "Workspaces"
        },
        {
            keys: ["SUPER", "SHIFT", "1 .. 6"],
            title: I18n.isEs ? "Mover Ventana a Escritorio" : "Move Window to Workspace",
            desc: I18n.isEs ? "Envía la ventana activa al escritorio 1..6 en segundo plano" : "Transfers focused window to workspace 1..6 silently",
            category: "workspaces",
            catLabel: I18n.isEs ? "Escritorios" : "Workspaces"
        },
        {
            keys: ["SUPER", "Rueda Ratón"],
            title: I18n.isEs ? "Ciclar Escritorios con Rueda" : "Cycle Workspaces Key+Scroll",
            desc: I18n.isEs ? "Recorre los escritorios 1 ↔ 6 sin saltarse los escritorios vacíos" : "Cycles smoothly across workspaces 1 to 6 without skips",
            category: "workspaces",
            catLabel: I18n.isEs ? "Escritorios" : "Workspaces"
        }
    ]

    property string currentCategory: "all"
    property var filteredList: []

    function updateFilteredList() {
        var q = searchInput.text.trim().toLowerCase();
        var cat = currentCategory;
        var res = [];

        for (var i = 0; i < allShortcuts.length; i++) {
            var item = allShortcuts[i];
            if (cat !== "all" && item.category !== cat) continue;

            if (q === "") {
                res.push(item);
            } else {
                var match = false;
                if (item.title.toLowerCase().indexOf(q) !== -1) match = true;
                else if (item.desc.toLowerCase().indexOf(q) !== -1) match = true;
                else if (item.catLabel.toLowerCase().indexOf(q) !== -1) match = true;
                else {
                    for (var k = 0; k < item.keys.length; k++) {
                        if (item.keys[k].toLowerCase().indexOf(q) !== -1) {
                            match = true;
                            break;
                        }
                    }
                }
                if (match) res.push(item);
            }
        }
        filteredList = res;
    }

    onVisibleChanged: {
        if (visible) {
            currentCategory = "all";
            searchInput.text = "";
            updateFilteredList();
            searchInput.forceActiveFocus();
        }
    }

    // Centered Obsidian & Crimson 2026 Card
    Rectangle {
        id: card
        width: Math.min(parent.width - 40, 960)
        height: Math.min(parent.height - 60, 680)
        anchors.centerIn: parent
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {} // consume clicks inside card
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // -----------------------------------------------------------------
            // HEADER: Icon, Title, Subtitle, Close Button
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: 10
                    color: Theme.accentDim
                    border.color: Theme.accentBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: I18n.isEs ? "GUÍA DE ATAJOS • HYPRLAND X64" : "KEYBOARD SHORTCUTS • HYPRLAND X64"
                        font.family: Theme.fontSans
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 0.6
                        color: Theme.textPrimary
                    }

                    Text {
                        text: I18n.isEs 
                            ? "Referencia interactiva de navegación, mosaico, multimonitor y herramientas del sistema"
                            : "Interactive reference for navigation, tiling, multi-monitor, and system tools"
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }

                // ESC Pill / Close Button
                Rectangle {
                    implicitWidth: 68
                    implicitHeight: 30
                    radius: 8
                    color: closeArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                    border.color: closeArea.containsMouse ? "#33ffffff" : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "ESC"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textMuted
                        }

                        Text {
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: closeArea.containsMouse ? Theme.accent : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shortcutsWindow.closeRequested()
                    }
                }
            }

            // -----------------------------------------------------------------
            // SEARCH BOX: Real-time dynamic filter
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusMd
                color: Theme.bgElevated
                border.color: searchInput.activeFocus ? Theme.accentBorder : Theme.borderSubtle
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        color: searchInput.activeFocus ? Theme.accent : Theme.textMuted
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        color: Theme.textPrimary
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: I18n.isEs 
                                ? "Buscar atajo o función... (ej. terminal, ventana, monitor, zoom, gaming, capturar...)"
                                : "Search shortcut or feature... (e.g. terminal, window, monitor, zoom, gaming, screenshot...)"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textMuted
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }

                        onTextChanged: shortcutsWindow.updateFilteredList()

                        Keys.onEscapePressed: shortcutsWindow.closeRequested()
                    }

                    // Clear button
                    Rectangle {
                        visible: searchInput.text.length > 0
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: clearArea.containsMouse ? Theme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // CATEGORY PILLS BAR
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "all",        label: I18n.isEs ? "Todos" : "All" },
                        { id: "essentials", label: I18n.isEs ? "🔰 Imprescindibles" : "🔰 Essentials" },
                        { id: "tiling",     label: I18n.isEs ? "🪟 Mosaico" : "🪟 Tiling" },
                        { id: "mouse",      label: I18n.isEs ? "🖱️ Ratón y Pantallas" : "🖱️ Mouse & Displays" },
                        { id: "x64",        label: I18n.isEs ? "🚀 Herramientas X64" : "🚀 X64 Tools" },
                        { id: "workspaces", label: I18n.isEs ? "🗂️ Escritorios" : "🗂️ Workspaces" }
                    ]

                    Rectangle {
                        id: catBtn
                        implicitHeight: 28
                        implicitWidth: catLabelText.implicitWidth + 20
                        radius: 8
                        readonly property bool isSelected: shortcutsWindow.currentCategory === modelData.id
                        color: isSelected ? Theme.accentDim : (catArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                        border.color: isSelected ? Theme.accentBorder : (catArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            id: catLabelText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: catBtn.isSelected
                            color: catBtn.isSelected ? Theme.textPrimary : Theme.textSecondary
                        }

                        MouseArea {
                            id: catArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shortcutsWindow.currentCategory = modelData.id;
                                shortcutsWindow.updateFilteredList();
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // -----------------------------------------------------------------
            // SHORTCUTS LIST / GRID: 2-column responsive layout
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMd
                color: Theme.bgDark
                border.color: Theme.borderSubtle
                border.width: 1
                clip: true

                ListView {
                    id: shortcutListView
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    model: shortcutsWindow.filteredList

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: shortcutListView.width
                        implicitHeight: 52
                        radius: 10
                        color: itemMouseArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                        border.color: itemMouseArea.containsMouse ? "#2affffff" : Theme.borderSubtle
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12

                            // 1. Keycaps Row
                            RowLayout {
                                spacing: 4
                                Repeater {
                                    model: modelData.keys
                                    RowLayout {
                                        spacing: 4
                                        Rectangle {
                                            implicitHeight: 26
                                            implicitWidth: Math.max(keyText.implicitWidth + 14, 28)
                                            radius: 6
                                            readonly property bool isSpecial: modelData === "SUPER" || modelData === "ALT" || modelData === "SHIFT" || modelData === "CTRL" || modelData === "G" || modelData === "S" || modelData === "A" || modelData === "F1"
                                            color: isSpecial ? "#24ff2b2b" : "#1a202c"
                                            border.color: isSpecial ? "#66ff2b2b" : "#33ffffff"
                                            border.width: 1

                                            Text {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.family: Theme.fontMono
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: isSpecial ? Theme.accent : Theme.textPrimary
                                            }
                                        }

                                        Text {
                                            visible: index < (modelData.keys ? modelData.keys.length - 1 : 0)
                                            text: "+"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            color: Theme.textMuted
                                        }
                                    }
                                }
                            }

                            // 2. Title & Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            // 3. Category Tag
                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: catTagText.implicitWidth + 10
                                radius: 5
                                color: "#0fffffff"
                                border.color: "#18ffffff"
                                border.width: 1

                                Text {
                                    id: catTagText
                                    anchors.centerIn: parent
                                    text: modelData.catLabel
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    // Empty Search Fallback
                    Item {
                        anchors.centerIn: parent
                        visible: shortcutsWindow.filteredList.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰍉"
                                font.family: Theme.fontMono
                                font.pixelSize: 32
                                color: Theme.textMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.isEs ? "No se encontraron atajos con ese criterio" : "No shortcuts found matching your search"
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                color: Theme.textSecondary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.isEs ? "Prueba buscando otra palabra clave o selecciona 'Todos'" : "Try another keyword or select 'All' categories"
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // FOOTER: Status counter & Quick Navigation Hint
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰋖"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.accent
                }

                Text {
                    text: I18n.isEs
                        ? (shortcutsWindow.filteredList.length + " atajos disponibles • Pulsa SUPER + F1 en cualquier momento o ESC para cerrar")
                        : (shortcutsWindow.filteredList.length + " shortcuts available • Press SUPER + F1 anytime or ESC to dismiss")
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: I18n.isEs ? "X64 LIOS Hyprland • Obsidian & Crimson 2026" : "X64 LIOS Hyprland • Obsidian & Crimson 2026"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}
