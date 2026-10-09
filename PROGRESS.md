# Progress

Milestone: **vertical slice** (design brief, "First milestone"). Plan and decisions: see DECISIONS.md.

| Step | What | Status |
|---|---|---|
| 0 | Skeleton: settings, input map, autoloads, tracked state + saves, test runner, gate, palette, fonts, title with canonical ring | done |
| 1 | Isometric movement, dodge, greybox Vellum street | next |
| 2 | Combat with two-weapon loadout, tuned/manual modes | |
| 3 | Predictive path, hidden off-path area | |
| 4 | Voice toggle: assists, map, narration, lighting | |
| 5 | Adaptive narration from tagged line pools | |
| 6 | Level end with power-vs-truth core choice | |
| 7 | Ark hub with the Archive | |
| 8 | Tracking finished + debug overlay + save round-trip | |
| — | Sol analysis review (reviews/vertical-slice.md), fixes, re-check | |

## Done

**Step 0.** `project.godot` (1920×1080, canvas_items/expand, Forward+, HDR 2D, warnings as errors,
custom user dir "Undertow"); autoloads `Controls`, `SteamService`, `SaveService`, `GameState`,
`Steward`, `Narrator`, `SceneRouter`, `DebugOverlay`, `Autopilot`; `RunState` holds every tracked
variable from the brief; `SaveStore` JSON saves with backup and corrupt-file recovery; colour palette
with owners; fonts; the Steward ring drawn to image 11's geometry in all states; title screen with
the UNDERTOW wordmark (ring as the O, gap facing the W) and the Steward's last line.

## Next

Step 1: greybox Vellum street at image 10's scale; the Operator with 8-way screen-relative movement and
a dodge; collisions, depth sorting, follow camera; New Game starts the level.

## How to run

```bash
godot --path .                       # play (title screen)
godot --path . -- --debug-overlay    # start with the tracked-state overlay open (F3 toggles it)
```

## How to test

```bash
tools/check.sh                       # the full gate: import, tests, 30 s autopilot run
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn            # tests only
godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn -- --filter=save   # some tests
tools/record.sh <name> [seconds] [scenario]   # progress video -> ../undertow-recordings/<name>.mp4
```

Autopilot scenarios (`-- --autopilot --autopilot-scenario=NAME`): `slice` (default), `ring_gallery`.
Gate logs and screenshots land in `reports/check/` (ignored by git).
