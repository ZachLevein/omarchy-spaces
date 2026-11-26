import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import "Spaces.mjs" as Spaces

// The colours of a surface that dresses like Omarchy's bar: opaque, glassy or
// clear, as the bar's background is set (Spaces.barLook). Glassy is the
// theme's background faded the way the bar fades it; Hyprland blurs behind it
// (hypr/omarchy-spaces.lua). Clear takes its text colour from the wallpaper under
// the surface, as the bar does, so the text stays legible.
Item {
  id: root

  property string look: "opaque"
  // The screen edge the surface runs along and how far it reaches in from
  // it, which is the part of the wallpaper a clear surface sits on.
  property string edge: "top"
  property int size: 0

  readonly property color theme: Commons.Color.bar.background
  readonly property color text: Commons.Color.bar.text
  readonly property color contrast: Commons.Color.background
  property color clearText: text

  readonly property color background: look === "none" ? "transparent"
    : look === "glassy" ? Qt.rgba(theme.r, theme.g, theme.b, Math.min(theme.a, 0.35))
    : theme
  readonly property color foreground: look === "none" ? clearText : text
  // The shade over it where the background shows beside the space's windows.
  // None on a glassy one: the shade over the glass made it read as opaque.
  readonly property color recess: look === "glassy" ? "transparent"
    : Qt.rgba(0, 0, 0, Spaces.recessAlpha(theme.r, theme.g, theme.b))

  function hex(c) {
    function channel(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2) }
    return "#" + channel(c.r) + channel(c.g) + channel(c.b)
  }

  function sample() {
    if (root.look === "none" && root.size > 0) sampleTimer.restart()
  }

  onLookChanged: sample()
  onSizeChanged: sample()
  onTextChanged: sample()
  onContrastChanged: sample()

  Timer {
    id: sampleTimer
    interval: 120
    onTriggered: {
      if (picker.running) return restart()
      picker.command = ["omarchy-bar-text-color", root.edge, String(root.size), root.hex(root.text), root.hex(root.contrast)]
      picker.running = true
    }
  }

  Process {
    id: picker
    stdout: SplitParser {
      onRead: function(line) {
        var value = String(line || "").trim()
        if (/^#[0-9A-Fa-f]{6}$/.test(value)) root.clearText = value
      }
    }
  }

  // A new theme or wallpaper changes current/; the watch on a file inside it
  // fires for the whole directory, as it does for the bar.
  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/current/theme"
    watchChanges: true
    printErrors: false
    onFileChanged: root.sample()
  }
}
