import QtQuick
import Quickshell
import Quickshell.Io
import "Spaces.mjs" as Spaces

// The spaces sidebar, loaded with the shell and drawn under the windows
// (Base.qml). The overlay entry (Toggle.qml) starts and ends its search, so
// a key for it goes through the shell like any other plugin's. The tabs are a bar widget
// (TabsWidget.qml), which the bar loads itself.
Item {
  id: root

  property string omarchyPath: ""
  property var shell: null
  property var manifest: null

  // Only the first time: the shell hands a kept service the new manifest after
  // an update, while this is still the old one's QML.
  onManifestChanged: {
    if (!watchItem.loadedVersion && root.manifest) watchItem.loadedVersion = root.manifest.version || ""
  }

  // Whether Spaces is on: `bin/spaces-power` turns it off and on, writing
  // `power` in its state folder, which this follows. While it's off there is
  // no sidebar and no room kept for it, and the tabs on the bar shrink to a
  // button that turns it on again (TabsWidget.qml).
  property bool active: true
  readonly property string powerScript: String(Qt.resolvedUrl("../bin/spaces-power")).replace(/^file:\/\//, "")
  function setPower(on) { Quickshell.execDetached([root.powerScript, on ? "on" : "off"]) }
  function togglePower() { root.setPower(!root.active) }
  onActiveChanged: if (!root.active) sidebarItem.hide()

  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy-spaces/power"
    watchChanges: true
    printErrors: false
    // Read before the restore below decides whether to run.
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.active = text().trim() !== "off"
    onLoadFailed: root.active = true
  }

  readonly property bool searching: sidebarItem.searching
  readonly property var watch: watchItem
  // The sidebar, which the tabs on the bar line up beside while it shows.
  readonly property var sidebar: sidebarItem
  // Shared interaction and theme state for the bar, sidebar, and popups.
  readonly property var controller: controllerItem

  // The tabs' widgets with the sidebar's header on their bar, or null until
  // one has said whether it has.
  property var headerBars: null
  function setHeader(widget, on) {
    var bars = (root.headerBars || []).filter(function(bar) { return bar && bar !== widget })
    if (on) bars.push(widget)
    root.headerBars = bars
  }

  function search() { sidebarItem.search() }
  function endSearch() { sidebarItem.endSearch() }
  // While Spaces is off, the key that shows the sidebar turns it on instead.
  function toggleSidebar(screen) {
    if (root.active) sidebarItem.toggleSidebar(screen)
    else root.setPower(true)
  }
  function renameSpace() { controllerItem.renameSpace() }
  function renameTab() { controllerItem.renameTab("") }
  function sendTab() { controllerItem.sendTab() }
  function sendWindow(mode) { controllerItem.sendWindow(mode === "silent") }

  // What the sidebar and the bars show, for `just stress` to check.
  function shown() {
    return JSON.stringify({
      space: sidebarItem.shownRows.filter(function(row) { return row.active }).map(function(row) { return row.id }),
      focused: watchItem.now.focused,
      monitors: watchItem.now.monitors.map(function(m) { return { name: m.name, space: m.space, tab: m.tab } }),
    })
  }

  Base {
    sidebar: sidebarItem
    controller: controllerItem
    active: root.active
    look: Spaces.barLook(root.shell ? root.shell.barConfig : null)
    bar: root.shell ? root.shell.bar : null
  }

  SpaceMenu {
    controller: controllerItem
  }

  MovePicker {
    controller: controllerItem
  }

  IconPicker {
    controller: controllerItem
    omarchyPath: root.omarchyPath
  }

  // What the sidebar and the bar show, kept current by `space watch`
  // (TabsWidget.qml reaches it through the shell).
  Watch {
    id: watchItem
  }

  Controller {
    id: controllerItem
    watch: watchItem
    sidebar: sidebarItem
  }

  // The spaces from before the last restart open again by themselves, unless
  // `[restore]` sets `auto = false`. It does nothing when they already
  // have, as when only the shell restarts; detached, so restarting the shell
  // doesn't stop it halfway.
  // Not while Spaces is off: turning it on restores them then.
  Component.onCompleted: if (root.active) Quickshell.execDetached(["space", "restore", "--auto"])

  // When the plugin is removed this is all that runs, so it has uninstall.sh
  // undo the setup, from the copy the setup kept. That tells it apart from the
  // shell restarting. Detached, as the folder goes next; a linked clone has none.
  Component.onDestruction: Quickshell.execDetached(["sh", "-c",
    "exec \"${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-spaces/uninstall.sh\" 2>/dev/null"])

  Sidebar {
    id: sidebarItem
    active: root.active
    watch: watchItem
    controller: controllerItem
    // As the tabs' widgets have it, or as the config does until they load,
    // so the list doesn't start with a header that then goes.
    headerOnBar: root.headerBars ? root.headerBars.length > 0
      : Spaces.headerOnBar(root.shell ? root.shell.barConfig : null, (root.manifest && root.manifest.id) || "com.t4t5.spaces")
    // Ended from inside (a pick, Escape), so the shell stops counting the
    // overlay as open and the next toggle searches again.
    onSearchEnded: {
      if (root.shell && typeof root.shell.hide === "function")
        root.shell.hide((root.manifest && root.manifest.id) || "com.t4t5.spaces")
    }
  }
}
