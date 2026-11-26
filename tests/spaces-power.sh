#!/bin/bash

# Checks bin/spaces-power's bar edits on a copy of a bar layout, never the
# real shell.json: it swaps HOME and the state folder for a scratch folder
# and stubs omarchy-shell. Needs Omarchy's omarchy-shell-config on PATH.
#
#   tests/spaces-power.sh

set -euo pipefail

command -v omarchy-shell-config >/dev/null || { echo "skipped: no omarchy-shell-config"; exit 0; }

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home/.config/omarchy" "$scratch/stub"
printf '#!/bin/sh\necho ok\n' >"$scratch/stub/omarchy-shell"
chmod +x "$scratch/stub/omarchy-shell"
config="$scratch/home/.config/omarchy/shell.json"
state="$scratch/state/omarchy-spaces"

power() {
  HOME="$scratch/home" XDG_STATE_HOME="$scratch/state" PATH="$scratch/stub:$PATH" "$root/bin/spaces-power" "$@"
}
left() { jq -c '[.bar.layout.left[] | if type == "object" then .id else . end]' "$config"; }
failed=0
expect() {
  local got
  got=$(left)
  if [[ $got == "$2" ]]; then echo "ok: $1"; else echo "FAIL: $1: got $got, wanted $2"; failed=1; fi
}

# Clones of the menu and workspaces, with the tabs added last.
echo '{"bar":{"layout":{"left":[{"id":"me.menu"},"me.workspaces",{"id":"omarchy.media"},{"id":"com.t4t5.spaces"}]}}}' >"$config"
power bar-on
expect "on takes the menu and workspaces off and puts the tabs first" '["com.t4t5.spaces","omarchy.media"]'
power bar-on
expect "on twice changes nothing" '["com.t4t5.spaces","omarchy.media"]'
power bar-off
expect "off puts them back, the button after them" '["me.menu","me.workspaces","com.t4t5.spaces","omarchy.media"]'
jq -e '.bar.layout.left[1] == "me.workspaces"' "$config" >/dev/null && echo "ok: an entry comes back as it was" ||
  { echo "FAIL: me.workspaces came back changed"; failed=1; }
power bar-off
expect "off twice changes nothing" '["me.menu","me.workspaces","com.t4t5.spaces","omarchy.media"]'

# Removed while on: uninstall.sh gives the bar back without the tabs.
power bar-on
jq '.bar.layout.left |= map(select((.id? // .) != "com.t4t5.spaces"))' "$config" >"$config.tmp" && mv "$config.tmp" "$config"
power bar-off
expect "off with the tabs gone" '["me.menu","me.workspaces","omarchy.media"]'

# Set up by upstream's install, which replaced Omarchy's two and saved nothing.
rm -f "$state/power-bar.json"
echo replace >"$state/bar"
echo '{"bar":{"layout":{"left":[{"id":"com.t4t5.spaces"},{"id":"omarchy.media"}]}}}' >"$config"
power bar-off
expect "off after upstream's setup" '["omarchy.menu","omarchy.workspaces","com.t4t5.spaces","omarchy.media"]'

# The tabs first when turned on, as the setup enables them.
rm -f "$state/power-bar.json" "$state/bar"
echo '{"bar":{"layout":{"left":[{"id":"com.t4t5.spaces"},{"id":"me.menu"},{"id":"me.workspaces"},{"id":"omarchy.indicators"}]}}}' >"$config"
power bar-on
expect "on with the tabs already first" '["com.t4t5.spaces","omarchy.indicators"]'
power bar-off
expect "off keeps the others' order" '["me.menu","me.workspaces","com.t4t5.spaces","omarchy.indicators"]'

[[ $(power status) == on ]] && echo "ok: on until turned off" || { echo "FAIL: status"; failed=1; }
exit $failed
