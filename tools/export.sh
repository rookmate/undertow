#!/usr/bin/env bash
# Exports Linux, Windows and macOS release builds (export_presets.cfg) and smoke-tests the Linux one:
# the exported game must play the 30-second autopilot with no errors. This is the packaging check: maps,
# narration, cores, logs, fonts and every scene must be inside the export.
#   tools/export.sh            exports into build/ (ignored by git); logs in reports/export/
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG_DIR="$ROOT/reports/export"
mkdir -p "$LOG_DIR" build/linux build/windows build/macos
# Screenshots land inside the project folder: keep Godot from importing them.
touch "$ROOT/reports/.gdignore"
BAD='^(ERROR|SCRIPT ERROR|USER ERROR|USER SCRIPT ERROR):|Parse Error|Failed to load'
status=0
for spec in "Linux:build/linux/Undertow.x86_64" "Windows:build/windows/Undertow.exe" "macOS:build/macos/Undertow.zip"; do
  preset="${spec%%:*}"; out="${spec#*:}"
  echo "== export $preset"
  timeout 900 godot --headless --path . --export-release "$preset" "$ROOT/$out" > "$LOG_DIR/$preset.log" 2>&1
  code=$?
  if [ $code -ne 0 ] || [ ! -s "$ROOT/$out" ]; then echo "  FAIL ($code)"; tail -5 "$LOG_DIR/$preset.log"; status=1; continue; fi
  if grep -nE "$BAD" "$LOG_DIR/$preset.log" | head -5; then echo "  FAIL errors in export log"; status=1; continue; fi
  echo "  ok  $(du -h "$ROOT/$out" | cut -f1)  $out"
done
echo "== run the exported Linux build (30 s autopilot)"
MODE=(--disable-vsync --max-fps 60)
if [ -n "${HEADLESS:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then MODE=(--headless); fi
timeout 150 build/linux/Undertow.x86_64 "${MODE[@]}" -- --autopilot --autopilot-seconds=30 > "$LOG_DIR/linux-run.log" 2>&1
code=$?
grep -E '^AUTOPILOT' "$LOG_DIR/linux-run.log" | sed 's/^/  /'
if [ $code -ne 0 ] || ! grep -q '^AUTOPILOT PASS' "$LOG_DIR/linux-run.log"; then echo "  FAIL exported run ($code)"; status=1; fi
if grep -nE "$BAD" "$LOG_DIR/linux-run.log" | head -10; then echo "  FAIL errors in exported run"; status=1; fi
echo
if [ $status -eq 0 ]; then echo "EXPORT: PASS"; else echo "EXPORT: FAIL"; fi
exit $status
