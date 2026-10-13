#!/usr/bin/env bash
# The step gate (see PROGRESS.md). Exit code 0 only if every check passes:
#   1. `godot --headless --import` finishes with no ERROR/WARNING lines.
#   2. All automated tests pass (tests/test_runner.tscn). Warnings are errors in this project, and a
#      test loads every script, so script errors and warnings fail here too.
#   3. The game runs for 30 s from the main scene under the autopilot with no ERROR/WARNING lines and
#      every autopilot check passing. Windowed when a display exists, headless otherwise.
#   4. The long autopilot run that expects every feature built so far to work, as a player meets them,
#      in one run ("campaign"): New Game, every district in order, the Ark between them, a save and
#      Continue, and the end: the Council Chamber, an epilogue, the title after. It ends when it's done
#      (at most CAMPAIGN_SECONDS). Then the three endings, each from a prepared run ("ending_reboot",
#      "ending_unplug", "ending_rewrite"), FULL_SECONDS each. Prepared single-district runs and the long
#      "slice" can be added with FULL_SCENARIOS.
#   5. A tour of every district in LevelCatalog (autopilot scenario "tour": start, checkpoints, finds,
#      Reliquary, muted), each with no ERROR/WARNING lines. The district listing is checked first.
# Env: SMOKE_SECONDS (30), FULL_SCENARIOS (campaign and the endings), CAMPAIGN_SECONDS (1500), FULL_SECONDS (150),
#      SMOKE_SCENARIO (slice), HEADLESS=1 to force headless, LOG_DIR.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG_DIR="${LOG_DIR:-$ROOT/reports/check}"
SMOKE_SECONDS="${SMOKE_SECONDS:-30}"
SMOKE_SCENARIO="${SMOKE_SCENARIO:-slice}"
# The long runs: the whole game so far in one run, and any single-district runs asked for.
FULL_SCENARIOS="${FULL_SCENARIOS:-campaign ending_reboot ending_unplug ending_rewrite}"
seconds_for() { if [ "$1" = campaign ]; then echo "${CAMPAIGN_SECONDS:-1500}"; else echo "${FULL_SECONDS:-150}"; fi; }
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

echo "== 4/5 full runs (${FULL_SCENARIOS})"
for scenario in $FULL_SCENARIOS; do
  log="$LOG_DIR/full_$scenario.log"
  run_seconds=$(seconds_for "$scenario")
  timeout $(( run_seconds + 90 )) godot "${MODE[@]}" --path . -- --autopilot \
    --autopilot-seconds="$run_seconds" --autopilot-scenario="$scenario" \
    --autopilot-shots="$LOG_DIR/shots_full_$scenario" > "$log" 2>&1
  code=$?
  grep -E '^AUTOPILOT' "$log" | sed "s/^/  $scenario: /"
  # The Operator can't go down in these runs (DECISIONS 178): where it would have, for the record.
  grep -E '^\[autopilot\] would have gone down [0-9]+ times' "$log" | sed "s/^\[autopilot\] /  $scenario: /"
  if [ $code -ne 0 ]; then echo "  FAIL full $scenario run exited with $code"; status=1; fi
  grep -q '^AUTOPILOT PASS' "$log" || { echo "  FAIL full $scenario run did not pass"; status=1; }
  scan_log "$log" "full $scenario" && [ $code -eq 0 ] && echo "  ok"
done

echo "== 5/5 district tours"
# The listing itself is checked (tools/district_listing.sh, which tests itself first): a failed,
# timed-out, noisy or incomplete listing fails the gate rather than silently touring nothing.
if ! tools/test_district_listing.sh > "$LOG_DIR/district_listing_test.log" 2>&1; then
  echo "  FAIL the listing check's own test:"; sed 's/^/    /' "$LOG_DIR/district_listing_test.log"; status=1
fi
timeout 120 godot --headless --path . -- --list-districts > "$LOG_DIR/districts.log" 2>&1
code=$?
if ! districts=$(tools/district_listing.sh "$LOG_DIR/districts.log" "$code" 2> "$LOG_DIR/districts.why"); then
  echo "  FAIL listing districts: $(cat "$LOG_DIR/districts.why") (see districts.log)"; status=1; districts=""
fi
scan_log "$LOG_DIR/districts.log" "district listing"
for district in $districts; do
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
