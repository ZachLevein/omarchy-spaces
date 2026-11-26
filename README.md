# Omarchy Spaces

<img src="assets/screenshot.png" width="627" alt="A sidebar listing your spaces, beside the tabs of the open one">

Inspired by multiplexer apps like [Herdr](https://herdr.dev) and [Rex](https://superlogical.com), but for your whole desktop:

- Every project gets its own **space**
- Every space has its own **tabs** (Hyprland workspaces)
- Keeps track of agent status across projects
- Spaces are restored after a reboot

## Install

You need Omarchy 4.5 or newer.

**1. Add the plugin.** Choose "Left" (the default) when it asks where to put it. This replaces the built-in `omarchy.menu` and `omarchy.workspaces` components with `com.t4t5.spaces`.

```sh
omarchy plugin add https://github.com/ZachLevein/omarchy-spaces.git --enable
```

**2. Add the basic key bindings** to your `~/.config/hypr/bindings.lua` file (at the end):

```lua
if package.searchpath("hypr.omarchy-spaces", package.path) then
  local spaces = require("hypr.omarchy-spaces")

  spaces.bind_tab_keys()
  o.rebind("SUPER + B", "Show or hide spaces", spaces.toggle_sidebar())
end
```

For advanced workflows, check out [all the key bindings you can add](docs/guide/keys.md).

## Use

- <kbd>Super</kbd> <kbd>B</kbd> shows your spaces. Click **New space** to open one in the folder you're in.
- <kbd>Super</kbd> <kbd>1</kbd>–<kbd>0</kbd> goes to a tab. Click **+** to open a new one.
- Right-click a space or a tab to rename or close it.

Your regular workspaces are still there, in the `home` space.

## Turn it off and on

This fork adds an off switch that leaves the plugin installed:

- **Off:** the power button in the expanded sidebar's header, or `spaces-power off` (in the plugin's `bin/`). You go to `home`, the sidebar goes, and the bar gets back the menu and workspaces widgets Spaces took the place of (Omarchy's or your own clones). Your spaces' windows stay on their tabs, out of sight.
- **On:** the faded sidebar icon left on the bar after your workspaces, <kbd>Super</kbd> <kbd>B</kbd>, or `spaces-power on`. You're back in the space you were in, with its tabs.

`spaces-power toggle` switches between the two, and `spaces-power status` prints which it is. While it's off, <kbd>Super</kbd> <kbd>1</kbd>–<kbd>0</kbd> go to your regular workspaces as they did before Spaces.

For everything else, check out the [docs](docs/README.md).

## Uninstall

```sh
omarchy plugin remove com.t4t5.spaces
```

Your windows, bar and keys go back to how they were.
