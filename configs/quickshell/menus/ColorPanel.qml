import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../oklch.js" as Oklch

// SUPER+comma → Colors: the palette, edited in tokens.toml itself.
//
//   Swatches  repaint a swatch (the raw paint) in OKLCH: lightness, chroma and
//             hue meters, or type a hex. Everywhere it's used changes.
//   Roles     point a role (roles, terminal, web, editor, syntax; day or night)
//             at another swatch.
//   Alpha     how see-through kitty (and yazi), Zed and the bar are; their
//             text is then checked against the worst pixel of the desk behind.
//
// Every change is checked as you make it by contrast.py's own rules (through
// tools/palette.py), so you see each check the swatch or role takes part in,
// before → after, failures first. Enter saves: palette.py rewrites that one
// line of tokens.toml, regenerates, and redeploys the colors, keeping the
// menu's day/night. Saving with a failing check asks for a second Enter.
//
// Saving rewrites Tokens.qml, so Quickshell reloads mid-save; this panel's
// place is kept in PersistentProperties, and palette.py leaves the outcome in
// ~/.cache/cozy-archive/palette-saved.json for the reloaded panel to show.
PanelWindow {
    id: win
    visible: Menus.colorsOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "cozy-archive:colors"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property int u: Theme.unit
    readonly property int rowHeight: 6 * u
    readonly property int listRows: 16
    readonly property int listWidth: 72 * u
    implicitWidth: 200 * u + Theme.shadowOffset
    implicitHeight: card.height + Theme.shadowOffset

    // ── where we are (kept across Quickshell's reload on save) ─────────────
    PersistentProperties {
        id: place
        reloadableId: "colorPanel"
        property string tab: "swatches"       // "swatches" | "roles" | "alpha"
        property int swatch: 0
        property int table: 0
        property int role: 0                  // 0 is the table chooser row
    }
    property bool editing: false              // focus in the right-hand editor
    property int editRow: 0                   // swatches: 0 L, 1 C, 2 h, 3 hex

    // ── the palette (tools/palette.py dump) ─────────────────────────────────
    property var model: null
    readonly property var swatches: model ? model.swatches : []
    readonly property var tableNames: model ? Object.keys(model.tables) : []
    readonly property string tableName: tableNames[place.table] ?? ""
    readonly property var roles: model && tableName ? model.tables[tableName] : []
    readonly property var alphaItem: model ? { key: "alpha", value: model.alpha,
        note: "kitty (and yazi in it), Zed, the bar. VS Code can't be see-through." } : undefined
    readonly property var current: place.tab === "swatches" ? swatches[place.swatch]
        : place.tab === "roles" ? roles[place.role - 1] : alphaItem
    readonly property var tabs: ["swatches", "roles", "alpha"]

    function swatchHex(name) {
        const s = swatches.find(s => s.name === name)
        return s ? s.hex : (Oklch.isHex(name) ? name : "#000000")
    }

    // ── the draft: what the editor shows, not yet in tokens.toml ───────────
    property real dL: 0
    property real dC: 0
    property real dH: 0
    property string draftHex: "#000000"
    property bool draftInGamut: true
    property string draftRef: ""
    property real draftAlpha: 1

    function setLCH(L, C, h) {
        dL = Math.max(0, Math.min(1, L))
        dC = Math.max(0, Math.min(0.4, C))
        dH = ((h % 360) + 360) % 360
        const out = Oklch.toHex(dL, dC, dH)
        draftHex = out.hex
        draftInGamut = out.inGamut
        if (hexInput.text.toUpperCase() !== draftHex) hexInput.text = draftHex
        requestCheck()
    }
    function setHex(hex) {
        const o = Oklch.fromHex(hex)
        dL = o.L; dC = o.C
        if (o.C > 1e-4) dH = o.h            // grey has no hue: keep the last one
        draftHex = hex.toUpperCase()
        draftInGamut = true
        requestCheck()
    }
    // The three meters: OKLCH lightness, chroma, hue.
    readonly property var channels: [
        { label: "L", min: 0, max: 1 },
        { label: "C", min: 0, max: 0.4 },
        { label: "h", min: 0, max: 360 },
    ]
    function channelValue(i) { return [dL, dC, dH][i] }
    function channelAt(i, t) {       // the color with channel i set to t
        return Oklch.toHex(i === 0 ? t : dL, i === 1 ? t : dC, i === 2 ? t : dH)
    }
    function channelSet(i, v) { setLCH(i === 0 ? v : dL, i === 1 ? v : dC, i === 2 ? v : dH) }

    function resetDraft() {
        confirmFailing = false
        if (!current) return
        if (place.tab === "swatches") {
            setHex(current.hex)
            hexInput.text = current.hex
        } else if (place.tab === "alpha") {
            draftAlpha = current.value
            requestCheck()
        } else {
            draftRef = current.ref
            requestCheck()
        }
    }
    readonly property bool dirty: !!current && (place.tab === "swatches" ? draftHex !== current.hex
        : place.tab === "alpha" ? Math.abs(draftAlpha - current.value) > 0.001
        : draftRef !== current.ref)

    function edits() {
        if (!current) return null
        if (place.tab === "swatches") return { swatch: { [current.name]: draftHex } }
        if (place.tab === "alpha") return { structure: { alpha: Math.round(draftAlpha * 100) / 100 } }
        const ref = {}
        ref[tableName] = { [current.key]: draftRef }
        return { ref: ref }
    }

    onCurrentChanged: resetDraft()

    // ── back end ────────────────────────────────────────────────────────────
    FileView {
        id: repoFile
        path: Settings.dataDir + "/cozy-archive/repo"
        blockLoading: true      // the panel may open (restored) before an async load lands
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string repo: repoFile.text().trim()
    onRepoChanged: if (visible && repo) refresh()
    readonly property string script: repo + "/tools/palette.py"
    property string status: ""
    property bool statusIsError: false

    function refresh() {
        if (!repo) { status = "No repo recorded: run ./install.sh from your clone."; statusIsError = true; return }
        dumper.running = true
    }
    Process {
        id: dumper
        command: ["python3", win.script, "dump"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const m = JSON.parse(text)
                    if (m.error) throw new Error(m.error)
                    win.model = m
                    win.resetDraft()
                } catch (e) {
                    win.status = "Couldn't read tokens.toml: " + e.message
                    win.statusIsError = true
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) {
                win.status = text.trim().split("\n").pop()
                win.statusIsError = true
            }
        }
    }

    // Checks: debounced, one run at a time, the latest draft wins.
    property var checks: []
    property int failing: 0
    property bool checkPending: false
    function requestCheck() { checkTimer.restart() }
    Timer {
        id: checkTimer
        interval: 120
        onTriggered: {
            const e = win.edits()
            if (!e || !win.repo) return
            if (checker.running) { win.checkPending = true; return }
            checker.command = ["python3", win.script, "check", JSON.stringify(e)]
            checker.running = true
        }
    }
    Process {
        id: checker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    if (r.error) { win.status = r.error; win.statusIsError = true; return }
                    win.checks = r.affected
                    win.failing = r.failing
                } catch (e) {}
            }
        }
        onExited: if (win.checkPending) { win.checkPending = false; checkTimer.restart() }
    }

    // Save: detached, because the redeploy reloads Quickshell (and this panel).
    property bool confirmFailing: false
    property bool saving: false
    function save() {
        if (!dirty || saving) return
        if (failing > 0 && !confirmFailing) {
            confirmFailing = true
            return
        }
        saving = true
        status = "Saving to tokens.toml…"
        statusIsError = false
        Quickshell.execDetached(["python3", script, "save", JSON.stringify(edits())])
    }
    FileView {
        id: savedFile
        path: Settings.cacheDir + "/cozy-archive/palette-saved.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let r
            try { r = JSON.parse(text()) } catch (e) { return }
            if (Date.now() / 1000 - r.at > 120) return     // an old save
            win.saving = false
            win.confirmFailing = false
            win.status = r.ok ? "Saved to tokens.toml. " + (r.total - r.failing) + "/" + r.total + " checks pass."
                              : r.error          // palette.py says whether tokens.toml was written
            win.statusIsError = !r.ok || r.failing > 0
            if (win.visible) win.refresh()
        }
    }

    function opened() {
        editing = false
        refresh()
        keys.forceActiveFocus()
    }
    onVisibleChanged: if (visible) opened()
    // After a save's reload the panel comes back already open: no change to see.
    Component.onCompleted: if (visible) opened()

    // ── keys ────────────────────────────────────────────────────────────────
    function clampList() {
        if (place.tab === "swatches") place.swatch = Math.max(0, Math.min(swatches.length - 1, place.swatch))
        else if (place.tab === "roles") place.role = Math.max(0, Math.min(roles.length, place.role))
    }
    function moveList(d) {
        if (place.tab === "swatches") place.swatch += d
        else if (place.tab === "roles") place.role += d
        clampList()
    }
    function nudge(dir, coarse) {
        if (place.tab === "swatches") {
            if (editRow === 0) setLCH(dL + dir * (coarse ? 0.05 : 0.01), dC, dH)
            else if (editRow === 1) setLCH(dL, dC + dir * (coarse ? 0.02 : 0.005), dH)
            else if (editRow === 2) setLCH(dL, dC, dH + dir * (coarse ? 15 : 2))
        } else if (place.tab === "alpha") {
            draftAlpha = Math.max(0.5, Math.min(1, Math.round((draftAlpha + dir * (coarse ? 0.05 : 0.01)) * 100) / 100))
            confirmFailing = false
            requestCheck()
        } else {
            const names = swatches.map(s => s.name)
            let i = names.indexOf(draftRef)
            i = i < 0 ? 0 : (i + dir * (coarse ? 5 : 1) + names.length) % names.length
            draftRef = names[i]
            confirmFailing = false
            requestCheck()
        }
    }
    function syncFocus() {
        if (editing && place.tab === "swatches" && editRow === 3) hexInput.forceActiveFocus()
        else keys.forceActiveFocus()
    }

    function handleKey(event) {
        const k = event.key, shift = event.modifiers & Qt.ShiftModifier
        if (!saving && !statusIsError) status = ""        // the last save's note, once read
        if (!editing) {
            if (k === Qt.Key_Escape) Menus.colorsOpen = false
            else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
                const i = tabs.indexOf(place.tab)
                place.tab = tabs[(i + (k === Qt.Key_Backtab ? tabs.length - 1 : 1)) % tabs.length]
            }
            else if (k === Qt.Key_Down) moveList(shift ? 5 : 1)
            else if (k === Qt.Key_Up) moveList(shift ? -5 : -1)
            else if (k === Qt.Key_PageDown) moveList(listRows)
            else if (k === Qt.Key_PageUp) moveList(-listRows)
            else if (place.tab === "roles" && place.role === 0 && (k === Qt.Key_Left || k === Qt.Key_Right)) {
                const n = tableNames.length
                place.table = (place.table + (k === Qt.Key_Right ? 1 : -1) + n) % n
                clampList()
            }
            else if ((k === Qt.Key_Right || k === Qt.Key_Return || k === Qt.Key_Enter) && current) {
                editing = true
                editRow = 0
            }
            else return
        } else {
            const rows = place.tab === "swatches" ? 4 : 1
            if (k === Qt.Key_Escape) { resetDraft(); editing = false }
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) save()
            else if (k === Qt.Key_Down || (k === Qt.Key_Tab && !shift)) editRow = Math.min(rows - 1, editRow + 1)
            else if (k === Qt.Key_Up || k === Qt.Key_Backtab) editRow = Math.max(0, editRow - 1)
            else if (editRow === 3 && place.tab === "swatches") return    // typing a hex
            else if (k === Qt.Key_Left) nudge(-1, shift)
            else if (k === Qt.Key_Right) nudge(1, shift)
            else return
        }
        event.accepted = true
        syncFocus()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => win.handleKey(event)
    }

    // ── drawing ─────────────────────────────────────────────────────────────
    component Words: Text {
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.textPrimary
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    // A color chip: a tiny raised plate with a hard edge, so pale swatches
    // still read against the card.
    component Chip: Rectangle {
        width: 4 * Theme.unit
        height: 4 * Theme.unit
        border.width: Theme.borderThin
        border.color: Theme.borderShade
    }
    // The focused-row marker, as in the settings menu.
    component Marker: Rectangle {
        width: Theme.borderWidth
        height: 4 * Theme.unit
        color: Theme.focusBorder
    }

    Card {
        id: card
        width: win.implicitWidth - Theme.shadowOffset
        height: 2 * Theme.borderWidth + 4 * win.u
              + 7 * win.u                                  // title + tabs
              + win.listRows * win.rowHeight
              + 7 * win.u                                  // status / hint

        Column {
            anchors.fill: parent
            anchors.margins: 2 * win.u

            // ── title, tabs ──
            Item {
                width: parent.width
                height: 7 * win.u
                Words { x: 2 * win.u; height: parent.height; text: "Colors" }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2 * win.u
                    Repeater {
                        model: [["swatches", "Swatches"], ["roles", "Roles"], ["alpha", "Alpha"]]
                        delegate: Card {
                            id: tabChip
                            required property var modelData
                            readonly property bool chosen: place.tab === modelData[0]
                            chamfer: Theme.unit
                            dropShadow: chosen
                            fill: chosen ? Theme.accentSolid : Theme.bgPrimary
                            lit: chosen ? Theme.highlight : Theme.bgPrimary
                            shade: chosen ? Theme.shadow : Theme.bgPrimary
                            width: tabWords.implicitWidth + 6 * Theme.unit
                            height: 6 * Theme.unit
                            Words {
                                id: tabWords
                                anchors.centerIn: parent
                                text: tabChip.modelData[1]
                                color: tabChip.chosen ? Theme.textOnAccent : Theme.textPrimary
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { place.tab = tabChip.modelData[0]; win.editing = false; win.syncFocus() }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: win.listRows * win.rowHeight

                // ── the list ──
                Item {
                    id: list
                    width: win.listWidth
                    height: parent.height
                    clip: true

                    readonly property int count: place.tab === "swatches" ? win.swatches.length
                        : place.tab === "roles" ? win.roles.length + 1 : (win.alphaItem ? 1 : 0)
                    readonly property int selected: place.tab === "swatches" ? place.swatch
                        : place.tab === "roles" ? place.role : 0
                    property int first: 0
                    onSelectedChanged: {
                        if (selected < first) first = selected
                        if (selected >= first + win.listRows) first = selected - win.listRows + 1
                    }

                    Repeater {
                        model: Math.min(win.listRows, list.count - list.first)
                        delegate: Item {
                            id: row
                            required property int index
                            readonly property int i: list.first + index
                            readonly property bool chooser: place.tab === "roles" && i === 0
                            readonly property var item: place.tab === "swatches" ? win.swatches[i]
                                : place.tab === "roles" ? win.roles[i - 1] : win.alphaItem
                            readonly property bool current: i === list.selected
                            readonly property bool solid: current && !win.editing

                            y: index * win.rowHeight
                            width: list.width
                            height: win.rowHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 2 * win.u
                                color: row.solid ? Theme.accentSolid : "transparent"
                            }
                            Marker { visible: row.current && win.editing; anchors.verticalCenter: parent.verticalCenter }

                            // Roles' first row picks the table: ‹ roles.light ›
                            Words {
                                visible: row.chooser
                                x: 4 * win.u
                                height: parent.height
                                text: "‹ " + win.tableName + " ›"
                                color: row.solid ? Theme.textOnAccent : Theme.textPrimary
                            }

                            Chip {
                                visible: !row.chooser && !!row.item && !!row.item.hex
                                x: 4 * win.u
                                anchors.verticalCenter: parent.verticalCenter
                                color: row.item && row.item.hex ? row.item.hex : "transparent"
                            }
                            Words {
                                visible: !row.chooser
                                x: place.tab === "alpha" ? 4 * win.u : 10 * win.u
                                width: parent.width - 30 * win.u
                                height: parent.height
                                text: row.item ? (place.tab === "swatches" ? row.item.name : row.item.key) : ""
                                color: row.solid ? Theme.textOnAccent : Theme.textPrimary
                            }
                            Words {
                                visible: !row.chooser
                                anchors.right: parent.right
                                anchors.rightMargin: 2 * win.u
                                width: 18 * win.u
                                height: parent.height
                                horizontalAlignment: Text.AlignRight
                                text: !row.item ? "" : place.tab === "swatches" ? row.item.hex
                                    : place.tab === "alpha" ? row.item.value.toFixed(2) : row.item.ref
                                color: row.solid ? Theme.textOnAccent : Theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (place.tab === "swatches") place.swatch = row.i
                                    else if (place.tab === "roles") place.role = row.i
                                    win.editing = !row.chooser
                                    win.editRow = 0
                                    win.syncFocus()
                                }
                            }
                        }
                    }
                }

                // A rule between the list and the editor.
                Rectangle { width: Theme.borderThin; height: parent.height; color: Theme.border }

                // ── the editor ──
                Column {
                    id: editor
                    width: parent.width - win.listWidth - Theme.borderThin
                    height: parent.height
                    leftPadding: 4 * win.u
                    readonly property int inner: width - 4 * win.u

                    // Name and note.
                    Item {
                        width: editor.inner
                        height: win.rowHeight
                        Words {
                            id: nameWords
                            height: parent.height
                            text: !win.current ? (place.tab === "roles" ? "Pick a role" : "")
                                : place.tab === "swatches" ? win.current.name
                                : place.tab === "alpha" ? "alpha"
                                : win.tableName + "." + win.current.key
                        }
                        Words {
                            x: nameWords.implicitWidth + 3 * win.u
                            width: parent.width - x
                            height: parent.height
                            text: win.current ? win.current.note : ""
                            color: Theme.textSecondary
                        }
                    }

                    // Before → after.
                    Row {
                        visible: !!win.current && place.tab !== "alpha"
                        height: 10 * win.u
                        spacing: 2 * win.u
                        Rectangle {
                            width: 16 * win.u; height: 8 * win.u
                            anchors.verticalCenter: parent.verticalCenter
                            color: win.current && win.current.hex ? win.current.hex : "transparent"
                            border.width: Theme.borderThin; border.color: Theme.borderShade
                        }
                        Words {
                            height: parent.height
                            text: (win.current ? win.current.hex : "") + "  →"
                            color: Theme.textSecondary
                        }
                        Rectangle {
                            width: 16 * win.u; height: 8 * win.u
                            anchors.verticalCenter: parent.verticalCenter
                            color: place.tab === "swatches" ? win.draftHex : win.swatchHex(win.draftRef)
                            border.width: Theme.borderThin; border.color: Theme.borderShade
                        }
                        Words {
                            height: parent.height
                            text: place.tab === "swatches" ? win.draftHex
                                : win.draftRef + "  " + win.swatchHex(win.draftRef)
                            color: win.dirty ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    // Where it's used: checked or not (the lit lip, the desk…).
                    Words {
                        visible: !!win.current && place.tab !== "alpha"
                        width: editor.inner
                        height: win.rowHeight
                        readonly property var used: !win.current || !win.model ? []
                            : place.tab === "swatches" ? (win.model.uses[win.current.name] ?? [])
                            : (win.model.uses[win.draftRef] ?? [])
                        text: (place.tab === "swatches" ? "Used by " : win.draftRef + " is used by ")
                            + used.length + (used.length ? ":  " + used.join("  ") : "")
                        color: Theme.textSecondary
                    }

                    // ── swatches: L, C, h meters and a hex field ──
                    Repeater {
                        // A count, not an array of values: the meters stay put
                        // (and a drag keeps its press) while the draft changes.
                        model: place.tab === "swatches" && win.current ? 3 : 0
                        delegate: Item {
                            id: meter
                            required property int index
                            readonly property var spec: win.channels[index]
                            readonly property real value: win.channelValue(index)
                            readonly property bool focused: win.editing && win.editRow === index
                            readonly property int cells: 40
                            width: editor.inner
                            height: 7 * win.u

                            Marker { visible: meter.focused; x: -3 * win.u; anchors.verticalCenter: parent.verticalCenter }
                            Words { width: 4 * win.u; height: parent.height; text: meter.spec.label; color: Theme.textSecondary }

                            // The track: the channel swept across `cells` flat
                            // steps, so you can see where it's going before you
                            // get there. Steps outside sRGB sit half height.
                            Slot {
                                id: track
                                x: 5 * win.u
                                anchors.verticalCenter: parent.verticalCenter
                                width: meter.cells * 2 * win.u + 2 * Theme.borderThin
                                height: 4 * win.u
                                Row {
                                    x: Theme.borderThin
                                    y: Theme.borderThin
                                    Repeater {
                                        model: meter.cells
                                        delegate: Item {
                                            required property int index
                                            readonly property var c: win.channelAt(meter.index,
                                                meter.spec.min + (index + 0.5) / meter.cells * (meter.spec.max - meter.spec.min))
                                            width: 2 * win.u
                                            height: track.height - 2 * Theme.borderThin
                                            Rectangle {
                                                width: parent.width
                                                height: parent.c.inGamut ? parent.height : parent.height / 2
                                                anchors.bottom: parent.bottom
                                                color: parent.c.hex
                                            }
                                        }
                                    }
                                }
                                // Where the value is: a full-height tick.
                                Rectangle {
                                    z: 2
                                    x: Theme.borderThin - 1 + (meter.value - meter.spec.min)
                                       / (meter.spec.max - meter.spec.min) * meter.cells * 2 * win.u
                                    y: -win.u
                                    width: Theme.borderWidth
                                    height: track.height + 2 * win.u
                                    color: meter.focused ? Theme.focusBorder : Theme.textPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    function pick(mx) {
                                        const t = Math.max(0, Math.min(1, (mx - Theme.borderThin) / (meter.cells * 2 * win.u)))
                                        win.channelSet(meter.index, meter.spec.min + t * (meter.spec.max - meter.spec.min))
                                    }
                                    onPressed: mouse => { win.editing = true; win.editRow = meter.index; win.syncFocus(); pick(mouse.x) }
                                    onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                                }
                            }
                            Words {
                                anchors.right: parent.right
                                height: parent.height
                                text: meter.index === 2 ? Math.round(meter.value) + "°" : meter.value.toFixed(3)
                            }
                        }
                    }

                    Item {
                        visible: place.tab === "swatches" && !!win.current
                        width: editor.inner
                        height: 8 * win.u
                        Marker { visible: win.editing && win.editRow === 3; x: -3 * win.u; anchors.verticalCenter: parent.verticalCenter }
                        Words { width: 4 * win.u; height: parent.height; text: "#"; color: Theme.textSecondary }
                        Slot {
                            x: 5 * win.u
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24 * win.u
                            height: 6 * win.u
                            TextInput {
                                id: hexInput
                                anchors.fill: parent
                                anchors.leftMargin: 2 * win.u
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Theme.textPrimary
                                selectionColor: Theme.accentSolid
                                selectedTextColor: Theme.textOnAccent
                                maximumLength: 7
                                onTextEdited: {
                                    const t = text.startsWith("#") ? text : "#" + text
                                    if (Oklch.isHex(t)) win.setHex(t)
                                }
                                Keys.onPressed: event => win.handleKey(event)
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: { win.editing = true; win.editRow = 3; win.syncFocus() }
                                }
                            }
                        }
                        Words {
                            x: 31 * win.u
                            height: parent.height
                            visible: !win.draftInGamut
                            text: "outside sRGB: saved clipped"
                            color: Theme.alert
                        }
                    }

                    // ── alpha: one meter. Each step shows the bar's face at
                    // that alpha over the desk, so you see what you'd get. ──
                    Item {
                        visible: place.tab === "alpha" && !!win.current
                        width: editor.inner
                        height: 9 * win.u
                        readonly property int cells: 40
                        Marker { visible: win.editing; x: -3 * win.u; anchors.verticalCenter: parent.verticalCenter }
                        Words { width: 4 * win.u; height: parent.height; text: "α"; color: Theme.textSecondary }
                        Slot {
                            id: alphaTrack
                            x: 5 * win.u
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.cells * 2 * win.u + 2 * Theme.borderThin
                            height: 4 * win.u
                            Row {
                                x: Theme.borderThin
                                y: Theme.borderThin
                                Repeater {
                                    model: 40
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property real a: 0.5 + (index + 0.5) / 40 * 0.5
                                        width: 2 * win.u
                                        height: alphaTrack.height - 2 * Theme.borderThin
                                        color: Qt.rgba(a * Theme.bgPrimary.r + (1 - a) * Theme.desk.r,
                                                       a * Theme.bgPrimary.g + (1 - a) * Theme.desk.g,
                                                       a * Theme.bgPrimary.b + (1 - a) * Theme.desk.b, 1)
                                    }
                                }
                            }
                            Rectangle {
                                z: 2
                                x: Theme.borderThin - 1 + (win.draftAlpha - 0.5) / 0.5 * 40 * 2 * win.u
                                y: -win.u
                                width: Theme.borderWidth
                                height: alphaTrack.height + 2 * win.u
                                color: win.editing ? Theme.focusBorder : Theme.textPrimary
                            }
                            MouseArea {
                                anchors.fill: parent
                                function pick(mx) {
                                    const t = Math.max(0, Math.min(1, (mx - Theme.borderThin) / (40 * 2 * win.u)))
                                    win.draftAlpha = Math.round((0.5 + t * 0.5) * 100) / 100
                                    win.confirmFailing = false
                                    win.requestCheck()
                                }
                                onPressed: mouse => { win.editing = true; win.syncFocus(); pick(mouse.x) }
                                onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                            }
                        }
                        Words {
                            anchors.right: parent.right
                            height: parent.height
                            text: win.draftAlpha.toFixed(2) + (win.dirty ? "  was " + win.current.value.toFixed(2) : "")
                        }
                    }

                    // ── roles: which swatch ──
                    Item {
                        visible: place.tab === "roles" && !!win.current
                        width: editor.inner
                        height: 8 * win.u
                        Marker { visible: win.editing; x: -3 * win.u; anchors.verticalCenter: parent.verticalCenter }
                        Words { height: parent.height; text: "Swatch"; color: Theme.textSecondary }
                        Words {
                            x: 16 * win.u
                            height: parent.height
                            text: "‹ " + win.draftRef + " ›" + (win.current && win.draftRef !== win.current.ref ? "   was " + win.current.ref : "")
                        }
                    }

                    // ── checks ──
                    Item {
                        visible: !!win.current
                        width: editor.inner
                        height: win.rowHeight
                        Words {
                            height: parent.height
                            text: {
                                const involved = win.checks.filter(c => c.involved).length
                                const fails = win.checks.filter(c => !c.ok).length
                                return "Checks  " + involved + " involve it"
                                    + (fails ? "  ·  " + fails + " fail" : "  ·  all pass")
                            }
                            color: win.checks.some(c => !c.ok) ? Theme.alert : Theme.textSecondary
                        }
                    }
                    Repeater {
                        model: win.current ? win.checks.slice(0, place.tab === "swatches" ? 6 : 10) : []
                        delegate: Item {
                            id: chk
                            required property var modelData
                            readonly property bool step: modelData.kind === "step"
                            width: editor.inner
                            height: win.rowHeight

                            // The pair itself: text on its background, or for a
                            // surface step, the upper surface lying on the lower.
                            Rectangle {
                                width: 8 * win.u
                                height: 5 * win.u
                                anchors.verticalCenter: parent.verticalCenter
                                color: chk.modelData.bgHex
                                Rectangle {
                                    visible: chk.step
                                    x: win.u; y: win.u
                                    width: parent.width - 2 * win.u; height: parent.height - 2 * win.u
                                    color: chk.modelData.fgHex
                                }
                                Text {
                                    visible: !chk.step
                                    anchors.centerIn: parent
                                    text: "Aa"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    color: chk.modelData.fgHex
                                }
                            }
                            Words {
                                x: 10 * win.u
                                width: 30 * win.u
                                height: parent.height
                                text: (chk.modelData.ok ? "ok   " : "FAIL ")
                                    + (chk.step ? "ΔL " + chk.modelData.value.toFixed(2) : chk.modelData.value.toFixed(2))
                                    + (chk.modelData.was === null ? "  (new)"
                                       : chk.modelData.value !== chk.modelData.was ? " ← " + chk.modelData.was : "")
                                color: chk.modelData.ok ? Theme.textPrimary : Theme.alert
                            }
                            Words {
                                x: 41 * win.u
                                width: parent.width - x
                                height: parent.height
                                text: "≥ " + chk.modelData.min + "  " + chk.modelData.fg + " on " + chk.modelData.bg
                                    + "  (" + chk.modelData.where + ")"
                                color: Theme.textSecondary
                            }
                        }
                    }
                }
            }

            // ── status, or what the keys do ──
            Words {
                width: parent.width
                height: 7 * win.u
                leftPadding: 2 * win.u
                text: win.confirmFailing ? win.failing + " check" + (win.failing === 1 ? "" : "s") + " would fail. Enter again saves anyway; Esc undoes."
                    : win.saving || win.status ? win.status
                    : !win.editing ? "Up/Down choose. Right edits. Tab: swatches/roles/alpha. Esc closes."
                    : place.tab === "swatches" ? "Up/Down: L C h #. Left/Right adjust (Shift: more). Enter saves. Esc undoes."
                    : place.tab === "alpha" ? "Left/Right: 0.01 (Shift: 0.05). Enter saves. Esc undoes."
                    : "Left/Right picks a swatch (Shift: 5). Enter saves. Esc undoes."
                color: win.confirmFailing || (win.status && win.statusIsError) ? Theme.alert : Theme.textSecondary
            }
        }
    }
}
