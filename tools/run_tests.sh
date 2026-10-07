#!/usr/bin/env bash
# Import the project, run every test headlessly, and fail on test failures or on any
# script error Godot printed along the way (Godot keeps running after those).
#
#   tools/run_tests.sh [name_filter]
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

"$GODOT" --headless --path . --import > /dev/null 2>&1
log="$(mktemp)"
"$GODOT" --headless --path . -s tests/run_tests.gd -- "$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error|Compile Error|^ERROR:" "$log"; then
  echo "Godot reported errors (see above)." >&2
  status=1
fi
rm -f "$log"
exit "$status"
