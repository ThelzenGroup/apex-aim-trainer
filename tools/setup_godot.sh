#!/usr/bin/env bash
# Install the pinned Godot editor plus the Windows export templates, self-contained
# (editor settings and templates live next to the binary, nothing in $HOME config).
#
#   tools/setup_godot.sh            # installs to ~/.local/share/godot-<version>
#   export PATH="$HOME/.local/share/godot-4.7.2:$PATH"   # then `godot` works
set -euo pipefail

VERSION="${GODOT_VERSION:-4.7.2}"
DEST="${GODOT_HOME:-$HOME/.local/share/godot-$VERSION}"
URL="https://downloads.godotengine.org/?version=$VERSION&flavor=stable"
TEMPLATES="$DEST/editor_data/export_templates/$VERSION.stable"

mkdir -p "$DEST"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ ! -x "$DEST/godot" ]; then
  curl -fsSL -o "$tmp/editor.zip" "$URL&slug=linux.x86_64.zip&platform=linux.64"
  unzip -q -o "$tmp/editor.zip" -d "$DEST"
  ln -sf "$DEST/Godot_v$VERSION-stable_linux.x86_64" "$DEST/godot"
  touch "$DEST/._sc_"
fi

if [ ! -f "$TEMPLATES/windows_release_x86_64.exe" ]; then
  curl -fsSL -o "$tmp/templates.tpz" "$URL&slug=export_templates.tpz&platform=templates"
  mkdir -p "$TEMPLATES"
  unzip -q -o -j "$tmp/templates.tpz" \
    templates/version.txt templates/windows_release_x86_64.exe templates/windows_debug_x86_64.exe \
    -d "$TEMPLATES"
fi

"$DEST/godot" --headless --version
