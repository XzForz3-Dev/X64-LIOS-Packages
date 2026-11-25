import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1120
    height: 700
    color: "#191919"
    focus: true

    property string explorerSection: (typeof initialArg !== "undefined" && initialArg !== "") ? initialArg : "Este equipo"
    property string explorerRealPath: "Este equipo"
    property string explorerMode: "thispc"
    property bool isTrashFolder: false
    property var explorerItems: []
    property var explorerDrives: []
    property int explorerItemCount: 0
    property string explorerSortBy: "name"
    property bool explorerSortAsc: true
    property string explorerViewMode: "details" // "details" | "tiles" | "large"
    property bool showHiddenFiles: false
    property string searchFilter: ""
    property bool deepSearchActive: false
    property var deepSearchItems: []
    property bool editingAddress: false
    property string statusToast: ""

    // Multi-Selection, Shared Clipboard, Inline Rename, Drag-and-Drop & Context Menu State
    property var selectedPaths: []
    readonly property string selectedPath: selectedPaths.length > 0 ? selectedPaths[selectedPaths.length - 1] : ""
    property var selectedObj: null
    property int selectionAnchorIdx: -1
    property int hoveredItemIdx: -1
    property var clipboardPaths: []
    readonly property string clipboardPath: clipboardPaths.length > 0 ? clipboardPaths[0] : ""
    property bool clipboardIsCut: false
    property bool renamingActive: false
    property string openDropdown: "" // "" | "new" | "sort" | "view" | "more"
    property bool expCtxOpen: false
    property string expCtxKind: "bg" // "bg" | "item" | "trash_nav" | "nav_folder" | "thispc_item"
    property var expCtxTargetObj: null
    property real expCtxX: 200
    property real expCtxY: 200
    property bool expPropsOpen: false
    property var expPropsData: null

    // Unified Drag-and-Drop State (across Details View, Tiles/Large View, Sidebar & Breadcrumbs!)
    property bool draggingItems: false
    property var dragSourcePaths: []
    property string dragLeadName: ""
    property string dragLeadIcon: "fluent-document.svg"
    property string dragLeadIconUrl: ""
    property real dragGlobalX: 0
    property real dragGlobalY: 0
    property string dropTargetPath: ""
    property string dropTargetLabel: ""
    property int dropTargetListIdx: -1
    property string dropTargetNavName: ""
    property string dropTargetCrumbPath: ""

    // Per-Tab State: each tab stores { section, history: [...], histIdx: 0 }
    property var explorerTabs: [({ section: root.explorerSection, history: [root.explorerSection], histIdx: 0 })]
    property int activeTabIndex: 0

    readonly property var currentTabObj: (activeTabIndex >= 0 && activeTabIndex < explorerTabs.length) ? explorerTabs[activeTabIndex] : ({ section: "Este equipo", history: ["Este equipo"], histIdx: 0 })
    readonly property bool canGoBack: currentTabObj.histIdx > 0
    readonly property bool canGoForward: currentTabObj.histIdx < (currentTabObj.history.length - 1)

    Timer {
        id: expToastTimer
        interval: 2800; repeat: false
        onTriggered: root.statusToast = ""
    }

    function showExpToast(msg) {
        statusToast = msg;
        expToastTimer.restart();
    }

    function syncSharedClipboardFromDisk() {
        try {
            var cl = JSON.parse(bridge.getSharedClipboardJson());
            if (cl && Array.isArray(cl.paths)) {
                clipboardPaths = cl.paths;
                clipboardIsCut = (cl.mode === "cut");
            }
        } catch (e) {}
    }

    function writeClipboard(paths, isCut) {
        clipboardPaths = paths.slice();
        clipboardIsCut = isCut;
        bridge.setSharedClipboardJson(JSON.stringify(clipboardPaths), isCut);
        if (!isCut && paths.length > 0) bridge.copyTextToClipboard(paths.join("\n"));
    }

    function isPathSelected(p) {
        return selectedPaths.indexOf(p) !== -1;
    }

    function clearSelection() {
        selectedPaths = [];
        selectedObj = null;
        selectionAnchorIdx = -1;
    }

    function setSingleSelection(itemObj, idx) {
        if (!itemObj) { clearSelection(); return; }
        selectedPaths = [itemObj.path];
        selectedObj = itemObj;
        selectionAnchorIdx = idx;
    }

    function syncSelectedObjFromPaths() {
        if (selectedPaths.length === 0) { selectedObj = null; return; }
        var lastP = selectedPaths[selectedPaths.length - 1];
        var arr = filteredItems || [];
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].path === lastP) { selectedObj = arr[i]; return; }
        }
        selectedObj = null;
    }

    function openPropertiesForPath(targetPath, fallbackIcon) {
        if (!targetPath) return;
        try {
            var data = JSON.parse(bridge.getItemPropertiesJson(targetPath));
            if (data && data.path) {
                data.icon = fallbackIcon || (data.isDir ? "folder.svg" : "fluent-document.svg");
                expPropsData = data;
                expPropsOpen = true;
            }
        } catch (e) {}
    }

    function openNewTab(section) {
        if (explorerTabs.length >= 8) return;
        var t = explorerTabs.slice();
        var sec = section || "Este equipo";
        t.push({ section: sec, history: [sec], histIdx: 0 });
        explorerTabs = t;
        activeTabIndex = t.length - 1;
        navigateExplorer(sec, false);
    }

    function closeTabAt(idx) {
        if (explorerTabs.length <= 1) {
            bridge.closeWindow();
            return;
        }
        var t = explorerTabs.slice();
        t.splice(idx, 1);
        explorerTabs = t;
        activeTabIndex = Math.min(activeTabIndex, t.length - 1);
        navigateExplorer(explorerTabs[activeTabIndex].section, false);
    }

    function goBack() {
        if (!canGoBack) return;
        var t = explorerTabs.slice();
        var cur = Object.assign({}, t[activeTabIndex]);
        cur.histIdx -= 1;
        cur.section = cur.history[cur.histIdx];
        t[activeTabIndex] = cur;
        explorerTabs = t;
        navigateExplorer(cur.section, false);
    }

    function goForward() {
        if (!canGoForward) return;
        var t = explorerTabs.slice();
        var cur = Object.assign({}, t[activeTabIndex]);
        cur.histIdx += 1;
        cur.section = cur.history[cur.histIdx];
        t[activeTabIndex] = cur;
        explorerTabs = t;
        navigateExplorer(cur.section, false);
    }

    function showExpCtx(mx, my, kindStr, itemObj) {
        openDropdown = "";
        expCtxKind = kindStr;
        expCtxTargetObj = itemObj || null;
        if (kindStr === "item" && itemObj) {
            if (!isPathSelected(itemObj.path)) {
                selectedPaths = [itemObj.path];
            }
            selectedObj = itemObj;
        }
        expCtxX = Math.max(12, Math.min(root.width - 278, mx));
        expCtxY = Math.max(12, Math.min(root.height - 340, my));
        expCtxOpen = true;
    }

    function createAndSelectItem(kind) {
        var targetBase = (explorerMode === "thispc") ? "Escritorio" : explorerRealPath;
        var created = bridge.createNewItemPath(targetBase, kind);
        if (created !== "") {
            if (explorerMode === "thispc") {
                navigateExplorer("Escritorio", true);
            } else {
                refreshExplorer();
            }
            var arr = filteredItems || [];
            for (var i = 0; i < arr.length; i++) {
                if (arr[i].path === created) {
                    setSingleSelection(arr[i], i);
                    break;
                }
            }
            showExpToast(kind === "folder" ? "Carpeta creada" : "Archivo creado");
        }
    }

    function execExpDropdown(act) {
        openDropdown = "";
        if (act === "new_folder") createAndSelectItem("folder");
        else if (act === "new_doc") createAndSelectItem("doc");
        else if (act === "new_md") createAndSelectItem("md");
        else if (act === "s_name") { explorerSortBy = "name"; refreshExplorer(); }
        else if (act === "s_date") { explorerSortBy = "date"; refreshExplorer(); }
        else if (act === "s_type") { explorerSortBy = "type"; refreshExplorer(); }
        else if (act === "s_size") { explorerSortBy = "size"; refreshExplorer(); }
        else if (act === "s_asc")  { explorerSortAsc = true; refreshExplorer(); }
        else if (act === "s_desc") { explorerSortAsc = false; refreshExplorer(); }
        else if (act === "v_details") explorerViewMode = "details";
        else if (act === "v_tiles")   explorerViewMode = "tiles";
        else if (act === "v_large")   explorerViewMode = "large";
        else if (act === "v_hidden") {
            showHiddenFiles = !showHiddenFiles;
            bridge.setConfigValue("explorerShowHidden", showHiddenFiles ? "true" : "false");
            refreshExplorer();
            showExpToast(showHiddenFiles ? "Mostrando elementos ocultos" : "Elementos ocultos desactivados");
        } else if (act === "m_selall" && explorerMode === "dir") {
            var allP = [];
            var items = filteredItems || [];
            for (var i = 0; i < items.length; i++) allP.push(items[i].path);
            selectedPaths = allP;
            syncSelectedObjFromPaths();
        } else if (act === "m_invert" && explorerMode === "dir") {
            var invP = [];
            var items2 = filteredItems || [];
            for (var j = 0; j < items2.length; j++) {
                if (selectedPaths.indexOf(items2[j].path) === -1) invP.push(items2[j].path);
            }
            selectedPaths = invP;
            syncSelectedObjFromPaths();
        } else if (act === "m_term") {
            bridge.openTerminalIn(explorerRealPath);
        } else if (act === "m_copycur") {
            bridge.copyTextToClipboard(explorerRealPath);
            showExpToast("Ruta copiada al portapapeles");
        } else if (act === "m_zip" && selectedPaths.length > 0) {
            if (bridge.compressItemsToZipJson(JSON.stringify(selectedPaths))) {
                refreshExplorer();
                showExpToast("Archivo ZIP creado");
            }
        } else if (act === "m_props") {
            if (selectedObj) openPropertiesForPath(selectedObj.path, selectedObj.icon);
            else if (explorerMode === "dir") openPropertiesForPath(explorerRealPath, "folder.svg");
        }
    }

    function execExpCtxAction(a) {
        var it = selectedObj;
        var tgt = expCtxTargetObj;
        var selArr = selectedPaths.length > 0 ? selectedPaths.slice() : (it ? [it.path] : []);
        expCtxOpen = false;
        if (a === "open_trash") navigateExplorer("Papelera", true);
        else if (a === "empty_trash") { bridge.emptyTrash(); clearSelection(); refreshExplorer(); showExpToast("Papelera vaciada"); }
        else if (a === "restore_all") {
            var rc = bridge.restoreAllTrash();
            clearSelection(); refreshExplorer();
            if (rc > 0) showExpToast(rc + " elementos restaurados");
        } else if (a === "nav_open" && tgt) navigateExplorer(tgt.path || tgt.name, true);
        else if (a === "nav_tab" && tgt) openNewTab(tgt.path || tgt.name);
        else if (a === "nav_term" && tgt) bridge.openTerminalIn(tgt.path || tgt.name);
        else if (a === "nav_props" && tgt) openPropertiesForPath(bridge.getSpecialFolderPath(tgt.path || tgt.name), tgt.icon || "folder.svg");
        else if (a === "toggle_view") explorerViewMode = (explorerViewMode === "details" ? "tiles" : (explorerViewMode === "tiles" ? "large" : "details"));
        else if (a === "toggle_hidden") execExpDropdown("v_hidden");
        else if (a === "refresh") refreshExplorer();
        else if (a === "paste") {
            syncSharedClipboardFromDisk();
            if (clipboardPaths.length > 0 && bridge.pasteClipboardItemsJson(JSON.stringify(clipboardPaths), explorerRealPath, clipboardIsCut)) {
                if (clipboardIsCut) writeClipboard([], false);
                refreshExplorer();
                showExpToast("Elementos pegados");
            }
        } else if (a === "new_folder") createAndSelectItem("folder");
        else if (a === "new_doc") createAndSelectItem("doc");
        else if (a === "new_md") createAndSelectItem("md");
        else if (a === "term_here") bridge.openTerminalIn(explorerRealPath);
        else if (a === "restore_item" && selArr.length > 0) {
            if (bridge.restoreTrashItemsJson(JSON.stringify(selArr))) { clearSelection(); refreshExplorer(); showExpToast("Elementos restaurados"); }
        } else if (a === "del_perm" && selArr.length > 0) {
            if (bridge.deletePermanentlyJson(JSON.stringify(selArr))) { clearSelection(); refreshExplorer(); showExpToast("Eliminado permanentemente"); }
        } else if (a === "open" && it) {
            if (it.isDir) navigateExplorer(it.path, true);
            else bridge.openFileOrUrl(it.path);
        } else if (a === "open_tab" && it && it.isDir) {
            openNewTab(it.path);
        } else if (a === "term_item" && it) {
            bridge.openTerminalIn(it.path);
        } else if (a === "extract_item" && it && it.isArchive) {
            if (bridge.extractArchive(it.path)) { refreshExplorer(); showExpToast("Archivo extraído"); }
        } else if (a === "set_wp" && it && it.isImage) {
            if (bridge.setAsWallpaper(it.path)) showExpToast("Establecido como fondo de escritorio");
        } else if (a === "zip_item" && selArr.length > 0) {
            if (bridge.compressItemsToZipJson(JSON.stringify(selArr))) { refreshExplorer(); showExpToast("Comprimido en archivo ZIP"); }
        } else if (a === "copy_path" && selArr.length > 0) {
            bridge.copyTextToClipboard(selArr.join("\n"));
            showExpToast("Ruta copiada");
        } else if (a === "props" && it) {
            openPropertiesForPath(it.path, it.icon);
        }
    }

    function execExpQuickAction(id) {
        expCtxOpen = false;
        if (!selectedObj && selectedPaths.length === 0) return;
        if (id === "cut") {
            writeClipboard(selectedPaths, true);
            showExpToast(selectedPaths.length + " elemento(s) cortado(s)");
        } else if (id === "copy") {
            writeClipboard(selectedPaths, false);
            showExpToast(selectedPaths.length + " elemento(s) copiado(s)");
        } else if (id === "rename" && selectedObj && selectedPaths.length === 1) {
            renameField.text = selectedObj.name;
            renamingActive = true;
            renameField.forceActiveFocus();
            renameField.selectAll();
        } else if (id === "delete" && selectedPaths.length > 0) {
            if (bridge.trashItemsJson(JSON.stringify(selectedPaths))) {
                clearSelection();
                refreshExplorer();
                showExpToast("Movido a la Papelera");
            }
        }
    }

    // Unified Drag-and-Drop Resolver (checks Sidebar, Breadcrumbs & Current View Subfolders!)
    function updateDragTargets(gx, gy) {
        dragGlobalX = gx;
        dragGlobalY = gy;
        dropTargetPath = "";
        dropTargetLabel = "";
        dropTargetListIdx = -1;
        dropTargetNavName = "";
        dropTargetCrumbPath = "";

        // 1. Check Left Sidebar Drop Targets (including Papelera!)
        var navP = root.mapToItem(navCol, gx, gy);
        if (navP.x >= 0 && navP.x <= navCol.width && navP.y >= 0 && navP.y <= navCol.height) {
            var nKids = navCol.children;
            for (var ni = 0; ni < nKids.length; ni++) {
                var nc = nKids[ni];
                if (nc.navName && nc.navName !== "" && nc.navName !== "Este equipo" &&
                    navP.x >= nc.x && navP.x <= nc.x + nc.width && navP.y >= nc.y && navP.y <= nc.y + nc.height) {
                    var destPath = (nc.navName === "Papelera") ? "Papelera" : bridge.getSpecialFolderPath(nc.navName);
                    if (destPath !== explorerRealPath) {
                        dropTargetNavName = nc.navName;
                        dropTargetPath = destPath;
                        dropTargetLabel = (nc.navName === "Papelera") ? "Mover a Papelera de reciclaje" : ("Mover a " + nc.navName);
                        return;
                    }
                }
            }
        }

        // 2. Check Address Bar Breadcrumb Drop Targets (move items up into parent folder!)
        if (!editingAddress && explorerMode === "dir") {
            var crP = root.mapToItem(crumbRow, gx, gy);
            if (crP.x >= 0 && crP.x <= crumbRow.width && crP.y >= 0 && crP.y <= crumbRow.height) {
                var cKids = crumbRow.children;
                for (var ci = 0; ci < cKids.length; ci++) {
                    var cc = cKids[ci];
                    if (cc.crumbPath && cc.crumbPath !== "" && cc.crumbPath !== "Este equipo" && cc.crumbPath !== explorerRealPath &&
                        crP.x >= cc.x && crP.x <= cc.x + cc.width && crP.y >= cc.y && crP.y <= cc.y + cc.height) {
                        dropTargetCrumbPath = cc.crumbPath;
                        dropTargetPath = cc.crumbPath;
                        dropTargetLabel = "Mover a " + cc.crumbLabel;
                        return;
                    }
                }
            }
        }

        // 3. Check Subfolder Drop Targets inside Current Directory View
        if (explorerMode === "dir" && !isTrashFolder) {
            var items = filteredItems || [];
            if (explorerViewMode === "details") {
                var dp = root.mapToItem(detailsMarquee, gx, gy);
                if (dp.x >= 0 && dp.x <= detailsMarquee.width && dp.y >= 0 && dp.y <= detailsMarquee.height) {
                    var hit = detailsMarquee.hitTest(dp.x, dp.y);
                    if (hit >= 0 && hit < items.length && items[hit].isDir && dragSourcePaths.indexOf(items[hit].path) === -1) {
                        dropTargetListIdx = hit;
                        dropTargetPath = items[hit].path;
                        dropTargetLabel = "Mover a " + items[hit].name;
                        return;
                    }
                }
            } else {
                var tp = root.mapToItem(tilesMarquee, gx, gy);
                if (tp.x >= 0 && tp.x <= tilesMarquee.width && tp.y >= 0 && tp.y <= tilesMarquee.height) {
                    var hit2 = tilesMarquee.hitTest(tp.x, tp.y);
                    if (hit2 >= 0 && hit2 < items.length && items[hit2].isDir && dragSourcePaths.indexOf(items[hit2].path) === -1) {
                        dropTargetListIdx = hit2;
                        dropTargetPath = items[hit2].path;
                        dropTargetLabel = "Mover a " + items[hit2].name;
                        return;
                    }
                }
            }
        }
    }

    function finishItemDrag() {
        if (draggingItems && dropTargetPath !== "" && dragSourcePaths.length > 0) {
            var cnt = bridge.moveItemsToDirJson(JSON.stringify(dragSourcePaths), dropTargetPath);
            if (cnt > 0) {
                var lbl = dropTargetLabel;
                clearSelection();
                refreshExplorer();
                showExpToast(cnt + " elemento(s): " + lbl);
            }
        }
        draggingItems = false;
        dragSourcePaths = [];
        dropTargetPath = "";
        dropTargetLabel = "";
        dropTargetListIdx = -1;
        dropTargetNavName = "";
        dropTargetCrumbPath = "";
    }

    Keys.onPressed: (event) => {
        if (root.editingAddress || root.renamingActive || expSearchInput.activeFocus) return;
        if (event.key === Qt.Key_F5) {
            root.refreshExplorer();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
            addrInput.text = root.explorerRealPath;
            root.editingAddress = true;
            addrInput.forceActiveFocus();
            addrInput.selectAll();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            expSearchInput.forceActiveFocus();
            expSearchInput.selectAll();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_T) {
            root.openNewTab("Este equipo");
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_W) {
            root.closeTabAt(root.activeTabIndex);
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_H) {
            root.execExpDropdown("v_hidden");
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_N && !root.isTrashFolder) {
            root.createAndSelectItem("folder");
            event.accepted = true;
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Left) {
            root.goBack();
            event.accepted = true;
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Right) {
            root.goForward();
            event.accepted = true;
        } else if (((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Up) || event.key === Qt.Key_Backspace) {
            if (root.explorerMode !== "thispc") root.navigateExplorer(bridge.getParentDir(root.explorerRealPath), true);
            event.accepted = true;
        } else if ((event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            if (root.selectedObj) root.openPropertiesForPath(root.selectedObj.path, root.selectedObj.icon);
            else if (root.explorerMode === "dir") root.openPropertiesForPath(root.explorerRealPath, "folder.svg");
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_A && root.explorerMode === "dir") {
            root.execExpDropdown("m_selall");
            event.accepted = true;
        } else if (event.key === Qt.Key_F2 && root.selectedPaths.length === 1 && root.selectedObj && !root.isTrashFolder) {
            renameField.text = root.selectedObj.name;
            root.renamingActive = true;
            renameField.forceActiveFocus();
            renameField.selectAll();
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete && root.selectedPaths.length > 0) {
            var okDel = root.isTrashFolder
                        ? bridge.deletePermanentlyJson(JSON.stringify(root.selectedPaths))
                        : bridge.trashItemsJson(JSON.stringify(root.selectedPaths));
            if (okDel) {
                root.clearSelection();
                root.refreshExplorer();
                root.showExpToast(root.isTrashFolder ? "Eliminado permanentemente" : "Movido a la Papelera");
            }
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && root.selectedPaths.length > 0 && !root.isTrashFolder) {
            root.writeClipboard(root.selectedPaths, false);
            root.showExpToast(root.selectedPaths.length + " elemento(s) copiado(s)");
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_X && root.selectedPaths.length > 0 && !root.isTrashFolder) {
            root.writeClipboard(root.selectedPaths, true);
            root.showExpToast(root.selectedPaths.length + " elemento(s) cortado(s)");
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V && root.explorerMode === "dir" && !root.isTrashFolder) {
            root.execExpCtxAction("paste");
            event.accepted = true;
        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.selectedObj) {
            if (root.selectedObj.isDir) root.navigateExplorer(root.selectedObj.path, true);
            else bridge.openFileOrUrl(root.selectedObj.path);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.openDropdown = "";
            root.expCtxOpen = false;
            root.expPropsOpen = false;
            event.accepted = true;
        }
    }

    component WinSvg : Image {
        property string iconFile: "explorer.svg"
        property string iconUrl: ""
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: iconUrl !== "" ? iconUrl : (assetDirUrl + iconFile)
        sourceSize.width: Math.max(24, Math.round(width * 2))
        sourceSize.height: Math.max(24, Math.round(height * 2))
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true
        antialiasing: true
    }

    readonly property var breadcrumbSegments: {
        if (root.explorerMode === "thispc" || root.explorerRealPath === "Este equipo") {
            return [{ label: "Este equipo", path: "Este equipo" }];
        }
        if (root.isTrashFolder) {
            return [{ label: "Este equipo", path: "Este equipo" }, { label: "Papelera de reciclaje", path: "Papelera" }];
        }
        var segs = [{ label: "Este equipo", path: "Este equipo" }, { label: "X64 LIOS (C:)", path: "/" }];
        var p = String(root.explorerRealPath || "");
        if (p !== "/" && p.indexOf("/") === 0) {
            var parts = p.split("/");
            var acc = "";
            for (var i = 1; i < parts.length; i++) {
                if (parts[i] === "") continue;
                acc += "/" + parts[i];
                segs.push({ label: parts[i], path: acc });
            }
        }
        return segs;
    }

    readonly property var filteredItems: {
        if (root.deepSearchActive && root.searchFilter.trim() !== "") {
            return root.deepSearchItems || [];
        }
        var q = root.searchFilter.trim().toLowerCase();
        var src = root.explorerItems || [];
        if (q === "") return src;
        var out = [];
        for (var i = 0; i < src.length; i++) {
            if (String(src[i].name || "").toLowerCase().indexOf(q) !== -1) out.push(src[i]);
        }
        return out;
    }

    function runDeepSearch() {
        var q = searchFilter.trim();
        if (q === "") {
            deepSearchActive = false;
            deepSearchItems = [];
            return;
        }
        try {
            var res = JSON.parse(bridge.searchDirectoryJson(explorerRealPath, q, showHiddenFiles));
            deepSearchItems = res.items || [];
            deepSearchActive = true;
            if (explorerMode === "thispc") explorerMode = "dir";
            showExpToast("Búsqueda recursiva: " + deepSearchItems.length + " coincidencias");
        } catch (e) {}
    }

    function tabDisplayName(sec) {
        if (!sec || sec === "") return "Este equipo";
        if (sec === "/") return "X64 LIOS (C:)";
        if (sec.indexOf("/") !== -1) {
            var parts = sec.split("/");
            var last = parts[parts.length - 1];
            return last !== "" ? last : "X64 LIOS (C:)";
        }
        return sec;
    }

    function refreshExplorer() {
        try {
            syncSharedClipboardFromDisk();
            explorerDrives = JSON.parse(bridge.getDrivesJson());
            var res = JSON.parse(bridge.listDirectoryExJson(explorerSection, explorerSortBy, explorerSortAsc, showHiddenFiles));
            explorerMode = res.mode;
            explorerRealPath = res.path;
            isTrashFolder = Boolean(res.isTrash);
            explorerItems = res.items || [];
            explorerItemCount = res.count || 0;
        } catch (e) {}
    }

    function navigateExplorer(target, pushHistory) {
        openDropdown = "";
        expCtxOpen = false;
        renamingActive = false;
        editingAddress = false;
        clearSelection();
        hoveredItemIdx = -1;
        searchFilter = "";
        deepSearchActive = false;
        deepSearchItems = [];
        expSearchInput.text = "";
        explorerSection = target;

        var tabsCopy = explorerTabs.slice();
        var cur = Object.assign({}, tabsCopy[activeTabIndex] || { section: target, history: [target], histIdx: 0 });
        cur.section = target;
        if (pushHistory !== false) {
            var h = (cur.history || []).slice(0, cur.histIdx + 1);
            if (h.length === 0 || h[h.length - 1] !== target) {
                h.push(target);
            }
            cur.history = h;
            cur.histIdx = h.length - 1;
        }
        tabsCopy[activeTabIndex] = cur;
        explorerTabs = tabsCopy;
        refreshExplorer();
    }

    function toggleColumnSort(col) {
        if (explorerSortBy === col) {
            explorerSortAsc = !explorerSortAsc;
        } else {
            explorerSortBy = col;
            explorerSortAsc = true;
        }
        refreshExplorer();
    }

    Component.onCompleted: {
        try {
            var cfg = JSON.parse(bridge.getConfigJson());
            if (cfg.explorerShowHidden !== undefined) showHiddenFiles = Boolean(cfg.explorerShowHidden);
        } catch (e) {}
        refreshExplorer();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // [A] Authentic Windows 11 26H2 Multi-Tab Strip (#0f0f0f)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#0f0f0f"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                Repeater {
                    model: root.explorerTabs
                    delegate: Rectangle {
                        Layout.preferredWidth: Math.min(220, Math.max(128, (root.width - 160) / root.explorerTabs.length))
                        Layout.preferredHeight: 33
                        Layout.alignment: Qt.AlignBottom
                        radius: 8
                        color: index === root.activeTabIndex ? "#202020" : (tabHov.containsMouse ? "#181818" : "transparent")

                        Rectangle {
                            visible: index === root.activeTabIndex
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 8; color: "#202020"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8
                            WinSvg {
                                width: 16; height: 16
                                iconFile: modelData.section === "Este equipo" ? "thispc.svg" : (modelData.section === "Papelera" ? "trash.svg" : "folder.svg")
                            }
                            Text {
                                text: root.tabDisplayName(modelData.section)
                                color: index === root.activeTabIndex ? "#f5f5f5" : "#a8a8a8"
                                font.pixelSize: 12
                                font.weight: index === root.activeTabIndex ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                width: 20; height: 20; radius: 4
                                color: tabCloseHov.containsMouse ? "#28ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 10; height: 10; iconFile: "fluent-dismiss.svg"; opacity: 0.8 }
                                MouseArea {
                                    id: tabCloseHov; anchors.fill: parent; hoverEnabled: true
                                    onClicked: root.closeTabAt(index)
                                }
                            }
                        }

                        MouseArea {
                            id: tabHov; anchors.fill: parent; anchors.rightMargin: 28; hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.MiddleButton) {
                                    root.closeTabAt(index);
                                } else {
                                    root.activeTabIndex = index;
                                    root.navigateExplorer(root.explorerTabs[index].section, false);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 5
                    Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 3
                    color: newTabHov.containsMouse ? "#22ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-add.svg" }
                    MouseArea {
                        id: newTabHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.openNewTab("Este equipo")
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // [B] Navigation, Interactive Clickable Breadcrumbs & Live/Recursive Search Row (#202020)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#202020"

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 6

                Rectangle {
                    width: 32; height: 32; radius: 5; color: backHov.containsMouse && root.canGoBack ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-left.svg"; opacity: root.canGoBack ? 1.0 : 0.35 }
                    MouseArea { id: backHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.goBack() }
                }

                Rectangle {
                    width: 32; height: 32; radius: 5; color: fwdHov.containsMouse && root.canGoForward ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-right.svg"; opacity: root.canGoForward ? 1.0 : 0.35 }
                    MouseArea { id: fwdHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.goForward() }
                }

                Rectangle {
                    width: 32; height: 32; radius: 5; color: upHov.containsMouse && root.explorerMode !== "thispc" ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-up.svg"; opacity: root.explorerMode !== "thispc" ? 1.0 : 0.35 }
                    MouseArea {
                        id: upHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (root.explorerMode !== "thispc") root.navigateExplorer(bridge.getParentDir(root.explorerRealPath), true)
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 5; color: refHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "fluent-refresh.svg" }
                    MouseArea { id: refHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.refreshExplorer() }
                }

                // Interactive Clickable Breadcrumb & Drop-Target Address Bar (click empty right space -> type path!)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 5
                    clip: true
                    color: root.editingAddress ? "#171717" : "#2b2b2b"
                    border.color: root.editingAddress ? "#4cc2ff" : "#1fffffff"
                    border.width: 1

                    // Background click switches to direct text path editing
                    MouseArea {
                        visible: !root.editingAddress
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            addrInput.text = root.explorerRealPath;
                            root.editingAddress = true;
                            addrInput.forceActiveFocus();
                            addrInput.selectAll();
                        }
                    }

                    Row {
                        id: crumbRow
                        visible: !root.editingAddress
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 8
                        spacing: 2

                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            iconFile: root.explorerMode === "thispc" ? "thispc.svg" : (root.isTrashFolder ? "trash.svg" : "folder.svg")
                        }
                        Item { width: 4; height: 1 }

                        Repeater {
                            model: root.breadcrumbSegments
                            delegate: Row {
                                readonly property string crumbPath: modelData.path
                                readonly property string crumbLabel: modelData.label
                                readonly property bool isDrop: root.draggingItems && root.dropTargetCrumbPath === modelData.path
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                WinSvg {
                                    visible: index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10; height: 10; iconFile: "fluent-chevron-right.svg"; opacity: 0.65
                                }

                                Rectangle {
                                    width: Math.min(150, segTxt.implicitWidth + 14)
                                    height: 26; radius: 4
                                    color: parent.isDrop ? "#550078d4" : (segHov.containsMouse ? "#28ffffff" : "transparent")
                                    border.color: parent.isDrop ? "#4cc2ff" : "transparent"; border.width: 1
                                    Text {
                                        id: segTxt
                                        anchors.centerIn: parent
                                        width: Math.min(136, implicitWidth)
                                        text: modelData.label
                                        color: "#f2f2f2"; font.pixelSize: 12; elide: Text.ElideRight
                                    }
                                    MouseArea {
                                        id: segHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.navigateExplorer(modelData.path, true)
                                    }
                                }
                            }
                        }
                    }

                    TextInput {
                        id: addrInput
                        visible: root.editingAddress
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; selectionColor: "#0067c0"; clip: true
                        Keys.onEscapePressed: root.editingAddress = false
                        onActiveFocusChanged: if (!activeFocus) root.editingAddress = false
                        onAccepted: {
                            var target = text.trim();
                            root.editingAddress = false;
                            if (target !== "") root.navigateExplorer(target, true);
                        }
                    }
                }

                // Live & Recursive Search Box (Clipped, Responsive, Never Overflows!)
                Rectangle {
                    Layout.preferredWidth: root.width < 820 ? 190 : 260
                    Layout.preferredHeight: 34
                    radius: 5
                    clip: true
                    color: expSearchInput.activeFocus ? "#171717" : "#2b2b2b"
                    border.color: expSearchInput.activeFocus ? "#4cc2ff" : "#1fffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 6
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                            Text {
                                visible: expSearchInput.text === ""
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                text: "Buscar en " + root.tabDisplayName(root.explorerSection)
                                color: "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight
                            }
                            TextInput {
                                id: expSearchInput
                                anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                onTextChanged: {
                                    root.searchFilter = text;
                                    if (text.trim() === "") {
                                        root.deepSearchActive = false;
                                        root.deepSearchItems = [];
                                    }
                                }
                                onAccepted: root.runDeepSearch()
                                Keys.onEscapePressed: { text = ""; root.deepSearchActive = false; root.forceActiveFocus(); }
                            }
                        }

                        // Recursive Search Trigger (Enter or Click)
                        Rectangle {
                            visible: expSearchInput.text.trim() !== ""
                            width: 24; height: 22; radius: 4
                            color: root.deepSearchActive ? "#444cc2ff" : (dsHov.containsMouse ? "#28ffffff" : "transparent")
                            WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "fluent-search.svg" }
                            MouseArea {
                                id: dsHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.runDeepSearch()
                            }
                        }

                        WinSvg {
                            width: 13; height: 13
                            iconFile: expSearchInput.text !== "" ? "fluent-dismiss.svg" : "fluent-search.svg"
                            opacity: 0.8
                            MouseArea {
                                anchors.fill: parent
                                enabled: expSearchInput.text !== ""
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { expSearchInput.text = ""; root.deepSearchActive = false; root.deepSearchItems = []; root.refreshExplorer(); }
                            }
                        }
                    }
                }
            }
        }

        // [C] Authentic Windows 11 26H2 Functional Command Bar (#1c1c1c)
        Rectangle {
            id: cmdBarRect
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: "#1c1c1c"
            border.color: "#16ffffff"
            border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 5

                // "Nuevo ∨" Button
                Rectangle {
                    id: newCmdBtn
                    readonly property bool canNew: !root.isTrashFolder
                    width: 94; height: 32; radius: 5
                    opacity: canNew ? 1.0 : 0.38
                    color: canNew && (root.openDropdown === "new" || newBtnHov.containsMouse) ? "#28ffffff" : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 17; height: 17; iconFile: "fluent-add-circle.svg" }
                        Text { text: "Nuevo"; color: "#f2f2f2"; font.pixelSize: 12 }
                        WinSvg { width: 11; height: 11; iconFile: "fluent-chevron-down.svg"; opacity: 0.8 }
                    }
                    MouseArea {
                        id: newBtnHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canNew; cursorShape: Qt.PointingHandCursor
                        onClicked: root.openDropdown = (root.openDropdown === "new" ? "" : "new")
                    }
                }

                Rectangle { width: 1; height: 20; color: "#22ffffff" }

                // Cut
                Rectangle {
                    readonly property bool canAct: root.selectedPaths.length > 0 && !root.isTrashFolder
                    width: 34; height: 32; radius: 5
                    color: cutHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-cut.svg" }
                    MouseArea {
                        id: cutHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpQuickAction("cut")
                    }
                }

                // Copy
                Rectangle {
                    readonly property bool canAct: root.selectedPaths.length > 0 && !root.isTrashFolder
                    width: 34; height: 32; radius: 5
                    color: copyHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-copy.svg" }
                    MouseArea {
                        id: copyHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpQuickAction("copy")
                    }
                }

                // Paste
                Rectangle {
                    readonly property bool canAct: root.clipboardPaths.length > 0 && root.explorerMode === "dir" && !root.isTrashFolder
                    width: 34; height: 32; radius: 5
                    color: pasteHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-paste.svg" }
                    MouseArea {
                        id: pasteHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpCtxAction("paste")
                    }
                }

                // Rename (F2)
                Rectangle {
                    readonly property bool canAct: root.selectedPaths.length === 1 && root.selectedObj !== null && !root.isTrashFolder
                    width: 34; height: 32; radius: 5
                    color: renHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-rename.svg" }
                    MouseArea {
                        id: renHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpQuickAction("rename")
                    }
                }

                // Compress to ZIP (only active when 1+ items selected!)
                Rectangle {
                    readonly property bool canAct: root.selectedPaths.length > 0 && !root.isTrashFolder
                    width: 34; height: 32; radius: 5
                    color: zipHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-folder-zip.svg" }
                    MouseArea {
                        id: zipHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpDropdown("m_zip")
                    }
                }

                // Delete (Supr)
                Rectangle {
                    readonly property bool canAct: root.selectedPaths.length > 0
                    width: 34; height: 32; radius: 5
                    color: delHov.containsMouse && canAct ? "#24ffffff" : "transparent"
                    opacity: canAct ? 1.0 : 0.38
                    WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-delete.svg" }
                    MouseArea {
                        id: delHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canAct; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var okD = root.isTrashFolder
                                      ? bridge.deletePermanentlyJson(JSON.stringify(root.selectedPaths))
                                      : bridge.trashItemsJson(JSON.stringify(root.selectedPaths));
                            if (okD) {
                                root.clearSelection();
                                root.refreshExplorer();
                                root.showExpToast(root.isTrashFolder ? "Eliminado permanentemente" : "Movido a la Papelera");
                            }
                        }
                    }
                }

                Rectangle { width: 1; height: 20; color: "#22ffffff" }

                // "Ordenar ∨" Button
                Rectangle {
                    id: sortCmdBtn
                    width: 92; height: 32; radius: 5
                    color: (root.openDropdown === "sort" || sortBtnHov.containsMouse) ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 16; height: 16; iconFile: "fluent-arrow-sort.svg" }
                        Text { text: "Ordenar"; color: "#f0f0f0"; font.pixelSize: 12 }
                        WinSvg { width: 11; height: 11; iconFile: "fluent-chevron-down.svg"; opacity: 0.8 }
                    }
                    MouseArea {
                        id: sortBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.openDropdown = (root.openDropdown === "sort" ? "" : "sort")
                    }
                }

                // "Ver ∨" Button
                Rectangle {
                    id: viewCmdBtn
                    width: 74; height: 32; radius: 5
                    color: (root.openDropdown === "view" || viewBtnHov.containsMouse) ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 16; height: 16; iconFile: root.explorerViewMode === "details" ? "fluent-apps-list.svg" : "fluent-grid.svg" }
                        Text { text: "Ver"; color: "#f0f0f0"; font.pixelSize: 12 }
                        WinSvg { width: 11; height: 11; iconFile: "fluent-chevron-down.svg"; opacity: 0.8 }
                    }
                    MouseArea {
                        id: viewBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.openDropdown = (root.openDropdown === "view" ? "" : "view")
                    }
                }

                // "Más (...)" Menu Button (Select All, Invert, Terminal Here, Properties)
                Rectangle {
                    id: moreCmdBtn
                    width: 34; height: 32; radius: 5
                    color: (root.openDropdown === "more" || moreBtnHov.containsMouse) ? "#24ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: "•••"; color: "#e8e8e8"; font.pixelSize: 11 }
                    MouseArea {
                        id: moreBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.openDropdown = (root.openDropdown === "more" ? "" : "more")
                    }
                }

                // Recycle Bin Special Action Buttons (Empty Trash / Restore Selected / Restore All)
                Rectangle {
                    visible: root.isTrashFolder && root.selectedPaths.length > 0
                    width: 158; height: 30; radius: 5
                    color: resSelH.containsMouse ? "#384cc2ff" : "#244cc2ff"
                    border.color: "#4cc2ff"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 14; height: 14; iconFile: "fluent-arrow-undo.svg" }
                        Text { text: "Restaurar (" + root.selectedPaths.length + ")"; color: "#ffffff"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: resSelH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpCtxAction("restore_item")
                    }
                }

                Rectangle {
                    visible: root.isTrashFolder && root.explorerItems.length > 0 && root.selectedPaths.length === 0
                    width: 138; height: 30; radius: 5
                    color: resAllH.containsMouse ? "#383838" : "#2b2b2b"
                    border.color: "#24ffffff"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 14; height: 14; iconFile: "fluent-arrow-undo.svg" }
                        Text { text: "Restaurar todo"; color: "#f2f2f2"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: resAllH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpCtxAction("restore_all")
                    }
                }

                Rectangle {
                    visible: root.isTrashFolder && root.explorerItems.length > 0
                    width: 144; height: 30; radius: 5
                    color: emptyTrHov.containsMouse ? "#c42b1c" : "#2b2b2b"
                    border.color: "#24ffffff"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        WinSvg { width: 14; height: 14; iconFile: "fluent-delete.svg" }
                        Text { text: "Vaciar papelera"; color: "#f2f2f2"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: emptyTrHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.execExpCtxAction("empty_trash")
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Inline Rename Bar (F2 or Rename)
        Rectangle {
            visible: root.renamingActive
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: "#232323"
            border.color: "#4cc2ff"; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                WinSvg { width: 16; height: 16; iconFile: "fluent-rename.svg" }
                Text { text: "Nuevo nombre:"; color: "#e6e6e6"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 4; color: "#151515"; border.color: "#4cc2ff"; border.width: 1; clip: true
                    TextInput {
                        id: renameField
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                        Keys.onEscapePressed: root.renamingActive = false
                        onAccepted: {
                            if (root.selectedPath !== "" && bridge.renameItem(root.selectedPath, text)) {
                                root.renamingActive = false;
                                root.clearSelection();
                                root.refreshExplorer();
                                root.showExpToast("Nombre cambiado");
                            }
                        }
                    }
                }
                Rectangle {
                    width: 78; height: 28; radius: 4; color: "#4cc2ff"
                    Text { anchors.centerIn: parent; text: "Guardar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: renameField.accepted() }
                }
                Rectangle {
                    width: 78; height: 28; radius: 4; color: "#2d2d2d"
                    Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f0f0f0"; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.renamingActive = false }
                }
            }
        }

        // [D] Split Navigation Pane (with Drop Targets & Full Right-Click Menus!) & Main Directory Surface
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            Rectangle {
                Layout.preferredWidth: 218; Layout.fillHeight: true; color: "#191919"
                Flickable {
                    anchors.fill: parent; anchors.margins: 8
                    contentWidth: width; contentHeight: navCol.implicitHeight + 12; clip: true

                    Column {
                        id: navCol
                        width: parent.width; spacing: 2

                        Repeater {
                            model: [
                                { icon: "folder-home.svg",      name: "Inicio" },
                                { icon: "folder-desktop.svg",   name: "Escritorio" },
                                { icon: "folder-download.svg",  name: "Descargas" },
                                { icon: "folder-documents.svg", name: "Documentos" },
                                { icon: "folder-images.svg",    name: "Imágenes" },
                                { icon: "folder-music.svg",     name: "Música" },
                                { icon: "folder-videos.svg",    name: "Vídeos" },
                                { icon: "folder.svg",           name: "Proyectos" },
                                { sep: true },
                                { icon: "thispc.svg",           name: "Este equipo" },
                                { icon: "drive-c.svg",          name: "X64 LIOS (C:)" },
                                { icon: "trash.svg",            name: "Papelera" }
                            ]
                            delegate: Item {
                                readonly property string navName: modelData.sep ? "" : modelData.name
                                readonly property bool isDrop: root.draggingItems && !modelData.sep && root.dropTargetNavName === modelData.name
                                width: navCol.width
                                height: modelData.sep ? 11 : 33

                                Rectangle {
                                    visible: Boolean(modelData.sep)
                                    anchors.centerIn: parent
                                    width: navCol.width - 16; height: 1; color: "#1cffffff"
                                }

                                Rectangle {
                                    visible: !modelData.sep
                                    anchors.fill: parent; radius: 5
                                    color: parent.isDrop ? (modelData.name === "Papelera" ? "#55c42b1c" : "#550078d4")
                                                         : (root.explorerSection === modelData.name ? "#2c2c2c" : (navHover.containsMouse ? "#222222" : "transparent"))
                                    border.color: parent.isDrop ? (modelData.name === "Papelera" ? "#ff7b72" : "#4cc2ff") : "transparent"
                                    border.width: parent.isDrop ? 1.5 : 0

                                    Rectangle {
                                        visible: root.explorerSection === modelData.name
                                        x: 2; anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 16; radius: 1.5; color: "#4cc2ff"
                                    }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 10
                                        WinSvg { width: 18; height: 18; iconFile: modelData.icon || "folder.svg" }
                                        Text { text: modelData.name || ""; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    MouseArea {
                                        id: navHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.MiddleButton) {
                                                root.openNewTab(modelData.name);
                                            } else if (mouse.button === Qt.RightButton) {
                                                var gp = navHover.mapToItem(root, mouse.x, mouse.y);
                                                if (modelData.name === "Papelera") {
                                                    root.showExpCtx(gp.x, gp.y, "trash_nav", modelData);
                                                } else {
                                                    root.showExpCtx(gp.x, gp.y, "nav_folder", modelData);
                                                }
                                            } else {
                                                root.expCtxOpen = false;
                                                root.navigateExplorer(modelData.name, true);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1cffffff" }

            // Main Content Area
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "#191919"

                MouseArea {
                    anchors.fill: parent; z: -1
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        root.openDropdown = "";
                        root.clearSelection();
                        if (mouse.button === Qt.RightButton && root.explorerMode === "dir") {
                            var gp = mapToItem(root, mouse.x, mouse.y);
                            root.showExpCtx(gp.x, gp.y, "bg", null);
                        } else {
                            root.expCtxOpen = false;
                        }
                    }
                }

                // VIEW A: ESTE EQUIPO (Folders + Real Mounted Drives with Right-Click & Middle-Click!)
                Flickable {
                    anchors.fill: parent; anchors.margins: 22
                    visible: root.explorerMode === "thispc"
                    contentWidth: width; contentHeight: thisPcCol.implicitHeight + 20; clip: true

                    Column {
                        id: thisPcCol
                        width: parent.width; spacing: 18

                        RowLayout {
                            width: parent.width; spacing: 8
                            WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-down.svg" }
                            Text { text: "Carpetas (6)"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }
                        }

                        Grid {
                            columns: root.width < 920 ? 2 : 3
                            rowSpacing: 10; columnSpacing: 14
                            Repeater {
                                model: [
                                    { name: "Escritorio", icon: "folder-desktop.svg",   sub: "Acceso directo local" },
                                    { name: "Descargas",  icon: "folder-download.svg",  sub: "Acceso directo local" },
                                    { name: "Documentos", icon: "folder-documents.svg", sub: "Acceso directo local" },
                                    { name: "Imágenes",   icon: "folder-images.svg",    sub: "Acceso directo local" },
                                    { name: "Música",     icon: "folder-music.svg",     sub: "Acceso directo local" },
                                    { name: "Vídeos",     icon: "folder-videos.svg",    sub: "Acceso directo local" }
                                ]
                                delegate: Rectangle {
                                    width: 258; height: 64; radius: 6
                                    color: folderHover.containsMouse ? "#262626" : "transparent"
                                    border.color: folderHover.containsMouse ? "#26ffffff" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                                        WinSvg { width: 44; height: 44; iconFile: modelData.icon }
                                        Column {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13 }
                                            Text { text: modelData.sub; color: "#9a9a9a"; font.pixelSize: 11 }
                                        }
                                    }
                                    MouseArea {
                                        id: folderHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.MiddleButton) root.openNewTab(modelData.name);
                                            else if (mouse.button === Qt.RightButton) {
                                                var gp = folderHover.mapToItem(root, mouse.x, mouse.y);
                                                root.showExpCtx(gp.x, gp.y, "nav_folder", modelData);
                                            } else root.navigateExplorer(modelData.name, true);
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width; spacing: 8
                            WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-down.svg" }
                            Text { text: "Dispositivos y unidades (" + root.explorerDrives.length + ")"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }
                        }

                        Flow {
                            width: parent.width; spacing: 14
                            Repeater {
                                model: root.explorerDrives
                                delegate: Rectangle {
                                    width: 318; height: 78; radius: 6
                                    color: driveHover.containsMouse ? "#262626" : "transparent"
                                    border.color: driveHover.containsMouse ? "#26ffffff" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                                        WinSvg { width: 44; height: 44; iconFile: modelData.icon }
                                        Column {
                                            Layout.fillWidth: true; spacing: 5
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; elide: Text.ElideRight; width: 235 }
                                            Rectangle {
                                                width: 230; height: 10; radius: 3; color: "#323232"; border.color: "#4a4a4a"
                                                Rectangle {
                                                    x: 1; y: 1; width: (parent.width - 2) * modelData.usedRatio; height: parent.height - 2; radius: 2
                                                    color: modelData.isCritical ? "#d13438" : "#4cc2ff"
                                                }
                                            }
                                            Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 11 }
                                        }
                                    }
                                    MouseArea {
                                        id: driveHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.MiddleButton) root.openNewTab(modelData.path);
                                            else if (mouse.button === Qt.RightButton) {
                                                var gp = driveHover.mapToItem(root, mouse.x, mouse.y);
                                                root.showExpCtx(gp.x, gp.y, "nav_folder", modelData);
                                            } else root.navigateExplorer(modelData.path, true);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // VIEW B1: DETAILS TABLE VIEW (Marquee Selection + Full Drag-and-Drop!)
                ColumnLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.topMargin: 8; spacing: 0
                    visible: root.explorerMode === "dir" && root.explorerViewMode === "details"

                    // Sortable Column Headers (click toggles asc/desc!)
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32; color: "#191919"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 14; spacing: 12
                            Text {
                                text: "Nombre" + (root.explorerSortBy === "name" ? (root.explorerSortAsc ? "  ▲" : "  ▼") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.fillWidth: true
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColumnSort("name") }
                            }
                            Text {
                                text: (root.isTrashFolder ? "Fecha de eliminación" : "Fecha de modificación") + (root.explorerSortBy === "date" ? (root.explorerSortAsc ? "  ▼" : "  ▲") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.preferredWidth: 155
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColumnSort("date") }
                            }
                            Text {
                                text: (root.deepSearchActive ? "Carpeta" : "Tipo") + (root.explorerSortBy === "type" ? (root.explorerSortAsc ? "  ▲" : "  ▼") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.preferredWidth: 150
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColumnSort("type") }
                            }
                            Text {
                                text: "Tamaño" + (root.explorerSortBy === "size" ? (root.explorerSortAsc ? "  ▼" : "  ▲") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 90
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColumnSort("size") }
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1cffffff" }
                    }

                    // Empty Folder Notice (still right-clickable!)
                    Item {
                        visible: root.filteredItems.length === 0
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: root.searchFilter !== "" ? "No se encontraron coincidencias" : (root.isTrashFolder ? "La Papelera de reciclaje está vacía" : "Esta carpeta está vacía")
                            color: "#8e8e8e"; font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                root.openDropdown = "";
                                if (mouse.button === Qt.RightButton) {
                                    var gp = mapToItem(root, mouse.x, mouse.y);
                                    root.showExpCtx(gp.x, gp.y, "bg", null);
                                } else root.expCtxOpen = false;
                            }
                        }
                    }

                    Item {
                        visible: root.filteredItems.length > 0
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true

                        Flickable {
                            id: detailsFlick
                            anchors.fill: parent
                            contentWidth: width; contentHeight: detailsCol.implicitHeight + 28
                            interactive: false; boundsBehavior: Flickable.StopAtBounds; clip: true
                            ScrollBar.vertical: ScrollBar { id: detVBar; policy: ScrollBar.AsNeeded; z: 30 }

                            Column {
                                id: detailsCol
                                width: detailsFlick.width - 12; spacing: 2

                                Repeater {
                                    model: root.filteredItems
                                    delegate: Rectangle {
                                        readonly property int itemIdx: index
                                        readonly property bool isSel: root.selectedPaths.indexOf(modelData.path) !== -1
                                        readonly property bool isHov: root.hoveredItemIdx === index
                                        readonly property bool isDrop: root.draggingItems && root.dropTargetListIdx === index
                                        readonly property bool isDragSrc: root.draggingItems && root.dragSourcePaths.indexOf(modelData.path) !== -1
                                        readonly property bool isCut: root.clipboardIsCut && root.clipboardPaths.indexOf(modelData.path) !== -1
                                        width: detailsCol.width; height: 34; radius: 4
                                        opacity: (isDragSrc || isCut) ? 0.48 : (modelData.isHidden ? 0.68 : 1.0)
                                        color: isDrop ? "#550078d4" : (isSel ? "#400078d4" : (isHov ? "#242424" : "transparent"))
                                        border.color: isDrop ? "#4cc2ff" : (isSel ? "#784cc2ff" : "transparent")
                                        border.width: isDrop ? 1.5 : 1

                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 14; spacing: 12
                                            RowLayout {
                                                spacing: 10; Layout.fillWidth: true
                                                WinSvg {
                                                    width: 20; height: 20
                                                    iconUrl: modelData.isImage ? modelData.fileUrl : ""
                                                    iconFile: modelData.icon || "fluent-document.svg"
                                                }
                                                Text {
                                                    text: modelData.name; color: "#f5f5f5"; font.pixelSize: 12
                                                    elide: Text.ElideRight; Layout.fillWidth: true
                                                }
                                            }
                                            Text { text: modelData.mtime || ""; color: "#a8a8a8"; font.pixelSize: 11; Layout.preferredWidth: 155 }
                                            Text { text: modelData.typeLabel || ""; color: "#a8a8a8"; font.pixelSize: 11; elide: Text.ElideRight; Layout.preferredWidth: 150 }
                                            Text { text: modelData.sizeLabel || ""; color: "#a8a8a8"; font.pixelSize: 11; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 90 }
                                        }
                                    }
                                }
                            }
                        }

                        // Unified Details View Marquee Drag-Select + Item Drag-and-Drop Layer!
                        MouseArea {
                            id: detailsMarquee
                            anchors.fill: parent; anchors.rightMargin: 14; z: 10
                            hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            property real pressX: 0
                            property real pressContentY: 0
                            property real curX: 0
                            property real curContentY: 0
                            property int pressHit: -1
                            property bool pressWasSel: false
                            property bool leftDown: false
                            property bool draggingBox: false
                            property var baseSel: []

                            function hitTest(mx, my) {
                                var cy = my + detailsFlick.contentY;
                                var kids = detailsCol.children;
                                for (var i = 0; i < kids.length; i++) {
                                    var c = kids[i];
                                    if (typeof c.itemIdx === "number") {
                                        if (mx >= c.x && mx <= c.x + c.width && cy >= c.y && cy <= c.y + c.height) return c.itemIdx;
                                    }
                                }
                                return -1;
                            }

                            function syncMarquee() {
                                var rx = Math.min(pressX, curX);
                                var rw = Math.abs(curX - pressX);
                                var ry = Math.min(pressContentY, curContentY);
                                var rh = Math.abs(curContentY - pressContentY);
                                detRubber.x = rx; detRubber.y = ry - detailsFlick.contentY;
                                detRubber.width = rw; detRubber.height = rh;

                                var nextP = baseSel.slice();
                                var kids = detailsCol.children;
                                var items = root.filteredItems || [];
                                for (var i = 0; i < kids.length; i++) {
                                    var c = kids[i];
                                    if (typeof c.itemIdx === "number" && c.itemIdx < items.length) {
                                        if (c.x < rx + rw && c.x + c.width > rx && c.y < ry + rh && c.y + c.height > ry) {
                                            var p = items[c.itemIdx].path;
                                            if (nextP.indexOf(p) === -1) nextP.push(p);
                                        }
                                    }
                                }
                                root.selectedPaths = nextP;
                                root.syncSelectedObjFromPaths();
                            }

                            Timer {
                                interval: 25; repeat: true
                                running: (detailsMarquee.draggingBox || root.draggingItems) && detailsMarquee.leftDown
                                onTriggered: {
                                    var my = detailsMarquee.mouseY;
                                    var maxY = Math.max(0, detailsFlick.contentHeight - detailsFlick.height);
                                    if (my > detailsMarquee.height - 26 && detailsFlick.contentY < maxY) {
                                        detailsFlick.contentY = Math.min(maxY, detailsFlick.contentY + 12);
                                        if (detailsMarquee.draggingBox) { detailsMarquee.curContentY = my + detailsFlick.contentY; detailsMarquee.syncMarquee(); }
                                    } else if (my < 26 && detailsFlick.contentY > 0) {
                                        detailsFlick.contentY = Math.max(0, detailsFlick.contentY - 12);
                                        if (detailsMarquee.draggingBox) { detailsMarquee.curContentY = my + detailsFlick.contentY; detailsMarquee.syncMarquee(); }
                                    }
                                }
                            }

                            onWheel: (wheel) => {
                                var maxY = Math.max(0, detailsFlick.contentHeight - detailsFlick.height);
                                detailsFlick.contentY = Math.max(0, Math.min(maxY, detailsFlick.contentY - wheel.angleDelta.y * 0.65));
                            }
                            onExited: root.hoveredItemIdx = -1

                            onPressed: (mouse) => {
                                root.forceActiveFocus();
                                root.openDropdown = "";
                                var hit = hitTest(mouse.x, mouse.y);
                                var items = root.filteredItems || [];
                                if (mouse.button === Qt.LeftButton) {
                                    root.expCtxOpen = false;
                                    pressX = mouse.x;
                                    pressContentY = mouse.y + detailsFlick.contentY;
                                    curX = mouse.x; curContentY = pressContentY;
                                    pressHit = hit;
                                    leftDown = true;
                                    draggingBox = false;
                                    pressWasSel = (hit >= 0 && hit < items.length && root.isPathSelected(items[hit].path));
                                    baseSel = (mouse.modifiers & Qt.ControlModifier) ? root.selectedPaths.slice() : [];
                                    if (hit === -1 && !(mouse.modifiers & Qt.ControlModifier)) {
                                        root.clearSelection();
                                    } else if (hit >= 0 && hit < items.length && !pressWasSel && !(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                                        root.setSingleSelection(items[hit], hit);
                                    }
                                } else if (mouse.button === Qt.RightButton) {
                                    var gp = detailsMarquee.mapToItem(root, mouse.x, mouse.y);
                                    if (hit >= 0 && hit < items.length) root.showExpCtx(gp.x, gp.y, "item", items[hit]);
                                    else { root.clearSelection(); root.showExpCtx(gp.x, gp.y, "bg", null); }
                                }
                            }

                            onPositionChanged: (mouse) => {
                                if (leftDown && (mouse.buttons & Qt.LeftButton)) {
                                    curX = mouse.x; curContentY = mouse.y + detailsFlick.contentY;
                                    var dx = Math.abs(curX - pressX);
                                    var dy = Math.abs(curContentY - pressContentY);
                                    if (pressHit >= 0 && !root.isTrashFolder) {
                                        if (root.draggingItems || dx > 6 || dy > 6) {
                                            if (!root.draggingItems) {
                                                var items = root.filteredItems || [];
                                                var lead = items[pressHit];
                                                root.dragSourcePaths = root.selectedPaths.length > 0 ? root.selectedPaths.slice() : (lead ? [lead.path] : []);
                                                root.dragLeadName = lead ? lead.name : "";
                                                root.dragLeadIcon = lead ? (lead.icon || "fluent-document.svg") : "fluent-document.svg";
                                                root.dragLeadIconUrl = (lead && lead.isImage) ? lead.fileUrl : "";
                                                root.draggingItems = true;
                                            }
                                            var gp = detailsMarquee.mapToItem(root, mouse.x, mouse.y);
                                            root.updateDragTargets(gp.x, gp.y);
                                        }
                                    } else if (pressHit === -1 || root.isTrashFolder) {
                                        if (draggingBox || dx > 5 || dy > 5) {
                                            draggingBox = true;
                                            syncMarquee();
                                        }
                                    }
                                } else {
                                    root.hoveredItemIdx = hitTest(mouse.x, mouse.y);
                                }
                            }

                            onReleased: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    if (root.draggingItems) {
                                        root.finishItemDrag();
                                    } else if (!draggingBox) {
                                        var items = root.filteredItems || [];
                                        if (pressHit >= 0 && pressHit < items.length) {
                                            var it = items[pressHit];
                                            if (mouse.modifiers & Qt.ControlModifier) {
                                                var arr = root.selectedPaths.slice();
                                                var pos = arr.indexOf(it.path);
                                                if (pos !== -1) arr.splice(pos, 1); else arr.push(it.path);
                                                root.selectedPaths = arr;
                                                root.syncSelectedObjFromPaths();
                                            } else if ((mouse.modifiers & Qt.ShiftModifier) && root.selectionAnchorIdx >= 0) {
                                                var a = Math.min(root.selectionAnchorIdx, pressHit);
                                                var b = Math.max(root.selectionAnchorIdx, pressHit);
                                                var rng = [];
                                                for (var k = a; k <= b && k < items.length; k++) rng.push(items[k].path);
                                                root.selectedPaths = rng;
                                                root.selectedObj = it;
                                            } else if (pressWasSel && root.selectedPaths.length > 1) {
                                                root.setSingleSelection(it, pressHit);
                                            }
                                        } else {
                                            root.clearSelection();
                                        }
                                    }
                                    leftDown = false; draggingBox = false;
                                    detRubber.width = 0; detRubber.height = 0;
                                }
                            }

                            onDoubleClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    var hit = hitTest(mouse.x, mouse.y);
                                    var items = root.filteredItems || [];
                                    if (hit >= 0 && hit < items.length) {
                                        root.expCtxOpen = false;
                                        if (items[hit].isDir) root.navigateExplorer(items[hit].path, true);
                                        else bridge.openFileOrUrl(items[hit].path);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: detRubber; z: 20
                            visible: detailsMarquee.draggingBox && (width > 3 || height > 3)
                            color: "#380078d4"; border.color: "#4cc2ff"; border.width: 1
                        }
                    }
                }

                // VIEW B2: TILES & LARGE ICONS GRID VIEW (Marquee Selection + Full Drag-and-Drop!)
                Item {
                    anchors.fill: parent; anchors.margins: 18
                    visible: root.explorerMode === "dir" && (root.explorerViewMode === "tiles" || root.explorerViewMode === "large")
                    clip: true

                    Text {
                        visible: root.filteredItems.length === 0
                        anchors.centerIn: parent
                        text: root.searchFilter !== "" ? "No se encontraron coincidencias" : (root.isTrashFolder ? "La Papelera de reciclaje está vacía" : "Esta carpeta está vacía")
                        color: "#8e8e8e"; font.pixelSize: 13
                    }

                    Flickable {
                        id: tilesFlick
                        anchors.fill: parent
                        contentWidth: width; contentHeight: realDirGrid.implicitHeight + 28
                        interactive: false; boundsBehavior: Flickable.StopAtBounds; clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; z: 30 }

                        Grid {
                            id: realDirGrid; width: tilesFlick.width - 12
                            readonly property bool isLarge: root.explorerViewMode === "large"
                            columns: isLarge ? Math.max(3, Math.floor(width / 128)) : (root.width < 900 ? 2 : 3)
                            rowSpacing: isLarge ? 12 : 8; columnSpacing: 12

                            Repeater {
                                model: root.filteredItems
                                delegate: Rectangle {
                                    readonly property int itemIdx: index
                                    readonly property bool isSel: root.selectedPaths.indexOf(modelData.path) !== -1
                                    readonly property bool isHov: root.hoveredItemIdx === index
                                    readonly property bool isDrop: root.draggingItems && root.dropTargetListIdx === index
                                    readonly property bool isDragSrc: root.draggingItems && root.dragSourcePaths.indexOf(modelData.path) !== -1
                                    readonly property bool isCut: root.clipboardIsCut && root.clipboardPaths.indexOf(modelData.path) !== -1
                                    width: realDirGrid.isLarge ? 116 : ((realDirGrid.width - (realDirGrid.columns - 1) * 12) / realDirGrid.columns)
                                    height: realDirGrid.isLarge ? 114 : 58
                                    radius: 6
                                    opacity: (isDragSrc || isCut) ? 0.48 : (modelData.isHidden ? 0.68 : 1.0)
                                    color: isDrop ? "#550078d4" : (isSel ? "#400078d4" : (isHov ? "#282828" : "#1f1f1f"))
                                    border.color: isDrop ? "#4cc2ff" : (isSel ? "#784cc2ff" : (isHov ? "#30ffffff" : "#14ffffff"))
                                    border.width: isDrop ? 1.5 : 1

                                    // Large Icons Layout
                                    Column {
                                        visible: realDirGrid.isLarge
                                        anchors.centerIn: parent; spacing: 6
                                        WinSvg {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 56; height: 56
                                            iconUrl: modelData.isImage ? modelData.fileUrl : ""
                                            iconFile: modelData.icon
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 104; text: modelData.name; color: "#f5f5f5"; font.pixelSize: 11
                                            maximumLineCount: 2; wrapMode: Text.WordWrap; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    // Tiles Layout
                                    RowLayout {
                                        visible: !realDirGrid.isLarge
                                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                                        WinSvg {
                                            width: 36; height: 36
                                            iconUrl: modelData.isImage ? modelData.fileUrl : ""
                                            iconFile: modelData.icon
                                        }
                                        Column {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { width: parent.width; text: modelData.name; color: "#f5f5f5"; font.pixelSize: 12; elide: Text.ElideRight }
                                            Text { width: parent.width; text: modelData.sub + " • " + modelData.mtime; color: "#8e8e8e"; font.pixelSize: 11; elide: Text.ElideRight }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: tilesMarquee
                        anchors.fill: parent; anchors.rightMargin: 14; z: 10
                        hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        property real pressX: 0
                        property real pressContentY: 0
                        property real curX: 0
                        property real curContentY: 0
                        property int pressHit: -1
                        property bool pressWasSel: false
                        property bool leftDown: false
                        property bool draggingBox: false
                        property var baseSel: []

                        function hitTest(mx, my) {
                            var cy = my + tilesFlick.contentY;
                            var kids = realDirGrid.children;
                            for (var i = 0; i < kids.length; i++) {
                                var c = kids[i];
                                if (typeof c.itemIdx === "number") {
                                    if (mx >= c.x && mx <= c.x + c.width && cy >= c.y && cy <= c.y + c.height) return c.itemIdx;
                                }
                            }
                            return -1;
                        }

                        function syncMarquee() {
                            var rx = Math.min(pressX, curX);
                            var rw = Math.abs(curX - pressX);
                            var ry = Math.min(pressContentY, curContentY);
                            var rh = Math.abs(curContentY - pressContentY);
                            tilesRubber.x = rx; tilesRubber.y = ry - tilesFlick.contentY;
                            tilesRubber.width = rw; tilesRubber.height = rh;

                            var nextP = baseSel.slice();
                            var kids = realDirGrid.children;
                            var items = root.filteredItems || [];
                            for (var i = 0; i < kids.length; i++) {
                                var c = kids[i];
                                if (typeof c.itemIdx === "number" && c.itemIdx < items.length) {
                                    if (c.x < rx + rw && c.x + c.width > rx && c.y < ry + rh && c.y + c.height > ry) {
                                        var p = items[c.itemIdx].path;
                                        if (nextP.indexOf(p) === -1) nextP.push(p);
                                    }
                                }
                            }
                            root.selectedPaths = nextP;
                            root.syncSelectedObjFromPaths();
                        }

                        Timer {
                            interval: 25; repeat: true
                            running: (tilesMarquee.draggingBox || root.draggingItems) && tilesMarquee.leftDown
                            onTriggered: {
                                var my = tilesMarquee.mouseY;
                                var maxY = Math.max(0, tilesFlick.contentHeight - tilesFlick.height);
                                if (my > tilesMarquee.height - 26 && tilesFlick.contentY < maxY) {
                                    tilesFlick.contentY = Math.min(maxY, tilesFlick.contentY + 12);
                                    if (tilesMarquee.draggingBox) { tilesMarquee.curContentY = my + tilesFlick.contentY; tilesMarquee.syncMarquee(); }
                                } else if (my < 26 && tilesFlick.contentY > 0) {
                                    tilesFlick.contentY = Math.max(0, tilesFlick.contentY - 12);
                                    if (tilesMarquee.draggingBox) { tilesMarquee.curContentY = my + tilesFlick.contentY; tilesMarquee.syncMarquee(); }
                                }
                            }
                        }

                        onWheel: (wheel) => {
                            var maxY = Math.max(0, tilesFlick.contentHeight - tilesFlick.height);
                            tilesFlick.contentY = Math.max(0, Math.min(maxY, tilesFlick.contentY - wheel.angleDelta.y * 0.65));
                        }
                        onExited: root.hoveredItemIdx = -1

                        onPressed: (mouse) => {
                            root.forceActiveFocus();
                            root.openDropdown = "";
                            var hit = hitTest(mouse.x, mouse.y);
                            var items = root.filteredItems || [];
                            if (mouse.button === Qt.LeftButton) {
                                root.expCtxOpen = false;
                                pressX = mouse.x; pressContentY = mouse.y + tilesFlick.contentY;
                                curX = mouse.x; curContentY = pressContentY;
                                pressHit = hit; leftDown = true; draggingBox = false;
                                pressWasSel = (hit >= 0 && hit < items.length && root.isPathSelected(items[hit].path));
                                baseSel = (mouse.modifiers & Qt.ControlModifier) ? root.selectedPaths.slice() : [];
                                if (hit === -1 && !(mouse.modifiers & Qt.ControlModifier)) root.clearSelection();
                                else if (hit >= 0 && hit < items.length && !pressWasSel && !(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                                    root.setSingleSelection(items[hit], hit);
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                var gp = tilesMarquee.mapToItem(root, mouse.x, mouse.y);
                                if (hit >= 0 && hit < items.length) root.showExpCtx(gp.x, gp.y, "item", items[hit]);
                                else { root.clearSelection(); root.showExpCtx(gp.x, gp.y, "bg", null); }
                            }
                        }

                        onPositionChanged: (mouse) => {
                            if (leftDown && (mouse.buttons & Qt.LeftButton)) {
                                curX = mouse.x; curContentY = mouse.y + tilesFlick.contentY;
                                var dx = Math.abs(curX - pressX);
                                var dy = Math.abs(curContentY - pressContentY);
                                if (pressHit >= 0 && !root.isTrashFolder) {
                                    if (root.draggingItems || dx > 6 || dy > 6) {
                                        if (!root.draggingItems) {
                                            var items = root.filteredItems || [];
                                            var lead = items[pressHit];
                                            root.dragSourcePaths = root.selectedPaths.length > 0 ? root.selectedPaths.slice() : (lead ? [lead.path] : []);
                                            root.dragLeadName = lead ? lead.name : "";
                                            root.dragLeadIcon = lead ? (lead.icon || "fluent-document.svg") : "fluent-document.svg";
                                            root.dragLeadIconUrl = (lead && lead.isImage) ? lead.fileUrl : "";
                                            root.draggingItems = true;
                                        }
                                        var gp = tilesMarquee.mapToItem(root, mouse.x, mouse.y);
                                        root.updateDragTargets(gp.x, gp.y);
                                    }
                                } else {
                                    if (draggingBox || dx > 5 || dy > 5) { draggingBox = true; syncMarquee(); }
                                }
                            } else {
                                root.hoveredItemIdx = hitTest(mouse.x, mouse.y);
                            }
                        }

                        onReleased: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                if (root.draggingItems) {
                                    root.finishItemDrag();
                                } else if (!draggingBox) {
                                    var items = root.filteredItems || [];
                                    if (pressHit >= 0 && pressHit < items.length) {
                                        var it = items[pressHit];
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            var arr = root.selectedPaths.slice();
                                            var pos = arr.indexOf(it.path);
                                            if (pos !== -1) arr.splice(pos, 1); else arr.push(it.path);
                                            root.selectedPaths = arr; root.syncSelectedObjFromPaths();
                                        } else if ((mouse.modifiers & Qt.ShiftModifier) && root.selectionAnchorIdx >= 0) {
                                            var a = Math.min(root.selectionAnchorIdx, pressHit);
                                            var b = Math.max(root.selectionAnchorIdx, pressHit);
                                            var rng = [];
                                            for (var k = a; k <= b && k < items.length; k++) rng.push(items[k].path);
                                            root.selectedPaths = rng; root.selectedObj = it;
                                        } else if (pressWasSel && root.selectedPaths.length > 1) {
                                            root.setSingleSelection(it, pressHit);
                                        }
                                    } else {
                                        root.clearSelection();
                                    }
                                }
                                leftDown = false; draggingBox = false;
                                tilesRubber.width = 0; tilesRubber.height = 0;
                            }
                        }

                        onDoubleClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                var hit = hitTest(mouse.x, mouse.y);
                                var items = root.filteredItems || [];
                                if (hit >= 0 && hit < items.length) {
                                    root.expCtxOpen = false;
                                    if (items[hit].isDir) root.navigateExplorer(items[hit].path, true);
                                    else bridge.openFileOrUrl(items[hit].path);
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: tilesRubber; z: 20
                        visible: tilesMarquee.draggingBox && (width > 3 || height > 3)
                        color: "#380078d4"; border.color: "#4cc2ff"; border.width: 1
                    }
                }
            }
        }

        // [E] Authentic Windows 11 26H2 Status Footer (Count + Multi-Selection + Toast + View Mode Switcher)
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            color: "#191919"; border.color: "#16ffffff"; border.width: 1
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 10
                Text {
                    text: (root.explorerMode === "thispc" ? (root.explorerDrives.length + 6) : root.filteredItems.length) + " elementos" +
                          (root.selectedPaths.length > 1
                           ? ("   |   " + root.selectedPaths.length + " elementos seleccionados")
                           : (root.selectedObj ? ("   |   1 elemento seleccionado  " + (root.selectedObj.sizeLabel || "")) : ""))
                    color: "#a8a8a8"; font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.statusToast !== ""
                    text: root.statusToast; color: "#4cc2ff"; font.pixelSize: 11
                }
                Rectangle {
                    width: 24; height: 22; radius: 4
                    color: root.explorerViewMode === "details" ? "#2affffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-apps-list.svg" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.explorerViewMode = "details" }
                }
                Rectangle {
                    width: 24; height: 22; radius: 4
                    color: root.explorerViewMode === "tiles" ? "#2affffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-grid.svg" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.explorerViewMode = "tiles" }
                }
                Rectangle {
                    width: 24; height: 22; radius: 4
                    color: root.explorerViewMode === "large" ? "#2affffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-folder-grid.svg" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.explorerViewMode = "large" }
                }
            }
        }
    }

    // Floating WinUI 3 Drag Ghost Pill (follows cursor when dragging items across Explorer!)
    Item {
        id: expDragGhost
        z: 90
        visible: root.draggingItems && root.dragSourcePaths.length > 0
        x: Math.max(8, Math.min(root.width - 220, root.dragGlobalX + 14))
        y: Math.max(8, Math.min(root.height - 76, root.dragGlobalY + 14))

        Column {
            spacing: 4
            Rectangle {
                width: Math.min(220, dragRow.implicitWidth + 24); height: 36; radius: 6
                color: "#ee242c38"; border.color: "#4cc2ff"; border.width: 1
                RowLayout {
                    id: dragRow; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                    WinSvg { width: 18; height: 18; iconUrl: root.dragLeadIconUrl; iconFile: root.dragLeadIcon }
                    Text {
                        text: root.dragSourcePaths.length > 1 ? (root.dragSourcePaths.length + " elementos") : root.dragLeadName
                        color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.maximumWidth: 160
                    }
                }
            }
            Rectangle {
                visible: root.dropTargetLabel !== ""
                width: dropLblTxt.implicitWidth + 16; height: 24; radius: 5
                color: "#ee1a1a1a"; border.color: "#4cc2ff"; border.width: 1
                Text { id: dropLblTxt; anchors.centerIn: parent; text: root.dropTargetLabel; color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold }
            }
        }
    }

    // Click-outside Catcher for Dropdowns & Context Menu
    MouseArea {
        visible: root.openDropdown !== "" || root.expCtxOpen
        anchors.fill: parent; z: 45
        onClicked: { root.openDropdown = ""; root.expCtxOpen = false; }
    }

    // Floating Command Bar Dropdown Menus ("Nuevo", "Ordenar", "Ver", "Más")
    Rectangle {
        visible: root.openDropdown !== ""
        x: root.openDropdown === "new" ? 14 : (root.openDropdown === "sort" ? 344 : (root.openDropdown === "view" ? 440 : 518))
        y: 132
        width: 218
        height: dropCol.implicitHeight + 10
        radius: 8; color: "#f82b2b2b"; border.color: "#34ffffff"; border.width: 1; z: 50
        MouseArea { anchors.fill: parent }

        readonly property var menuModel: {
            if (root.openDropdown === "new") {
                return [
                    { id: "new_folder", label: "Carpeta",              icon: "folder.svg" },
                    { id: "new_doc",    label: "Documento de texto",   icon: "fluent-document.svg" },
                    { id: "new_md",     label: "Notas Markdown (.md)", icon: "fluent-document.svg" }
                ];
            }
            if (root.openDropdown === "sort") {
                return [
                    { id: "s_name", label: "Nombre",                active: root.explorerSortBy === "name" },
                    { id: "s_date", label: "Fecha de modificación", active: root.explorerSortBy === "date" },
                    { id: "s_type", label: "Tipo",                  active: root.explorerSortBy === "type" },
                    { id: "s_size", label: "Tamaño",                active: root.explorerSortBy === "size" },
                    { sep: true },
                    { id: "s_asc",  label: "Ascendente",            active: root.explorerSortAsc },
                    { id: "s_desc", label: "Descendente",           active: !root.explorerSortAsc }
                ];
            }
            if (root.openDropdown === "view") {
                return [
                    { id: "v_details", label: "Detalles",           active: root.explorerViewMode === "details" },
                    { id: "v_tiles",   label: "Mosaicos e iconos",  active: root.explorerViewMode === "tiles" },
                    { id: "v_large",   label: "Iconos grandes",     active: root.explorerViewMode === "large" },
                    { sep: true },
                    { id: "v_hidden",  label: "Elementos ocultos",  active: root.showHiddenFiles, isCheck: true }
                ];
            }
            if (root.openDropdown === "more") {
                return [
                    { id: "m_selall",  label: "Seleccionar todo (Ctrl+A)", icon: "fluent-grid.svg" },
                    { id: "m_invert",  label: "Invertir selección",        icon: "fluent-arrow-sort.svg" },
                    { sep: true },
                    { id: "m_term",    label: "Abrir en Terminal",         icon: "fluent-window-console.svg" },
                    { id: "m_copycur", label: "Copiar ruta actual",        icon: "fluent-link.svg" },
                    { sep: true },
                    { id: "m_props",   label: "Propiedades (Alt+Enter)",   icon: "fluent-info.svg" }
                ];
            }
            return [];
        }

        Column {
            id: dropCol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5; spacing: 2
            Repeater {
                model: parent.parent.menuModel
                delegate: Item {
                    width: 208; height: modelData.sep ? 8 : 31
                    Rectangle { visible: Boolean(modelData.sep); anchors.verticalCenter: parent.verticalCenter; x: 6; width: 196; height: 1; color: "#1effffff" }
                    Rectangle {
                        visible: !modelData.sep; anchors.fill: parent; radius: 5
                        color: dItemHov.containsMouse ? "#24ffffff" : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                            Item {
                                width: 16; height: 16
                                WinSvg { visible: Boolean(modelData.icon); anchors.centerIn: parent; width: 16; height: 16; iconFile: modelData.icon || "folder.svg" }
                                WinSvg { visible: !modelData.icon && Boolean(modelData.active) && Boolean(modelData.isCheck); anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-checkmark.svg" }
                                Rectangle { visible: !modelData.icon && Boolean(modelData.active) && !modelData.isCheck; anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: "#4cc2ff" }
                            }
                            Text { text: modelData.label || ""; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                        }
                        MouseArea { id: dItemHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.execExpDropdown(modelData.id) }
                    }
                }
            }
        }
    }

    // Authentic Windows 11 26H2 File Explorer Right-Click Context Menu
    Rectangle {
        id: expCtxCard
        visible: root.expCtxOpen
        x: root.expCtxX
        y: Math.min(root.expCtxY, root.height - height - 12)
        width: 268
        height: expCtxCol.implicitHeight + 12
        radius: 8; color: "#f6282828"; border.color: "#32ffffff"; border.width: 1; z: 70
        MouseArea { anchors.fill: parent }

        readonly property var menuRows: {
            if (root.expCtxKind === "trash_nav") {
                return [
                    { act: "open_trash",  label: "Abrir",                        icon: "trash.svg",        bold: true },
                    { act: "restore_all", label: "Restaurar todos los elementos",icon: "fluent-arrow-undo.svg" },
                    { sep: true },
                    { act: "empty_trash", label: "Vaciar Papelera de reciclaje", icon: "fluent-delete.svg" }
                ];
            }
            if (root.expCtxKind === "nav_folder") {
                return [
                    { act: "nav_open",  label: "Abrir",                      icon: "folder.svg",                bold: true },
                    { act: "nav_tab",   label: "Abrir en una pestaña nueva", icon: "fluent-add.svg" },
                    { act: "nav_term",  label: "Abrir en Terminal",          icon: "fluent-window-console.svg" },
                    { sep: true },
                    { act: "nav_props", label: "Propiedades",                icon: "fluent-info.svg" }
                ];
            }
            if (root.expCtxKind === "bg") {
                var b = [
                    { act: "toggle_view",   label: "Cambiar vista",                icon: "fluent-grid.svg" },
                    { act: "toggle_hidden", label: root.showHiddenFiles ? "Ocultar archivos ocultos" : "Mostrar archivos ocultos", icon: "fluent-eye.svg" },
                    { act: "refresh",       label: "Actualizar",                   icon: "fluent-refresh.svg" }
                ];
                if (root.clipboardPath !== "" && !root.isTrashFolder) {
                    b.push({ sep: true });
                    b.push({ act: "paste", label: "Pegar", icon: "fluent-paste.svg" });
                }
                if (root.isTrashFolder) {
                    b.push({ sep: true });
                    b.push({ act: "restore_all", label: "Restaurar todos los elementos", icon: "fluent-arrow-undo.svg" });
                    b.push({ act: "empty_trash", label: "Vaciar Papelera de reciclaje",  icon: "fluent-delete.svg" });
                } else {
                    b.push({ sep: true });
                    b.push({ act: "new_folder", label: "Nueva carpeta",            icon: "folder.svg" });
                    b.push({ act: "new_doc",    label: "Nuevo documento de texto", icon: "fluent-document.svg" });
                    b.push({ act: "new_md",     label: "Nuevas notas (.md)",       icon: "fluent-document.svg" });
                    b.push({ sep: true });
                    b.push({ act: "term_here",  label: "Abrir en Terminal",        icon: "fluent-window-console.svg" });
                }
                return b;
            }
            if (root.isTrashFolder && root.selectedObj) {
                return [
                    { act: "restore_item", label: "Restaurar",              icon: "fluent-arrow-undo.svg", bold: true },
                    { sep: true },
                    { act: "del_perm",     label: "Eliminar permanentemente", icon: "fluent-delete.svg" },
                    { sep: true },
                    { act: "props",        label: "Propiedades",            icon: "fluent-info.svg" }
                ];
            }
            var it = root.selectedObj;
            if (!it) return [];
            var r = [{ act: "open", label: "Abrir", icon: it.icon || "folder.svg", bold: true }];
            if (it.isDir) {
                r.push({ act: "open_tab",  label: "Abrir en una pestaña nueva", icon: "fluent-add.svg" });
                r.push({ act: "term_item", label: "Abrir en Terminal",          icon: "fluent-window-console.svg" });
            } else {
                r.push({ act: "term_item", label: "Abrir carpeta en Terminal",  icon: "fluent-window-console.svg" });
            }
            if (it.isArchive) {
                r.push({ act: "extract_item", label: "Extraer todo aquí", icon: "fluent-folder-zip.svg" });
            }
            if (it.isImage) {
                r.push({ act: "set_wp", label: "Establecer como fondo de escritorio", icon: "fluent-image.svg" });
            }
            r.push({ sep: true });
            r.push({ act: "zip_item",  label: "Comprimir en archivo ZIP",   icon: "fluent-folder-zip.svg" });
            r.push({ act: "copy_path", label: "Copiar como ruta de acceso", icon: "fluent-link.svg" });
            r.push({ sep: true });
            r.push({ act: "props",     label: "Propiedades",                icon: "fluent-info.svg" });
            return r;
        }

        Column {
            id: expCtxCol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5; spacing: 2

            // Top 26H2 Quick-Action Strip for Normal Items
            Column {
                visible: root.expCtxKind === "item" && !root.isTrashFolder && root.selectedObj !== null
                width: 258; spacing: 4
                Row {
                    x: 2; spacing: 2
                    Repeater {
                        model: [
                            { id: "cut",    icon: "fluent-cut.svg",    label: "Cortar" },
                            { id: "copy",   icon: "fluent-copy.svg",   label: "Copiar" },
                            { id: "rename", icon: "fluent-rename.svg", label: "Nombre" },
                            { id: "delete", icon: "fluent-delete.svg", label: "Eliminar" }
                        ]
                        delegate: Rectangle {
                            readonly property bool dis: (modelData.id === "rename" && root.selectedPaths.length > 1)
                            width: 62; height: 46; radius: 5
                            opacity: dis ? 0.4 : 1.0
                            color: (!dis && eqHov.containsMouse) ? "#24ffffff" : "transparent"
                            Column {
                                anchors.centerIn: parent; spacing: 4
                                WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 16; height: 16; iconFile: modelData.icon }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#e6e6e6"; font.pixelSize: 10 }
                            }
                            MouseArea {
                                id: eqHov; anchors.fill: parent; hoverEnabled: true; enabled: !parent.dis
                                onClicked: root.execExpQuickAction(modelData.id)
                            }
                        }
                    }
                }
                Rectangle { x: 6; width: 246; height: 1; color: "#1effffff" }
            }

            Repeater {
                model: expCtxCard.menuRows
                delegate: Item {
                    width: 258; height: modelData.sep ? 9 : 31
                    Rectangle { visible: Boolean(modelData.sep); anchors.verticalCenter: parent.verticalCenter; x: 6; width: 246; height: 1; color: "#1effffff" }
                    Rectangle {
                        visible: !modelData.sep; anchors.fill: parent; radius: 5
                        color: erHov.containsMouse ? "#24ffffff" : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 11
                            WinSvg { width: 16; height: 16; iconFile: modelData.icon || "folder.svg" }
                            Text {
                                text: modelData.label || ""; color: "#f2f2f2"; font.pixelSize: 12
                                font.weight: modelData.bold ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        MouseArea { id: erHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.execExpCtxAction(modelData.act) }
                    }
                }
            }
        }
    }

    // Complete File / Folder Properties Modal (Real Recursive Size, Permissions, Owner, MIME & Executable Toggle!)
    Rectangle {
        visible: root.expPropsOpen && root.expPropsData !== null
        anchors.fill: parent; color: "#66000000"; z: 80
        MouseArea { anchors.fill: parent; onClicked: root.expPropsOpen = false }

        Rectangle {
            anchors.centerIn: parent; width: 420; height: 325; radius: 10
            color: "#f8242424"; border.color: "#34ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 9
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg { width: 38; height: 38; iconFile: root.expPropsData ? (root.expPropsData.icon || "folder.svg") : "folder.svg" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: root.expPropsData ? root.expPropsData.name : ""; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; width: 320 }
                        Text { text: root.expPropsData ? (root.expPropsData.mime || "") : ""; color: "#9e9e9e"; font.pixelSize: 11 }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1effffff" }
                Text { text: "Ubicación:  " + (root.expPropsData ? root.expPropsData.parent : ""); color: "#d4d4d4"; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
                Text {
                    text: "Tamaño:  " + (root.expPropsData ? root.expPropsData.sizeStr : "") +
                          (root.expPropsData && root.expPropsData.contentsStr ? ("  (" + root.expPropsData.contentsStr + ")") : "")
                    color: "#d4d4d4"; font.pixelSize: 12
                }
                Text { text: "Modificado:  " + (root.expPropsData ? root.expPropsData.mtime : ""); color: "#d4d4d4"; font.pixelSize: 12 }
                Text { text: "Propietario / Permisos:  " + (root.expPropsData ? (root.expPropsData.owner + "  •  " + root.expPropsData.perms) : ""); color: "#d4d4d4"; font.pixelSize: 12 }
                Text {
                    visible: Boolean(root.expPropsData && root.expPropsData.isLink)
                    text: "Destino de enlace:  " + (root.expPropsData ? root.expPropsData.linkTarget : "")
                    color: "#4cc2ff"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.fillWidth: true
                }

                // Executable Permission Toggle for Files (real chmod +x / -x!)
                RowLayout {
                    visible: Boolean(root.expPropsData && !root.expPropsData.isDir)
                    Layout.fillWidth: true; spacing: 10
                    Text { text: "Permitir ejecutar como programa"; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true }
                    Rectangle {
                        width: 38; height: 20; radius: 10
                        color: (root.expPropsData && root.expPropsData.isExecutable) ? "#4cc2ff" : "#2e2e2e"
                        border.color: (root.expPropsData && root.expPropsData.isExecutable) ? "#4cc2ff" : "#55ffffff"; border.width: 1
                        Rectangle {
                            x: (root.expPropsData && root.expPropsData.isExecutable) ? 20 : 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12; height: 12; radius: 6
                            color: (root.expPropsData && root.expPropsData.isExecutable) ? "#000000" : "#cccccc"
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.expPropsData) return;
                                var nxt = !Boolean(root.expPropsData.isExecutable);
                                if (bridge.setFileExecutable(root.expPropsData.path, nxt)) {
                                    root.openPropertiesForPath(root.expPropsData.path, root.expPropsData.icon);
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Rectangle {
                        width: 108; height: 30; radius: 5; color: "#2d2d2d"; border.color: "#22ffffff"
                        Text { anchors.centerIn: parent; text: "Copiar ruta"; color: "#f0f0f0"; font.pixelSize: 12 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.expPropsData) { bridge.copyTextToClipboard(root.expPropsData.path); root.showExpToast("Ruta copiada"); }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 88; height: 30; radius: 5; color: "#4cc2ff"
                        Text { anchors.centerIn: parent; text: "Aceptar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.expPropsOpen = false }
                    }
                }
            }
        }
    }
}
