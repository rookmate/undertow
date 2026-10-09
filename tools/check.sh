#!/usr/bin/env bash
# The step gate (see PROGRESS.md). Exit code 0 only if every check passes:
#   1. `godot --headless --import` finishes with no ERROR/WARNING lines.
#   2. All automated tests pass (tests/test_runner.tscn). Warnings are errors in this project, and a
#      test loads every script, so script errors and warnings fail here too.
#   3. The game runs for 30 s from the main scene under the autopilot with no ERROR/WARNING lines and
#      every autopilot check passing. Windowed when a display exists, headless otherwise.
#   4. Long autopilot runs (150 s each) that expect every feature built so far to work: New Game through
#      Kestrel Heights to the Loop map ("slice"), and the Vellum's whole route to the Archive ("vellum").
#   5. A tour of every district in LevelCatalog (autopilot scenario "tour": start, checkpoints, finds,
#      Reliquary, muted), each with no ERROR/WARNING lines.
# Env: SMOKE_SECONDS (30), FULL_SECONDS (150), SMOKE_SCENARIO (slice), HEADLESS=1 to force headless, LOG_DIR.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG_DIR="${LOG_DIR:-$ROOT/reports/check}"
SMOKE_SECONDS="${SMOKE_SECONDS:-30}"
SMOKE_SCENARIO="${SMOKE_SCENARIO:-slice}"
# The long runs: the new-game route (Kestrel Heights to the Loop map) and the Vellum's whole route.
FULL_SCENARIOS="${FULL_SCENARIOS:-slice vellum}"
mkdir -p "$LOG_DIR"
# Screenshots land inside the project folder: keep Godot from importing them.
touch "$ROOT/reports/.gdignore"
rm -rf "$LOG_DIR/shots" "$LOG_DIR/shots_full"
BAD='^(ERROR|SCRIPT ERROR|WARNING|SCRIPT WARNING|USER ERROR|USER WARNING|USER SCRIPT ERROR):|Parse Error|Failed to load script|Attempt to resume function'
status=0

scan_log() { # $1 log file, $2 label
  if grep -nE "$BAD" "$1" > "$1.problems"; then
    echo "  FAIL $2: problem lines in $(basename "$1"):"
    sed 's/^/    /' "$1.problems" | head -40
    status=1
    return 1
  fi
  return 0
}

echo "== 1/5 import (godot --headless --import)"
timeout 900 godot --headless --path . --import > "$LOG_DIR/import.log" 2>&1
code=$?
if [ $code -ne 0 ]; then echo "  FAIL import exited with $code"; status=1; fi
scan_log "$LOG_DIR/import.log" import && [ $code -eq 0 ] && echo "  ok"

echo "== 2/5 tests"
timeout 900 godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn > "$LOG_DIR/tests.log" 2>&1
code=$?
grep -E '^(  FAIL|RESULT)' "$LOG_DIR/tests.log" | sed 's/^/  /'
if [ $code -ne 0 ]; then echo "  FAIL tests exited with $code"; status=1; fi
grep -q '^RESULT: PASS' "$LOG_DIR/tests.log" || { echo "  FAIL no passing RESULT line"; status=1; }
scan_log "$LOG_DIR/tests.log" tests && [ $code -eq 0 ] && echo "  ok"

echo "== 3/5 ${SMOKE_SECONDS}s run from the main scene (autopilot scenario: $SMOKE_SCENARIO)"
# Windowed runs disable vsync: this machine's display server has no monitor attached, so presenting
# with vsync blocks forever. --max-fps keeps the frame rate realistic.
MODE=(--disable-vsync --max-fps 60)
if [ -n "${HEADLESS:-}" ] || [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then MODE=(--headless); echo "  (headless)"; else echo "  (windowed)"; fi
timeout $((SMOKE_SECONDS + 90)) godot "${MODE[@]}" --path . -- --autopilot \
  --autopilot-seconds="$SMOKE_SECONDS" --autopilot-scenario="$SMOKE_SCENARIO" \
  --autopilot-shots="$LOG_DIR/shots" > "$LOG_DIR/smoke.log" 2>&1
code=$?
grep -E '^(AUTOPILOT|\[autopilot\] ok)' "$LOG_DIR/smoke.log" | sed 's/^/  /'
if [ $code -ne 0 ]; then echo "  FAIL run exited with $code"; status=1; fi
grep -q '^AUTOPILOT PASS' "$LOG_DIR/smoke.log" || { echo "  FAIL autopilot did not pass"; status=1; }
scan_log "$LOG_DIR/smoke.log" run && [ $code -eq 0 ] && echo "  ok"

echo "== 4/5 full runs (${FULL_SECONDS:-150}s each: ${FULL_SCENARIOS})"
for scenario in $FULL_SCENARIOS; do
  log="$LOG_DIR/full_$scenario.log"
  timeout $(( ${FULL_SECONDS:-150} + 90 )) godot "${MODE[@]}" --path . -- --autopilot \
    --autopilot-seconds="${FULL_SECONDS:-150}" --autopilot-scenario="$scenario" \
    --autopilot-shots="$LOG_DIR/shots_full_$scenario" > "$log" 2>&1
  code=$?
  grep -E '^AUTOPILOT' "$log" | sed "s/^/  $scenario: /"
  if [ $code -ne 0 ]; then echo "  FAIL full $scenario run exited with $code"; status=1; fi
  grep -q '^AUTOPILOT PASS' "$log" || { echo "  FAIL full $scenario run did not pass"; status=1; }
  scan_log "$log" "full $scenario" && [ $code -eq 0 ] && echo "  ok"
done

echo "== 5/5 district tours"
for district in $(timeout 120 godot --headless --path . -s tools/list_districts.gd 2>/dev/null | sed -n 's/^DISTRICT //p'); do
  log="$LOG_DIR/tour_$district.log"
  timeout 150 godot "${MODE[@]}" --path . -- --autopilot --autopilot-seconds=40 --autopilot-scenario=tour \
    --autopilot-level="$district" --autopilot-shots="$LOG_DIR/shots_tour_$district" > "$log" 2>&1
  code=$?
  grep -E '^AUTOPILOT' "$log" | sed "s/^/  $district: /"
  if [ $code -ne 0 ]; then echo "  FAIL tour of $district exited with $code"; status=1; fi
  grep -q '^AUTOPILOT PASS' "$log" || { echo "  FAIL tour of $district did not pass"; status=1; }
  scan_log "$log" "tour $district" && [ $code -eq 0 ] && echo "  ok"
done

echo
if [ $status -eq 0 ]; then echo "GATE: PASS"; else echo "GATE: FAIL"; fi
exit $status
