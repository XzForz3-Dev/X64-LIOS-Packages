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

    color: "#d0050508"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: shortcutsWindow.closeRequested()
    }

    // =========================================================================
    // COMPREHENSIVE HYPRLAND & X64 LIOS SHORTCUTS CATALOG
    // =========================================================================
    readonly property var allShortcuts: [
        // ---------------------------------------------------------------------
        // 1. BÁSICOS E IMPRESCINDIBLES (ESSENTIALS)
        // ---------------------------------------------------------------------
        {
            keys: ["SUPER", "Return"],
            title: I18n.isEs ? "Terminal Kitty" : "Kitty Terminal",
            desc: I18n.isEs ? "Lanza la terminal acelerada por GPU" : "GPU-accelerated default terminal",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "Espacio"],
            title: I18n.isEs ? "Lanzador de Apps" : "App Launcher",
            desc: I18n.isEs ? "Menú interactivo con buscador de programas" : "Interactive application launcher & search",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "Q"],
            title: I18n.isEs ? "Cerrar Ventana" : "Close Window",
            desc: I18n.isEs ? "Cierra de forma segura la ventana activa" : "Safely close the focused window",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "E"],
            title: I18n.isEs ? "Explorador de Archivos" : "File Manager",
            desc: I18n.isEs ? "Abre Dolphin con soporte nativo de pestañas" : "Dolphin file manager with tabs & previews",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "F1"],
            title: I18n.isEs ? "Guía de Atajos de Teclado" : "Shortcuts Guide",
            desc: I18n.isEs ? "Despliega este centro interactivo de ayuda" : "Toggles this interactive cheatsheet guide",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "L"],
            title: I18n.isEs ? "Bloquear Pantalla" : "Lock Screen",
            desc: I18n.isEs ? "Bloqueo cinematográfico seguro con Hyprlock" : "Cinematic secure lockscreen with Hyprlock",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },
        {
            keys: ["SUPER", "M"],
            title: I18n.isEs ? "Menú de Sesión / Salir" : "Power / Session Menu",
            desc: I18n.isEs ? "Apagar, reiniciar, suspender o cerrar sesión" : "Power off, reboot, suspend or logout",
            category: "essentials",
            catLabel: I18n.isEs ? "Básicos" : "Basics"
        },

        // ---------------------------------------------------------------------
        // 2. MOSAICO Y CONTROL DE VENTANAS (TILING & WINDOWS)
        // ---------------------------------------------------------------------
        {
            keys: ["SUPER", "W"],
            title: I18n.isEs ? "Ventana Flotante" : "Toggle Floating",
            desc: I18n.isEs ? "Alterna la ventana entre mosaico y flotante" : "Switch window between tiled and floating",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "F"],
            title: I18n.isEs ? "Pantalla Completa" : "Toggle Fullscreen",
            desc: I18n.isEs ? "Maximiza la ventana a pantalla completa total" : "Expand active window to true fullscreen",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "J"],
            title: I18n.isEs ? "Alternar División (Split)" : "Toggle Split Tree",
            desc: I18n.isEs ? "Alterna división entre horizontal y vertical" : "Toggle dwindle split horizontal / vertical",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "Flechas"],
            title: I18n.isEs ? "Mover Foco de Ventana" : "Move Window Focus",
            desc: I18n.isEs ? "Cambia el foco entre ventanas adyacentes" : "Shifts focus to adjacent window in direction",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "SHIFT", "Flechas"],
            title: I18n.isEs ? "Intercambiar Posición" : "Swap Window Position",
            desc: I18n.isEs ? "Mueve la ventana física de lugar en el árbol" : "Swap focused window location in layout tree",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },
        {
            keys: ["SUPER", "Tab"],
            title: I18n.isEs ? "Ciclar Siguiente Ventana" : "Cycle Next Window",
            desc: I18n.isEs ? "Pasa el foco en bucle a la siguiente ventana" : "Cycle window focus in active workspace",
            category: "tiling",
            catLabel: I18n.isEs ? "Mosaico" : "Tiling"
        },

        // ---------------------------------------------------------------------
        // 3. RATÓN Y PANTALLAS (MOUSE & MULTI-MONITOR)
        // ---------------------------------------------------------------------
        {
            keys: ["SUPER", "Arrastre Izq"],
            title: I18n.isEs ? "Mover con Ratón" : "Drag Window Mouse",
            desc: I18n.isEs ? "Mantén SUPER y arrastra con clic izquierdo" : "Hold SUPER & drag left-click to move freely",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["SUPER", "Arrastre Der"],
            title: I18n.isEs ? "Redimensionar con Ratón" : "Resize Window Mouse",
            desc: I18n.isEs ? "Mantén SUPER y arrastra con clic derecho" : "Hold SUPER & drag right-click to resize",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["Rueda", "Sobre Barra"],
            title: I18n.isEs ? "Cambiar Escritorio Rueda" : "Scroll Switch Workspace",
            desc: I18n.isEs ? "Girar la rueda sobre la barra cambia de escritorio" : "Scroll over top bar cycles active workspace",
            category: "mouse",
            catLabel: I18n.isEs ? "Ratón" : "Mouse"
        },
        {
            keys: ["SUPER", "SHIFT", "Izq / Der"],
            title: I18n.isEs ? "Mover a Otro Monitor" : "Move to Next Display",
            desc: I18n.isEs ? "Envía la ventana al monitor secundario/adyacente" : "Moves focused window across connected monitors",
            category: "mouse",
            catLabel: I18n.isEs ? "Pantallas" : "Displays"
        },

        // ---------------------------------------------------------------------
        // 4. HERRAMIENTAS EXCLUSIVAS X64 LIOS (X64 SUITE & GAMING)
        // ---------------------------------------------------------------------
        {
            keys: ["SUPER", "S"],
            title: I18n.isEs ? "Scratchpad IA (OpenCode)" : "AI Scratchpad (OpenCode)",
            desc: I18n.isEs ? "Consola flotante con modelos IA y agentes" : "Floating drop-down AI terminal with models",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "A"],
            title: I18n.isEs ? "Atajo Alternativo IA" : "Alt AI Scratchpad Key",
            desc: I18n.isEs ? "Acceso rápido ergonómico con una sola mano" : "One-handed ergonomic key to AI Scratchpad",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "G"],
            title: I18n.isEs ? "Modo Gaming • Cero Latencia" : "Gaming Mode • Zero Latency",
            desc: I18n.isEs ? "0 gaps/blur, CPU a max y tearing directo GPU" : "0 gaps/blur, max CPU clock & direct tearing",
            category: "x64",
            catLabel: "Gaming"
        },
        {
            keys: ["ALT", "Rueda Ratón"],
            title: I18n.isEs ? "Lupa Zoom Cinematográfico" : "Live Magnifier Zoom",
            desc: I18n.isEs ? "Acerca o aleja la pantalla suavemente" : "Smooth viewport zoom in / out with wheel",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["ALT", "0"],
            title: I18n.isEs ? "Resetear Zoom a 1.0x" : "Reset Zoom 1.0x",
            desc: I18n.isEs ? "Restaura la escala instantáneamente a 1.0x" : "Instantly resets compositor zoom to 1.0x",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "V"],
            title: I18n.isEs ? "Historial del Portapapeles" : "Clipboard History",
            desc: I18n.isEs ? "Abre el gestor visual de textos y enlaces copiados" : "Open visual history of copied text and links",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "C"],
            title: I18n.isEs ? "Centro de Control X64" : "X64 Control Center",
            desc: I18n.isEs ? "Brillo, volumen, perfiles, red y telemetría" : "Sidebar with brightness, volume, power & network",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["SUPER", "CTRL", "N"],
            title: I18n.isEs ? "Gestor de Redes Wi-Fi" : "Wi-Fi Network Manager",
            desc: I18n.isEs ? "Escaneo y conexión rápida de redes Wi-Fi" : "Direct Wi-Fi scanning & connection popup",
            category: "x64",
            catLabel: "X64 Suite"
        },
        {
            keys: ["Print"],
            title: I18n.isEs ? "Captura Pantalla Completa" : "Full Screenshot",
            desc: I18n.isEs ? "Guarda en ~/Imágenes/Screenshots con sonido" : "Saves full display to Screenshots with sound",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "SHIFT", "S"],
            title: I18n.isEs ? "Recorte / Captura de Región" : "Region Snipping Tool",
            desc: I18n.isEs ? "Selecciona un área rectangular interactiva" : "Interactive rectangular area snip to clipboard",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "SHIFT", "R"],
            title: I18n.isEs ? "Grabación de Pantalla (GPU)" : "Screen Recording (GPU)",
            desc: I18n.isEs ? "Graba pantalla con aceleración por hardware" : "Hardware-accelerated GPU screen recorder",
            category: "x64",
            catLabel: "Media"
        },
        {
            keys: ["SUPER", "B"],
            title: I18n.isEs ? "Monitor de Recursos Btop" : "Btop System Monitor",
            desc: I18n.isEs ? "Monitor de CPU, GPU, RAM, red y temperaturas" : "Interactive CPU, GPU, RAM & system monitor",
            category: "x64",
            catLabel: "Sistema"
        },
        {
            keys: ["SUPER", "H"],
            title: I18n.isEs ? "X64 LIOS Hello" : "X64 LIOS Hello",
            desc: I18n.isEs ? "Centro de bienvenida y optimizaciones gamer" : "Welcome hub, gaming tweaker & tools",
            category: "x64",
            catLabel: "Sistema"
        },

        // ---------------------------------------------------------------------
        // 5. ESCRITORIOS VIRTUALES (WORKSPACES)
        // ---------------------------------------------------------------------
        {
            keys: ["SUPER", "1 .. 6"],
            title: I18n.isEs ? "Ir al Escritorio 1 al 6" : "Go to Workspace 1..6",
            desc: I18n.isEs ? "Cambia al espacio de trabajo correspondiente" : "Switch directly to workspaces 1 through 6",
            category: "workspaces",
            catLabel: I18n.isEs ? "Escritorios" : "Workspaces"
        },
        {
            keys: ["SUPER", "SHIFT", "1 .. 6"],
            title: I18n.isEs ? "Mover Ventana a Escritorio" : "Move Window to Workspace",
            desc: I18n.isEs ? "Traslada la ventana activa al escritorio 1..6" : "Transfer active window to workspace 1..6",
            category: "workspaces",
            catLabel: I18n.isEs ? "Escritorios" : "Workspaces"
        },
        {
            keys: ["SUPER", "Rueda Ratón"],
            title: I18n.isEs ? "Ciclar Escritorios" : "Cycle Workspaces Key+Scroll",
            desc: I18n.isEs ? "Recorre en bucle 1 ↔ 6 sin saltar escritorios vacíos" : "Cycle workspaces 1..6 without skipping empty ones",
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

    // Centered Obsidian & Crimson 2026 High-Density Modal
    Rectangle {
        id: card
        width: Math.min(parent.width - 40, 1020)
        height: Math.min(parent.height - 50, 700)
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
            anchors.margins: 18
            spacing: 12

            // -----------------------------------------------------------------
            // 1. HEADER: Icon, Title, Subtitle, ESC Button
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 9
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
                        text: I18n.isEs ? "GUÍA MAESTRA DE ATAJOS • HYPRLAND X64" : "KEYBOARD SHORTCUTS MASTER GUIDE • HYPRLAND X64"
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.5
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
                    implicitWidth: 70
                    implicitHeight: 28
                    radius: 7
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
                            font.pixelSize: 11
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
            // 2. SEARCH BOX: Real-time dynamic query filter
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 10
                color: Theme.bgElevated
                border.color: searchInput.activeFocus ? Theme.accentBorder : Theme.borderSubtle
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
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

                    // Clear search button
                    Rectangle {
                        visible: searchInput.text.length > 0
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        color: clearArea.containsMouse ? Theme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
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
            // 3. CATEGORY PILLS BAR (Nerd Font Monochromatic Icons)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "all",        icon: "", label: I18n.isEs ? "Todos" : "All" },
                        { id: "essentials", icon: "", label: I18n.isEs ? "Básicos" : "Basics" },
                        { id: "tiling",     icon: "󱂬", label: I18n.isEs ? "Mosaico & Ventanas" : "Tiling & Windows" },
                        { id: "mouse",      icon: "󰖲", label: I18n.isEs ? "Ratón & Pantallas" : "Mouse & Displays" },
                        { id: "x64",        icon: "󰊴", label: I18n.isEs ? "Herramientas X64" : "X64 Tools" },
                        { id: "workspaces", icon: "󰘳", label: I18n.isEs ? "Escritorios" : "Workspaces" }
                    ]

                    Rectangle {
                        id: catBtn
                        implicitHeight: 28
                        implicitWidth: catRow.implicitWidth + 18
                        radius: 8
                        readonly property bool isSelected: shortcutsWindow.currentCategory === modelData.id
                        color: isSelected ? Theme.accentDim : (catArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                        border.color: isSelected ? Theme.accentBorder : (catArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: catRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: catBtn.isSelected ? Theme.accent : Theme.textSecondary
                            }

                            Text {
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: catBtn.isSelected
                                color: catBtn.isSelected ? Theme.textPrimary : Theme.textSecondary
                            }
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
            // 4. SHORTCUTS 2-COLUMN HIGH-DENSITY GRID
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMd
                color: Theme.bgDark
                border.color: Theme.borderSubtle
                border.width: 1
                clip: true

                GridView {
                    id: shortcutGrid
                    anchors.fill: parent
                    anchors.margins: 10
                    cellWidth: width / 2
                    cellHeight: 64
                    clip: true
                    model: shortcutsWindow.filteredList

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: shortcutCell
                        readonly property var itemData: modelData
                        width: shortcutGrid.cellWidth
                        height: shortcutGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 9
                            color: itemMouseArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                            border.color: itemMouseArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                // 1. Physical 3D Keycaps
                                RowLayout {
                                    spacing: 3
                                    Repeater {
                                        id: keysRepeater
                                        model: shortcutCell.itemData ? shortcutCell.itemData.keys : []
                                        RowLayout {
                                            spacing: 3
                                            Rectangle {
                                                implicitHeight: 24
                                                implicitWidth: Math.max(keyLabel.implicitWidth + 12, 24)
                                                radius: 5
                                                readonly property bool isSpecial: modelData === "SUPER" || modelData === "ALT" || modelData === "SHIFT" || modelData === "CTRL" || modelData === "G" || modelData === "S" || modelData === "A" || modelData === "F1"
                                                color: isSpecial ? "#29ff2b2b" : "#1b1d24"
                                                border.color: isSpecial ? "#77ff2b2b" : "#2b303d"
                                                border.width: 1

                                                // 3D bottom bevel line
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    height: 2
                                                    radius: 1
                                                    color: parent.isSpecial ? "#55ff2b2b" : "#121419"
                                                }

                                                Text {
                                                    id: keyLabel
                                                    anchors.centerIn: parent
                                                    anchors.verticalCenterOffset: -1
                                                    text: modelData
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: parent.isSpecial ? Theme.accent : Theme.textPrimary
                                                }
                                            }

                                            Text {
                                                visible: index < keysRepeater.count - 1
                                                text: "+"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                color: Theme.textMuted
                                            }
                                        }
                                    }
                                }

                                // 2. Action Title & Short Description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: shortcutCell.itemData ? shortcutCell.itemData.title : ""
                                            font.family: Theme.fontSans
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Theme.textPrimary
                                            elide: Text.ElideRight
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Category Tag Pill
                                        Rectangle {
                                            implicitHeight: 16
                                            implicitWidth: tagText.implicitWidth + 8
                                            radius: 4
                                            color: "#14ffffff"
                                            border.color: "#18ffffff"
                                            border.width: 1

                                            Text {
                                                id: tagText
                                                anchors.centerIn: parent
                                                text: shortcutCell.itemData ? shortcutCell.itemData.catLabel : ""
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                color: Theme.textSecondary
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: shortcutCell.itemData ? shortcutCell.itemData.desc : ""
                                        font.family: Theme.fontSans
                                        font.pixelSize: 9
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }

                    // Empty Search Fallback State
                    Item {
                        anchors.centerIn: parent
                        visible: shortcutsWindow.filteredList.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰍉"
                                font.family: Theme.fontMono
                                font.pixelSize: 28
                                color: Theme.textMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.isEs ? "No se encontraron atajos con ese criterio" : "No shortcuts found matching your search"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
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
            // 5. FOOTER: Status counter & Quick Navigation Hint (Guaranteed Icons)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰌌"
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
                    text: "X64 LIOS Hyprland • Obsidian & Crimson 2026"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}
